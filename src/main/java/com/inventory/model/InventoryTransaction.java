package com.inventory.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * ============================================================
 *  InventoryTransaction - Model / POJO
 * ============================================================
 *
 *  PURPOSE:
 *    Represents ONE row from the inventory_transactions table.
 *    Every time stock moves in or out - whether a delivery arrives,
 *    goods are sold, damaged, returned, or manually adjusted -
 *    one row is written to this table. It is the permanent audit
 *    trail of all stock movements.
 *
 *  WHY IS THIS IMPORTANT?
 *    In accounting and inventory management, every stock change
 *    must be traceable. This table answers the question:
 *      "How did the stock of Product X go from 50 to 12?"
 *    Answer: look up all inventory_transactions for product X.
 *    This is called an INVENTORY LEDGER - exactly like a cash book.
 *
 *  DB TABLE (inventory_transactions):
 *    id               SERIAL PRIMARY KEY
 *    product_id       INT NOT NULL REFERENCES products(id)
 *    transaction_type VARCHAR(20) CHECK (IN ('STOCK_IN','STOCK_OUT',
 *                                  'ADJUSTMENT','DAMAGE','RETURN'))
 *    quantity         INT NOT NULL
 *    unit_cost        NUMERIC(15,2)     -- optional: what was paid
 *    reference_note   VARCHAR(255)      -- optional: e.g. "GRN-001"
 *    performed_by     INT REFERENCES users(id)
 *    transaction_date TIMESTAMP DEFAULT NOW()
 *
 *  TRANSACTION TYPES EXPLAINED:
 *    STOCK_IN    -> goods arrive from supplier (quantity INCREASES)
 *    STOCK_OUT   -> goods leave for a reason other than a sale
 *                  (e.g. transferred to another branch)
 *    ADJUSTMENT  -> manual stock correction (positive or negative)
 *    DAMAGE      -> goods written off as damaged/expired (DECREASES)
 *    RETURN      -> customer returns goods (INCREASES)
 *
 *  NOTE: Sales-driven stock reductions are also recorded here as
 *        STOCK_OUT when a sale is processed, so the full history
 *        is always in one place.
 *
 *  EXTRA FIELDS (not DB columns, joined from other tables):
 *    productName   - joined from products.name
 *    productSku    - joined from products.sku
 *    performedByName - joined from users.full_name
 *
 *  LOCATION: src/com/inventory/model/InventoryTransaction.java
 * ============================================================
 */
public class InventoryTransaction {

    // ── DB columns ────────────────────────────────────────────────
    private int             id;
    private int             productId;
    private String          transactionType;   // STOCK_IN, STOCK_OUT, etc.
    private int             quantity;          // always positive; type determines direction
    private BigDecimal      unitCost;          // what was paid per unit (optional)
    private String          referenceNote;     // e.g. "Invoice #INV-2025-001"
    private int             performedBy;       // user id who did the transaction
    private LocalDateTime   transactionDate;

    // ── Joined / computed fields (not DB columns) ─────────────────
    private String          productName;       // from products.name
    private String          productSku;        // from products.sku
    private String          productUnit;       // from products.unit
    private String          performedByName;   // from users.full_name
    private int             stockBefore;       // product stock BEFORE this transaction
    private int             stockAfter;        // product stock AFTER this transaction

    // ══════════════════════════════════════════════════════════════
    // CONSTRUCTORS
    // ══════════════════════════════════════════════════════════════

    public InventoryTransaction() {}

    /**
     * Convenience constructor for quickly creating a transaction
     * object from the Stock In/Out servlet before calling the DAO.
     */
    public InventoryTransaction(int productId, String transactionType,
                                 int quantity, String referenceNote,
                                 int performedBy) {
        this.productId       = productId;
        this.transactionType = transactionType;
        this.quantity        = quantity;
        this.referenceNote   = referenceNote;
        this.performedBy     = performedBy;
    }

    // ══════════════════════════════════════════════════════════════
    // GETTERS & SETTERS
    // ══════════════════════════════════════════════════════════════

    public int getId()                           { return id; }
    public void setId(int id)                    { this.id = id; }

    public int getProductId()                    { return productId; }
    public void setProductId(int pid)            { this.productId = pid; }

    public String getTransactionType()           { return transactionType; }
    public void setTransactionType(String t)     { this.transactionType = t; }

