package com.inventory.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Sale - mirrors the "sales" table in PostgreSQL.
 * One instance = one sale transaction header.
 *
 * A sale has a header (this class) and one or more line-items (SaleItem).
 * The relationship is:
 *
 *   Sale  ──< SaleItem >── Product
 *     1             N
 *
 * Database columns this class maps to:
 * ─────────────────────────────────────────────────────────────────
 *   id              SERIAL PRIMARY KEY
 *   receipt_number  VARCHAR(20) NOT NULL UNIQUE  - e.g. "RCP-20250001"
 *   sale_date       TIMESTAMP NOT NULL DEFAULT NOW()
 *   customer_name   VARCHAR(150)                 - optional (walk-in)
 *   customer_phone  VARCHAR(20)                  - optional
 *   payment_method  VARCHAR(20) NOT NULL DEFAULT 'CASH'
 *                   CHECK (payment_method IN ('CASH','TRANSFER','POS','CREDIT'))
 *   subtotal        NUMERIC(12,2) NOT NULL        - sum of all line totals
 *   discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0
 *   tax_amount      NUMERIC(12,2) NOT NULL DEFAULT 0
 *   grand_total     NUMERIC(12,2) NOT NULL        - subtotal - discount + tax
 *   amount_paid     NUMERIC(12,2) NOT NULL        - what the customer actually gave
 *   change_given    NUMERIC(12,2) NOT NULL DEFAULT 0
 *   status          VARCHAR(20) NOT NULL DEFAULT 'COMPLETED'
 *                   CHECK (status IN ('COMPLETED','REFUNDED','VOID'))
 *   notes           TEXT                         - optional cashier note
 *   served_by       VARCHAR(100)                 - username from session
 *   created_at      TIMESTAMP NOT NULL DEFAULT NOW()
 * ─────────────────────────────────────────────────────────────────
 *
 * Extra computed / transient fields (not stored in the sales table):
 *   items        - List<SaleItem> loaded by SaleDAO when needed
 *   itemCount    - total number of line items in this sale
 */
public class Sale {

    // ── Payment method constants ─────────────────────────────
    // Use these constants throughout the app - never raw strings.
    public static final String PAYMENT_CASH     = "CASH";
    public static final String PAYMENT_TRANSFER = "TRANSFER";
    public static final String PAYMENT_POS      = "POS";
    public static final String PAYMENT_CREDIT   = "CREDIT";

    // ── Status constants ─────────────────────────────────────
    public static final String STATUS_COMPLETED = "COMPLETED";
    public static final String STATUS_REFUNDED  = "REFUNDED";
    public static final String STATUS_VOID      = "VOID";

    // ── Database columns ─────────────────────────────────────
    private int        id;
    private String     receiptNumber;    // e.g. "RCP-20250001"
    private LocalDateTime saleDate;
    private String     customerName;
    private String     customerPhone;
    private String     paymentMethod;    // CASH | TRANSFER | POS | CREDIT
    private BigDecimal subtotal;         // sum of all (qty × unit_price)
    private BigDecimal discountAmount;   // flat discount applied
    private BigDecimal taxAmount;        // tax (VAT etc.)
    private BigDecimal totalAmount;       // subtotal - discount + tax
    private BigDecimal amountPaid;       // what the customer paid
    private BigDecimal changeGiven;      // amountPaid - totalAmount
    private String     status;           // COMPLETED | REFUNDED | VOID
    private String     notes;
    private String     servedBy;         // username of the cashier
    private LocalDateTime createdAt;

    // ── Transient / computed fields ──────────────────────────
    private List<SaleItem> items = new ArrayList<>();
    private int            itemCount;   // populated by DAO COUNT query

    // ── Constructor ──────────────────────────────────────────

    public Sale() {
        // Sensible defaults so the POS servlet doesn't have to set these
        // manually when building a new sale.
        this.paymentMethod  = PAYMENT_CASH;
        this.status         = STATUS_COMPLETED;
        this.subtotal       = BigDecimal.ZERO;
        this.discountAmount = BigDecimal.ZERO;
        this.taxAmount      = BigDecimal.ZERO;
        this.totalAmount     = BigDecimal.ZERO;
        this.amountPaid     = BigDecimal.ZERO;
        this.changeGiven    = BigDecimal.ZERO;
    }

    // ── Computed helpers ─────────────────────────────────────

    /**
     * Recalculates totalAmount from subtotal, discountAmount, and taxAmount.
     * Call this any time one of those three values changes.
     *
     * totalAmount = subtotal - discountAmount + taxAmount
     */
    public void recalculate() {
        BigDecimal base = subtotal == null ? BigDecimal.ZERO : subtotal;
        BigDecimal disc = discountAmount == null ? BigDecimal.ZERO : discountAmount;
        BigDecimal tax  = taxAmount == null ? BigDecimal.ZERO : taxAmount;
        this.totalAmount = base.subtract(disc).add(tax);
        if (amountPaid != null) {
            this.changeGiven = amountPaid.subtract(totalAmount);
            if (changeGiven.compareTo(BigDecimal.ZERO) < 0) {
                this.changeGiven = BigDecimal.ZERO; // no negative change
            }
        }
    }

