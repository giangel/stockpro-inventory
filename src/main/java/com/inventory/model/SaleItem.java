package com.inventory.model;

import java.math.BigDecimal;

/**
 * SaleItem - mirrors the "sale_items" table in PostgreSQL.
 * One instance = one line item inside a sale.
 *
 * Relationship:
 *   Sale (1) ──< SaleItem (N)
 *   Each SaleItem belongs to exactly one Sale and references one Product.
 *
 * Database columns this class maps to:
 * ─────────────────────────────────────────────────────────────────
 *   id              SERIAL PRIMARY KEY
 *   sale_id         INT NOT NULL REFERENCES sales(id) ON DELETE CASCADE
 *   product_id      INT NOT NULL REFERENCES products(id)
 *   product_name    VARCHAR(200) NOT NULL    - snapshot at time of sale
 *   quantity        INT NOT NULL CHECK (quantity > 0)
 *   unit_price      NUMERIC(12,2) NOT NULL   - selling price at time of sale
 *   cost_price      NUMERIC(12,2) NOT NULL   - cost at time of sale (for profit calc)
 *   discount_pct    NUMERIC(5,2) NOT NULL DEFAULT 0  - % discount on this line
 *   line_total      NUMERIC(12,2) NOT NULL   - qty × unit_price × (1 - discount_pct/100)
 * ─────────────────────────────────────────────────────────────────
 *
 * WHY snapshot product_name, unit_price, and cost_price?
 *   Products can be renamed or repriced after a sale. Storing the values
 *   at the time of the sale preserves the historical accuracy of every
 *   receipt and profit report.
 *
 * Extra transient fields (not DB columns):
 *   profit       - (unit_price - cost_price) × quantity  (computed)
 *   profitMargin - profit / line_total as a percentage   (computed)
 */
public class SaleItem {

    // ── Database columns ─────────────────────────────────────
    private int        id;
    private int        saleId;
    private int        productId;
    private String     productName;   // snapshot - NOT a FK join
    private int        quantity;
    private BigDecimal unitPrice;     // selling price at time of sale
    private BigDecimal costPrice;     // cost price at time of sale
    private BigDecimal discountPct;   // e.g. 10.00 = 10%
    private BigDecimal lineTotal;     // qty × unitPrice × (1 - discountPct/100)

    // ── Transient / computed ─────────────────────────────────
    private String     productSku;    // loaded from products table for display

    // ── Constructor ──────────────────────────────────────────

    public SaleItem() {
        this.quantity    = 1;
        this.discountPct = BigDecimal.ZERO;
        this.costPrice   = BigDecimal.ZERO;
    }

    /**
     * Convenience constructor - used by the POS servlet when building
     * a sale item from the cart form data.
     */
    public SaleItem(int productId, String productName,
                    int quantity, BigDecimal unitPrice, BigDecimal costPrice) {
        this.productId   = productId;
        this.productName = productName;
        this.quantity    = quantity;
        this.unitPrice   = unitPrice;
        this.costPrice   = costPrice;
        this.discountPct = BigDecimal.ZERO;
        recalculate();
    }

    // ── Computed helpers ─────────────────────────────────────

    /**
     * Recalculates lineTotal from quantity, unitPrice, and discountPct.
     *
     * Formula: lineTotal = quantity × unitPrice × (1 - discountPct / 100)
     *
     * Call this any time quantity, unitPrice, or discountPct changes.
     */
    public void recalculate() {
        if (unitPrice == null) { this.lineTotal = BigDecimal.ZERO; return; }

        BigDecimal qty  = BigDecimal.valueOf(quantity);
        BigDecimal disc = discountPct != null ? discountPct : BigDecimal.ZERO;

        // multiplier = 1 - (discountPct / 100)
        BigDecimal multiplier = BigDecimal.ONE
                .subtract(disc.divide(BigDecimal.valueOf(100),
                        4, java.math.RoundingMode.HALF_UP));

        this.lineTotal = qty.multiply(unitPrice)
                           .multiply(multiplier)
                           .setScale(2, java.math.RoundingMode.HALF_UP);
    }

    /**
     * Profit on this line: (unitPrice - costPrice) × quantity
     *
     * WHY calculate per-line?
     *   Allows the sales report to break down profit by product line,
     *   not just per-sale - useful for identifying which products
     *   actually earn the most margin.
     */
    public BigDecimal getProfit() {
        if (unitPrice == null || costPrice == null) return BigDecimal.ZERO;
        BigDecimal margin = unitPrice.subtract(costPrice);
        return margin.multiply(BigDecimal.valueOf(quantity))
                     .setScale(2, java.math.RoundingMode.HALF_UP);
    }

    /**
     * Profit margin percentage: profit / lineTotal × 100
     * Returns 0 if lineTotal is zero (avoid division by zero).
     */
    public BigDecimal getProfitMarginPct() {
        BigDecimal profit = getProfit();
        if (lineTotal == null || lineTotal.compareTo(BigDecimal.ZERO) == 0) {
            return BigDecimal.ZERO;
        }
        return profit.divide(lineTotal, 4, java.math.RoundingMode.HALF_UP)
                     .multiply(BigDecimal.valueOf(100))
                     .setScale(2, java.math.RoundingMode.HALF_UP);
    }

    // ── Getters & Setters ─────────────────────────────────────

    public int        getId()               { return id; }
    public void       setId(int id)         { this.id = id; }

    public int        getSaleId()           { return saleId; }
    public void       setSaleId(int v)      { this.saleId = v; }

    public int        getProductId()        { return productId; }
    public void       setProductId(int v)   { this.productId = v; }

    public String     getProductName()      { return productName; }
    public void       setProductName(String v) { this.productName = v; }

    public int        getQuantity()         { return quantity; }
    public void       setQuantity(int v)    { this.quantity = v; }

    public BigDecimal getUnitPrice()        { return unitPrice; }
    public void       setUnitPrice(BigDecimal v) { this.unitPrice = v; }

    public BigDecimal getCostPrice()        { return costPrice; }
    public void       setCostPrice(BigDecimal v) { this.costPrice = v; }

    public BigDecimal getDiscountPct()      { return discountPct; }
    public void       setDiscountPct(BigDecimal v) { this.discountPct = v; }

    public BigDecimal getLineTotal()        { return lineTotal; }
    public void       setLineTotal(BigDecimal v) { this.lineTotal = v; }

    public String     getProductSku()       { return productSku; }
    public void       setProductSku(String v) { this.productSku = v; }

    // ── Utility ───────────────────────────────────────────────

    @Override
    public String toString() {
        return "SaleItem{productId=" + productId
                + ", name='" + productName + "'"
                + ", qty=" + quantity
                + ", unitPrice=" + unitPrice
                + ", lineTotal=" + lineTotal + "}";
    }
}