    public int getQuantity()                     { return quantity; }
    public void setQuantity(int qty)             { this.quantity = qty; }

    public BigDecimal getUnitCost()              { return unitCost; }
    public void setUnitCost(BigDecimal c)        { this.unitCost = c; }

    public String getReferenceNote()             { return referenceNote; }
    public void setReferenceNote(String note)    { this.referenceNote = note; }

    public int getPerformedBy()                  { return performedBy; }
    public void setPerformedBy(int userId)       { this.performedBy = userId; }

    public LocalDateTime getTransactionDate()    { return transactionDate; }
    public void setTransactionDate(LocalDateTime d) { this.transactionDate = d; }

    public String getProductName()               { return productName; }
    public void setProductName(String n)         { this.productName = n; }

    public String getProductSku()                { return productSku; }
    public void setProductSku(String s)          { this.productSku = s; }

    public String getProductUnit()               { return productUnit; }
    public void setProductUnit(String u)         { this.productUnit = u; }

    public String getPerformedByName()           { return performedByName; }
    public void setPerformedByName(String n)     { this.performedByName = n; }

    public int getStockBefore()                  { return stockBefore; }
    public void setStockBefore(int s)            { this.stockBefore = s; }

    public int getStockAfter()                   { return stockAfter; }
    public void setStockAfter(int s)             { this.stockAfter = s; }

    // ══════════════════════════════════════════════════════════════
    // CONVENIENCE HELPERS  (used in JSP via ${tx.xxx})
    // ══════════════════════════════════════════════════════════════

    /**
     * isStockIncreasing()
     * Returns true if this transaction type ADDS to stock.
     * Used in JSP to show a green arrow (↑) for increases.
     *   STOCK_IN  -> true
     *   RETURN    -> true
     *   STOCK_OUT -> false
     *   DAMAGE    -> false
     *   ADJUSTMENT -> depends on quantity sign, but we treat as neutral
     */
    public boolean isStockIncreasing() {
        return "STOCK_IN".equals(transactionType) || "RETURN".equals(transactionType);
    }

    /**
     * isStockDecreasing()
     * Returns true if this transaction type REMOVES from stock.
     * Used in JSP to show a red arrow (↓) for decreases.
     */
    public boolean isStockDecreasing() {
        return "STOCK_OUT".equals(transactionType) || "DAMAGE".equals(transactionType);
    }

    /**
     * getTypeLabel()
     * Human-readable label for each transaction type.
     * Used in the JSP table so users see "Stock In" not "STOCK_IN".
     */
    public String getTypeLabel() {
        switch (transactionType) {
            case "STOCK_IN":    return "Stock In";
            case "STOCK_OUT":   return "Stock Out";
            case "ADJUSTMENT":  return "Adjustment";
            case "DAMAGE":      return "Damage / Write-off";
            case "RETURN":      return "Customer Return";
            default:            return transactionType;
        }
    }

    /**
     * getTypeCssClass()
     * Returns a CSS class name for colour-coding the type badge in the JSP.
     *   Stock In  -> green
     *   Stock Out -> red
     *   Damage    -> orange
     *   Return    -> blue
     *   Adjustment-> grey
     */
    public String getTypeCssClass() {
        switch (transactionType) {
            case "STOCK_IN":    return "type-in";
            case "STOCK_OUT":   return "type-out";
            case "DAMAGE":      return "type-damage";
            case "RETURN":      return "type-return";
            case "ADJUSTMENT":  return "type-adjust";
            default:            return "type-adjust";
        }
    }

    /**
     * getFormattedDate()
     * Returns the transaction date in a readable format.
     * e.g. "06 Jun 2025, 14:32"
     * Used in the JSP table where a raw LocalDateTime looks ugly.
     */
    public String getFormattedDate() {
        if (transactionDate == null) return "-";
        return transactionDate.format(
            DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm")
        );
    }

    /**
     * getSignedQuantity()
     * Returns "+50" for stock increases, "-12" for decreases.
     * Used in the JSP to show the direction clearly in the quantity column.
     */
    public String getSignedQuantity() {
        if (isStockIncreasing())  return "+" + quantity;
        if (isStockDecreasing())  return "-" + quantity;
        return String.valueOf(quantity); // adjustment - no sign
    }

    @Override
    public String toString() {
        return "InventoryTransaction{id=" + id + ", productId=" + productId
             + ", type=" + transactionType + ", qty=" + quantity + "}";
    }
}
