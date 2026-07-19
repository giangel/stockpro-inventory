package com.inventory.dao;

import com.inventory.model.InventoryTransaction;
import com.inventory.util.DatabaseUtil;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * ============================================================
 *  InventoryDAO - Data Access Object
 * ============================================================
 *
 *  PURPOSE:
 *    ALL SQL for inventory_transactions lives here.
 *    No servlet or JSP ever writes SQL directly -
 *    they call DAO methods and get back Java objects.
 *
 *  WHAT THIS DAO DOES:
 *    1. recordTransaction()    - saves any stock movement to DB,
 *                                then updates products.current_stock
 *                                in the SAME transaction (atomic).
 *    2. getAllTransactions()   - full history list with product + user names
 *    3. getByProduct()         - transaction history for one product
 *    4. getRecentTransactions()- last N records (for dashboard widget)
 *    5. getStockInTotal()      - total units received (reporting)
 *    6. getStockOutTotal()     - total units issued (reporting)
 *    7. getLowStockProducts()  - products at/below reorder level
 *    8. getProductCurrentStock()- quick stock lookup by product id
 *
 *  THE CRITICAL CONCEPT - ATOMICITY:
 *    When stock comes in, TWO things must happen together:
 *      a) INSERT a row into inventory_transactions
 *      b) UPDATE products.current_stock
 *    If step (a) succeeds but step (b) fails (e.g. network error),
 *    the books are wrong - transaction says stock came in but the
 *    product still shows old stock. This inconsistency is a BUG.
 *
 *    The solution is a DATABASE TRANSACTION:
 *      conn.setAutoCommit(false);   // start transaction
 *      ... run both SQL statements ...
 *      conn.commit();               // save both at once
 *    If anything fails:
 *      conn.rollback();             // undo EVERYTHING - clean state
 *
 *    This is the ACID principle (Atomicity, Consistency, Isolation,
 *    Durability) that you will study in database courses.
 *
 *  LOCATION: src/com/inventory/dao/InventoryDAO.java
 * ============================================================
 */
public class InventoryDAO {

    // ══════════════════════════════════════════════════════════════
    //  CORE WRITE OPERATION - The most important method in this DAO
    // ══════════════════════════════════════════════════════════════