    /**
     * Rebuilds subtotal by summing all SaleItem line totals.
     * Call this after adding or removing items.
     */
    public void recalculateSubtotal() {
        BigDecimal sum = BigDecimal.ZERO;
        for (SaleItem item : items) {
            if (item.getLineTotal() != null) {
                sum = sum.add(item.getLineTotal());
            }
        }
        this.subtotal = sum;
        recalculate();
    }

    /**
     * Convenience check: is this sale in a terminal state
     * (cannot be modified further)?
     */
    public boolean isTerminal() {
        return STATUS_REFUNDED.equals(status) || STATUS_VOID.equals(status);
    }

    /**
     * Returns a display-friendly payment method label.
     * TRANSFER -> "Bank Transfer", POS -> "POS Machine", etc.
     */
    public String getPaymentMethodLabel() {
        if (PAYMENT_CASH.equals(paymentMethod))     return "Cash";
        if (PAYMENT_TRANSFER.equals(paymentMethod)) return "Bank Transfer";
        if (PAYMENT_POS.equals(paymentMethod))      return "POS Machine";
        if (PAYMENT_CREDIT.equals(paymentMethod))   return "Credit / Debt";
        return paymentMethod != null ? paymentMethod : "Unknown";
    }

    /**
     * Returns a Font Awesome icon class that matches the payment method.
     * Used in the JSP to render a payment icon beside the method label.
     */
    public String getPaymentMethodIcon() {
        if (PAYMENT_CASH.equals(paymentMethod))     return "fas fa-money-bill-wave";
        if (PAYMENT_TRANSFER.equals(paymentMethod)) return "fas fa-building-columns";
        if (PAYMENT_POS.equals(paymentMethod))      return "fas fa-credit-card";
        if (PAYMENT_CREDIT.equals(paymentMethod))   return "fas fa-handshake";
        return "fas fa-circle-question";
    }

    /**
     * Returns a CSS class string for the status badge.
     * Matched to the design system colour palette used in categories.jsp / suppliers.jsp.
     */
    public String getStatusBadgeClass() {
        if (STATUS_COMPLETED.equals(status)) return "status-completed";
        if (STATUS_REFUNDED.equals(status))  return "status-refunded";
        if (STATUS_VOID.equals(status))      return "status-void";
        return "";
    }

    // ── Getters & Setters ─────────────────────────────────────

    public int         getId()              { return id; }
    public void        setId(int id)        { this.id = id; }

    public String      getReceiptNumber()              { return receiptNumber; }
    public void        setReceiptNumber(String v)      { this.receiptNumber = v; }

    public LocalDateTime getSaleDate()                 { return saleDate; }
    public void          setSaleDate(LocalDateTime v)  { this.saleDate = v; }

    public String      getCustomerName()               { return customerName; }
    public void        setCustomerName(String v)       { this.customerName = v; }

    public String      getCustomerPhone()              { return customerPhone; }
    public void        setCustomerPhone(String v)      { this.customerPhone = v; }

    public String      getPaymentMethod()              { return paymentMethod; }
    public void        setPaymentMethod(String v)      { this.paymentMethod = v; }

    public BigDecimal  getSubtotal()                   { return subtotal; }
    public void        setSubtotal(BigDecimal v)       { this.subtotal = v; }

    public BigDecimal  getDiscountAmount()             { return discountAmount; }
    public void        setDiscountAmount(BigDecimal v) { this.discountAmount = v; }

    public BigDecimal  getTaxAmount()                  { return taxAmount; }
    public void        setTaxAmount(BigDecimal v)      { this.taxAmount = v; }

    public BigDecimal  getTotalAmount()                 { return totalAmount; }
    public void        setTotalAmount(BigDecimal v)     { this.totalAmount = v; }

    public BigDecimal  getAmountPaid()                 { return amountPaid; }
    public void        setAmountPaid(BigDecimal v)     { this.amountPaid = v; }

    public BigDecimal  getChangeGiven()                { return changeGiven; }
    public void        setChangeGiven(BigDecimal v)    { this.changeGiven = v; }

    public String      getStatus()                     { return status; }
    public void        setStatus(String v)             { this.status = v; }

    public String      getNotes()                      { return notes; }
    public void        setNotes(String v)              { this.notes = v; }

    public String      getServedBy()                   { return servedBy; }
    public void        setServedBy(String v)           { this.servedBy = v; }

    public LocalDateTime getCreatedAt()                { return createdAt; }
    public void          setCreatedAt(LocalDateTime v) { this.createdAt = v; }

    public List<SaleItem> getItems()                   { return items; }
    public void           setItems(List<SaleItem> v)   { this.items = v; }

    public int  getItemCount()                         { return itemCount; }
    public void setItemCount(int v)                    { this.itemCount = v; }

    // ── Utility ───────────────────────────────────────────────

    @Override
    public String toString() {
        return "Sale{id=" + id + ", receipt='" + receiptNumber
                + "', total=" + totalAmount + ", status='" + status + "'}";
    }
}