    /**
     * recordTransaction()
     * -------------------
     * Records a stock movement AND updates the product's current stock
     * in a single atomic database transaction.
     *
     * STEPS:
     *  1. Turn off auto-commit (start our own DB transaction)
     *  2. Get the product's current stock (to calculate stockAfter)
     *  3. Calculate new stock based on transaction type
     *  4. Validate: stock cannot go below 0
     *  5. INSERT into inventory_transactions
     *  6. UPDATE products.current_stock
     *  7. COMMIT both changes
     *  8. On ANY failure: ROLLBACK and throw exception
     *
     * @param tx   The InventoryTransaction object built from the form
     * @throws SQLException  if DB error or insufficient stock
     * @throws IllegalStateException  if transaction would make stock negative
     */
    public void recordTransaction(InventoryTransaction tx)
            throws SQLException, IllegalStateException {

        Connection conn = null;
        PreparedStatement insertPs = null;
        PreparedStatement updatePs = null;
        PreparedStatement selectPs = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            // ── STEP 1: Turn off auto-commit ──────────────────────
            // By default, every SQL statement is immediately committed.
            // We need to group our INSERT + UPDATE into one unit.
            conn.setAutoCommit(false);

            // ── STEP 2: Get the current stock level ───────────────
            selectPs = conn.prepareStatement(
                "SELECT current_stock FROM products WHERE id = ? AND is_active = true");
            selectPs.setInt(1, tx.getProductId());
            rs = selectPs.executeQuery();

            if (!rs.next()) {
                throw new IllegalStateException("Product not found or is inactive.");
            }

            int currentStock = rs.getInt("current_stock");
            rs.close();
            selectPs.close();

            // ── STEP 3: Calculate the new stock level ─────────────
            //
            // Stock-INCREASING types: STOCK_IN, RETURN
            //   new stock = current + quantity
            //
            // Stock-DECREASING types: STOCK_OUT, DAMAGE
            //   new stock = current - quantity
            //
            // ADJUSTMENT: can go either way.
            //   We treat the quantity field as a SIGNED integer for adjustments:
            //     +20 means add 20, -5 means remove 5.
            //   The form sends positive numbers with a separate +/- dropdown,
            //   and the servlet sets the sign before calling this DAO.
            //
            int newStock;
            String type = tx.getTransactionType();

            switch (type) {
                case "STOCK_IN":
                case "RETURN":
                    newStock = currentStock + tx.getQuantity();
                    break;
                case "STOCK_OUT":
                case "DAMAGE":
                    newStock = currentStock - tx.getQuantity();
                    break;
                case "ADJUSTMENT":
                    // For adjustments, quantity can be positive (add) or negative (remove).
                    // The servlet ensures the sign is already set correctly.
                    newStock = currentStock + tx.getQuantity();
                    break;
                default:
                    throw new IllegalArgumentException("Unknown transaction type: " + type);
            }

            // ── STEP 4: Guard against negative stock ──────────────
            // It is physically impossible to have -3 bags of rice.
            // If the user tries to remove more than exists, we reject it.
            if (newStock < 0) {
                throw new IllegalStateException(
                    "Insufficient stock. Current: " + currentStock
                    + ", Attempted removal: " + tx.getQuantity()
                    + ", This would result in: " + newStock
                );
            }

            // Store the before/after values on the transaction object
            // so the DAO caller can show them in a success message
            tx.setStockBefore(currentStock);
            tx.setStockAfter(newStock);

            // ── STEP 5: INSERT the transaction record ─────────────
            // RETURNING id gives us back the auto-generated id.
            String insertSql =
                "INSERT INTO inventory_transactions " +
                "  (product_id, transaction_type, quantity, unit_cost, " +
                "   reference_note, performed_by, transaction_date) " +
                "VALUES (?, ?, ?, ?, ?, ?, NOW()) " +
                "RETURNING id";

            insertPs = conn.prepareStatement(insertSql);
            insertPs.setInt(1, tx.getProductId());
            insertPs.setString(2, tx.getTransactionType());
            insertPs.setInt(3, Math.abs(tx.getQuantity())); // always store as positive

            // unit_cost is optional - null if not provided
            if (tx.getUnitCost() != null && tx.getUnitCost().compareTo(BigDecimal.ZERO) > 0) {
                insertPs.setBigDecimal(4, tx.getUnitCost());
            } else {
                insertPs.setNull(4, Types.NUMERIC);
            }

            // reference_note is optional
            if (tx.getReferenceNote() != null && !tx.getReferenceNote().trim().isEmpty()) {
                insertPs.setString(5, tx.getReferenceNote().trim());
            } else {
                insertPs.setNull(5, Types.VARCHAR);
            }

            insertPs.setInt(6, tx.getPerformedBy());

            rs = insertPs.executeQuery();
            if (rs.next()) {
                tx.setId(rs.getInt(1)); // store the new id on the object
            }
            rs.close();

            // ── STEP 6: UPDATE the product's current stock ────────
            String updateSql =
                "UPDATE products SET current_stock = ?, updated_at = NOW() " +
                "WHERE id = ?";

            updatePs = conn.prepareStatement(updateSql);
            updatePs.setInt(1, newStock);
            updatePs.setInt(2, tx.getProductId());
            updatePs.executeUpdate();

            // ── STEP 7: COMMIT - save both changes to the DB ──────
            // Nothing is saved until commit() is called.
            // Both the INSERT and UPDATE are saved together here.
            conn.commit();

        } catch (Exception e) {
            // ── STEP 8: ROLLBACK on any failure ───────────────────
            // If ANYTHING went wrong, undo the INSERT too.
            // The database is left exactly as it was before this method ran.
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackEx) {
                    System.err.println("Rollback failed: " + rollbackEx.getMessage());
                }
            }
            // Re-throw so the calling servlet can handle the error
            if (e instanceof SQLException) throw (SQLException) e;
            if (e instanceof IllegalStateException) throw (IllegalStateException) e;
            throw new SQLException("Unexpected error during transaction: " + e.getMessage(), e);

        } finally {
            // Always restore auto-commit and close resources
            if (conn != null) {
                try { conn.setAutoCommit(true); } catch (SQLException ignored) {}
            }
            DatabaseUtil.close(rs, insertPs, updatePs, selectPs, conn);
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  READ OPERATIONS
    // ══════════════════════════════════════════════════════════════

    /**
     * getAllTransactions()
     * --------------------
     * Returns the FULL transaction history, joined with product and user data.
     * Used by the main inventory history page.
     *
     * SQL JOINS EXPLAINED:
     *   JOIN products p      -> get product name and SKU
     *   JOIN users u         -> get the full name of who performed the action
     *   ORDER BY DESC        -> newest transactions shown first
     *
     * @param limit  Max number of rows to return. Pass 0 for all records.
     *               Use a limit on the main page to keep it fast (e.g. 200).
     */
    public List<InventoryTransaction> getAllTransactions(int limit)
            throws SQLException {

        List<InventoryTransaction> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            String sql =
                "SELECT t.id, t.product_id, t.transaction_type, t.quantity, " +
                "       t.unit_cost, t.reference_note, t.performed_by, " +
                "       t.transaction_date, " +
                "       p.name AS product_name, p.sku AS product_sku, " +
                "       p.unit AS product_unit, " +
                "       u.full_name AS performed_by_name " +
                "FROM   inventory_transactions t " +
                "JOIN   products p ON t.product_id = p.id " +
                "JOIN   users u    ON t.performed_by = u.id " +
                "ORDER  BY t.transaction_date DESC ";

            // Add LIMIT only if a positive limit is given
            if (limit > 0) sql += "LIMIT " + limit;

            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(mapRow(rs));
            }

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }

        return list;
    }

    /**
     * getTransactionsByProduct()
     * --------------------------
     * Returns ALL transaction history for ONE specific product.
     * Used when the user clicks "View History" on a product row.
     *
     * This answers: "Show me every time Product X moved."
     */
    public List<InventoryTransaction> getTransactionsByProduct(int productId)
            throws SQLException {

        List<InventoryTransaction> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            String sql =
                "SELECT t.id, t.product_id, t.transaction_type, t.quantity, " +
                "       t.unit_cost, t.reference_note, t.performed_by, " +
                "       t.transaction_date, " +
                "       p.name AS product_name, p.sku AS product_sku, " +
                "       p.unit AS product_unit, " +
                "       u.full_name AS performed_by_name " +
                "FROM   inventory_transactions t " +
                "JOIN   products p ON t.product_id = p.id " +
                "JOIN   users u    ON t.performed_by = u.id " +
                "WHERE  t.product_id = ? " +
                "ORDER  BY t.transaction_date DESC";

            ps = conn.prepareStatement(sql);
            ps.setInt(1, productId);
            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(mapRow(rs));
            }

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }

        return list;
    }

    /**
     * getRecentTransactions()
     * -----------------------
     * Returns the most recent N transactions.
     * Used by the dashboard "Recent Activity" widget.
     * Typically called with limit = 8 or 10.
     */
    public List<InventoryTransaction> getRecentTransactions(int limit)
            throws SQLException {
        return getAllTransactions(limit);
    }

    /**
     * getTransactionsByType()
     * -----------------------
     * Returns all transactions of a specific type.
     * e.g. getTransactionsByType("STOCK_IN") to see all deliveries.
     * Used for reports and filtering.
     */
    public List<InventoryTransaction> getTransactionsByType(String type)
            throws SQLException {

        List<InventoryTransaction> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            String sql =
                "SELECT t.id, t.product_id, t.transaction_type, t.quantity, " +
                "       t.unit_cost, t.reference_note, t.performed_by, " +
                "       t.transaction_date, " +
                "       p.name AS product_name, p.sku AS product_sku, " +
                "       p.unit AS product_unit, " +
                "       u.full_name AS performed_by_name " +
                "FROM   inventory_transactions t " +
                "JOIN   products p ON t.product_id = p.id " +
                "JOIN   users u    ON t.performed_by = u.id " +
                "WHERE  t.transaction_type = ? " +
                "ORDER  BY t.transaction_date DESC";

            ps = conn.prepareStatement(sql);
            ps.setString(1, type);
            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(mapRow(rs));
            }

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }

        return list;
    }

    /**
     * getTransactionsByDateRange()
     * ----------------------------
     * Returns all transactions between two dates.
     * e.g. for the monthly stock report.
     *
     * @param from  Start date as a SQL Timestamp (inclusive)
     * @param to    End date as a SQL Timestamp (inclusive)
     */
    public List<InventoryTransaction> getTransactionsByDateRange(
            Timestamp from, Timestamp to) throws SQLException {

        List<InventoryTransaction> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            String sql =
                "SELECT t.id, t.product_id, t.transaction_type, t.quantity, " +
                "       t.unit_cost, t.reference_note, t.performed_by, " +
                "       t.transaction_date, " +
                "       p.name AS product_name, p.sku AS product_sku, " +
                "       p.unit AS product_unit, " +
                "       u.full_name AS performed_by_name " +
                "FROM   inventory_transactions t " +
                "JOIN   products p ON t.product_id = p.id " +
                "JOIN   users u    ON t.performed_by = u.id " +
                "WHERE  t.transaction_date BETWEEN ? AND ? " +
                "ORDER  BY t.transaction_date DESC";

            ps = conn.prepareStatement(sql);
            ps.setTimestamp(1, from);
            ps.setTimestamp(2, to);
            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(mapRow(rs));
            }

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }

        return list;
    }

    // ══════════════════════════════════════════════════════════════
    //  SUMMARY / REPORTING METHODS
    // ══════════════════════════════════════════════════════════════

    /**
     * getTotalTransactionCount()
     * --------------------------
     * Total number of rows in inventory_transactions.
     * Used for the dashboard KPI counter.
     */
    public int getTotalTransactionCount() throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM inventory_transactions");
            rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    /**
     * getTotalStockIn()
     * -----------------
     * Total units received (all STOCK_IN + RETURN transactions).
     * Used for the Stock In summary KPI on the inventory page.
     */
    public int getTotalStockIn() throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT COALESCE(SUM(quantity), 0) " +
                "FROM inventory_transactions " +
                "WHERE transaction_type IN ('STOCK_IN', 'RETURN')");
            rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    /**
     * getTotalStockOut()
     * ------------------
     * Total units removed (all STOCK_OUT + DAMAGE transactions).
     * Used for the Stock Out summary KPI.
     */
    public int getTotalStockOut() throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT COALESCE(SUM(quantity), 0) " +
                "FROM inventory_transactions " +
                "WHERE transaction_type IN ('STOCK_OUT', 'DAMAGE')");
            rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    /**
     * getTodayTransactionCount()
     * --------------------------
     * Number of stock movements recorded today.
     * Used for the dashboard live counter.
     *
     * DATE_TRUNC('day', ...) is PostgreSQL syntax that rounds a
     * timestamp down to midnight - so we match any time on today's date.
     */
    public int getTodayTransactionCount() throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM inventory_transactions " +
                "WHERE DATE_TRUNC('day', transaction_date) = DATE_TRUNC('day', NOW())");
            rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    /**
     * getStockInThisMonth()
     * ---------------------
     * Total units received THIS calendar month.
     * Used for the monthly stock-in KPI on the dashboard.
     */
    public int getStockInThisMonth() throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT COALESCE(SUM(quantity), 0) " +
                "FROM inventory_transactions " +
                "WHERE transaction_type IN ('STOCK_IN', 'RETURN') " +
                "  AND DATE_TRUNC('month', transaction_date) = DATE_TRUNC('month', NOW())");
            rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    /**
     * getProductCurrentStock()
     * ------------------------
     * Quick lookup of a product's current stock level.
     * Used before rendering the Stock In/Out form to show
     * the user the current quantity.
     *
     * Returns -1 if the product is not found.
     */
    public int getProductCurrentStock(int productId) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT current_stock FROM products " +
                "WHERE id = ? AND is_active = true");
            ps.setInt(1, productId);
            rs = ps.executeQuery();
            return rs.next() ? rs.getInt("current_stock") : -1;
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    /**
     * getLowStockCount()
     * ------------------
     * Number of active products at or below their reorder level.
     * Used for the dashboard low-stock alert badge number.
     */
    public int getLowStockCount() throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM products " +
                "WHERE is_active = true " +
                "  AND current_stock <= reorder_level");
            rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  PRIVATE HELPER
    // ══════════════════════════════════════════════════════════════

    /**
     * mapRow()
     * --------
     * Maps ONE ResultSet row -> ONE InventoryTransaction object.
     * Called from every SELECT method to avoid duplicating
     * rs.getString("product_name") etc. across every query method.
     *
     * DRY PRINCIPLE: Don't Repeat Yourself.
     */
    private InventoryTransaction mapRow(ResultSet rs) throws SQLException {
        InventoryTransaction tx = new InventoryTransaction();

        tx.setId(rs.getInt("id"));
        tx.setProductId(rs.getInt("product_id"));
        tx.setTransactionType(rs.getString("transaction_type"));
        tx.setQuantity(rs.getInt("quantity"));
        tx.setUnitCost(rs.getBigDecimal("unit_cost"));
        tx.setReferenceNote(rs.getString("reference_note"));
        tx.setPerformedBy(rs.getInt("performed_by"));

        // Map joined columns from products and users tables
        tx.setProductName(rs.getString("product_name"));
        tx.setProductSku(rs.getString("product_sku"));
        tx.setProductUnit(rs.getString("product_unit"));
        tx.setPerformedByName(rs.getString("performed_by_name"));

        // Convert SQL Timestamp -> Java LocalDateTime
        Timestamp txDate = rs.getTimestamp("transaction_date");
        if (txDate != null) {
            tx.setTransactionDate(txDate.toLocalDateTime());
        }

        return tx;
    }
}
