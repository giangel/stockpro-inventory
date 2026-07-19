package com.inventory.dao;

import com.inventory.model.Sale;
import com.inventory.model.SaleItem;
import com.inventory.util.DatabaseUtil;

import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * SaleDAO - Data Access Object
 * ─────────────────────────────────────────────────────────────────
 * ALL SQL for the sales and sale_items tables lives here.
 * Servlets NEVER write SQL - they call DAO methods.
 */
public class SaleDAO {

    // ══════════════════════════════════════════════════════════
    // CREATE - the core POS operation
    // ══════════════════════════════════════════════════════════

    public int createSale(Sale sale) throws SQLException {
        Connection conn = null;

        try {
            conn = DatabaseUtil.getConnection();
            conn.setAutoCommit(false); // BEGIN TRANSACTION

            String receiptNumber = generateReceiptNumber(conn);
            sale.setReceiptNumber(receiptNumber);

            int saleId = insertSaleHeader(conn, sale);
            sale.setId(saleId);

            for (SaleItem item : sale.getItems()) {
                insertSaleItem(conn, saleId, item);
                deductStock(conn, item.getProductId(), item.getQuantity());
            }

            conn.commit();
            return saleId;

        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ignored) {}
            }
            throw e;

        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); } catch (SQLException ignored) {}
            }
            DatabaseUtil.close(null, null, conn);
        }
    }

    // ══════════════════════════════════════════════════════════
    // READ - fetching sales
    // ══════════════════════════════════════════════════════════

    public List<Sale> getAllSales() throws SQLException {
        List<Sale> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            String sql =
                "SELECT s.*, " +
                "       COUNT(si.id) AS item_count " +
                "FROM   sales s " +
                "LEFT JOIN sale_items si ON si.sale_id = s.id " +
                "GROUP BY s.id " +
                "ORDER BY s.sale_date DESC";

            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(mapSaleRow(rs, true));
            }
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
        return list;
    }

    public List<Sale> getFilteredSales(LocalDate from, LocalDate to,
                                       String status, String paymentMethod)
            throws SQLException {

        List<Sale> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            StringBuilder sql = new StringBuilder(
                "SELECT s.*, COUNT(si.id) AS item_count " +
                "FROM   sales s " +
                "LEFT JOIN sale_items si ON si.sale_id = s.id "
            );

            List<Object> params = new ArrayList<>();
            List<String> conditions = new ArrayList<>();

            if (from != null) {
                conditions.add("s.sale_date >= ?");
                params.add(Timestamp.valueOf(from.atStartOfDay()));
            }
            if (to != null) {
                conditions.add("s.sale_date < ?");
                params.add(Timestamp.valueOf(to.plusDays(1).atStartOfDay()));
            }
            if (status != null && !status.trim().isEmpty()) {
                conditions.add("s.status = ?");
                params.add(status.trim());
            }
            if (paymentMethod != null && !paymentMethod.trim().isEmpty()) {
                conditions.add("s.payment_method = ?");
                params.add(paymentMethod.trim());
            }

            if (!conditions.isEmpty()) {
                sql.append("WHERE ").append(String.join(" AND ", conditions)).append(" ");
            }

            sql.append("GROUP BY s.id ORDER BY s.sale_date DESC");

            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                Object p = params.get(i);
                if (p instanceof Timestamp) ps.setTimestamp(i + 1, (Timestamp) p);
                else                        ps.setString(i + 1, (String) p);
            }

            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapSaleRow(rs, true));
            }

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
        return list;
    }

    public List<Sale> getSalesByDate(LocalDate date) throws SQLException {
        return getFilteredSales(date, date, null, null);
    }

    public Sale getSaleById(int id) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            ps = conn.prepareStatement(
                "SELECT s.*, COUNT(si.id) AS item_count " +
                "FROM   sales s " +
                "LEFT JOIN sale_items si ON si.sale_id = s.id " +
                "WHERE  s.id = ? " +
                "GROUP BY s.id");
            ps.setInt(1, id);
            rs = ps.executeQuery();

            if (!rs.next()) return null;
            Sale sale = mapSaleRow(rs, true);
            DatabaseUtil.close(rs, ps, null);

            ps = conn.prepareStatement(
                "SELECT si.*, p.sku AS product_sku " +
                "FROM   sale_items si " +
                "LEFT JOIN products p ON p.id = si.product_id " +
                "WHERE  si.sale_id = ? " +
                "ORDER BY si.id ASC");
            ps.setInt(1, id);
            rs = ps.executeQuery();

            List<SaleItem> items = new ArrayList<>();
            while (rs.next()) {
                items.add(mapItemRow(rs));
            }
            sale.setItems(items);
            return sale;

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    public Sale getSaleByReceiptNumber(String receiptNumber) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT id FROM sales WHERE receipt_number = ?");
            ps.setString(1, receiptNumber.trim());
            rs = ps.executeQuery();
            if (!rs.next()) return null;
            int id = rs.getInt("id");
            DatabaseUtil.close(rs, ps, null);
            return getSaleById(id);

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    // ══════════════════════════════════════════════════════════
    // STATUS CHANGES - void & refund
    // ══════════════════════════════════════════════════════════

    public int voidSale(int saleId) throws SQLException {
        Connection conn = null;

        try {
            conn = DatabaseUtil.getConnection();
            conn.setAutoCommit(false);

            Sale sale = getSaleById(saleId);
            if (sale == null) { conn.commit(); return 0; }
            if (sale.isTerminal()) { conn.commit(); return -1; }

            updateSaleStatus(conn, saleId, Sale.STATUS_VOID);

            for (SaleItem item : sale.getItems()) {
                restoreStock(conn, item.getProductId(), item.getQuantity());
            }

            conn.commit();
            return 1;

        } catch (SQLException e) {
            if (conn != null) try { conn.rollback(); } catch (SQLException ignored) {}
            throw e;
        } finally {
            if (conn != null) try { conn.setAutoCommit(true); } catch (SQLException ignored) {}
            DatabaseUtil.close(null, null, conn);
        }
    }

    public int refundSale(int saleId) throws SQLException {
        Connection conn = null;

        try {
            conn = DatabaseUtil.getConnection();
            conn.setAutoCommit(false);

            Sale sale = getSaleById(saleId);
            if (sale == null) { conn.commit(); return 0; }
            if (sale.isTerminal()) { conn.commit(); return -1; }

            updateSaleStatus(conn, saleId, Sale.STATUS_REFUNDED);

            for (SaleItem item : sale.getItems()) {
                restoreStock(conn, item.getProductId(), item.getQuantity());
            }

            conn.commit();
            return 1;

        } catch (SQLException e) {
            if (conn != null) try { conn.rollback(); } catch (SQLException ignored) {}
            throw e;
        } finally {
            if (conn != null) try { conn.setAutoCommit(true); } catch (SQLException ignored) {}
            DatabaseUtil.close(null, null, conn);
        }
    }

    // ══════════════════════════════════════════════════════════
    // REPORTING / ANALYTICS
    // ══════════════════════════════════════════════════════════

    public Map<String, Object> getSalesSummary(LocalDate from, LocalDate to)
            throws SQLException {

        Map<String, Object> summary = new LinkedHashMap<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            StringBuilder revSql = new StringBuilder(
                "SELECT " +
                "  COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) AS completed_count, " +
                "  COUNT(CASE WHEN status = 'REFUNDED'  THEN 1 END) AS refunded_count, " +
                "  COUNT(CASE WHEN status = 'VOID'      THEN 1 END) AS void_count, " +
                "  COALESCE(SUM(CASE WHEN status = 'COMPLETED' THEN total_amount END), 0) AS total_revenue " +
                "FROM sales "
            );
            List<Timestamp> dateParams = buildDateParams(from, to);
            if (!dateParams.isEmpty()) {
                revSql.append("WHERE sale_date >= ? AND sale_date < ? ");
            }

            ps = conn.prepareStatement(revSql.toString());
            setDateParams(ps, dateParams);
            rs = ps.executeQuery();

            if (rs.next()) {
                int completed = rs.getInt("completed_count");
                summary.put("totalSales",     completed);
                summary.put("completedCount", completed);
                summary.put("refundedCount",  rs.getInt("refunded_count"));
                summary.put("voidCount",      rs.getInt("void_count"));
                BigDecimal revenue = rs.getBigDecimal("total_revenue");
                summary.put("totalRevenue",   revenue);
                summary.put("avgOrderValue",
                    completed > 0
                        ? revenue.divide(BigDecimal.valueOf(completed), 2, java.math.RoundingMode.HALF_UP)
                        : BigDecimal.ZERO);
            }
            DatabaseUtil.close(rs, ps, null);

            StringBuilder profitSql = new StringBuilder(
                "SELECT " +
                "  COALESCE(SUM((si.unit_price - si.cost_price) * si.quantity), 0) AS total_profit, " +
                "  COALESCE(SUM(si.quantity), 0) AS items_sold " +
                "FROM sale_items si " +
                "JOIN sales s ON s.id = si.sale_id " +
                "WHERE s.status = 'COMPLETED' "
            );
            if (!dateParams.isEmpty()) {
                profitSql.append("AND s.sale_date >= ? AND s.sale_date < ? ");
            }

            ps = conn.prepareStatement(profitSql.toString());
            setDateParams(ps, dateParams);
            rs = ps.executeQuery();

            if (rs.next()) {
                summary.put("totalProfit",    rs.getBigDecimal("total_profit"));
                summary.put("totalItemsSold", rs.getInt("items_sold"));
            }

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }

        return summary;
    }

    public Map<String, Object> getTodaySummary() throws SQLException {
        LocalDate today = LocalDate.now();
        return getSalesSummary(today, today);
    }

    public List<Map<String, Object>> getTopSellingProducts(int limit,
                                                           LocalDate from,
                                                           LocalDate to)
            throws SQLException {

        List<Map<String, Object>> rows = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            StringBuilder sql = new StringBuilder(
                "SELECT si.product_id, si.product_name, " +
                "       SUM(si.quantity)    AS total_qty, " +
                "       SUM(si.line_total)  AS total_revenue, " +
                "       SUM((si.unit_price - si.cost_price) * si.quantity) AS total_profit " +
                "FROM   sale_items si " +
                "JOIN   sales s ON s.id = si.sale_id " +
                "WHERE  s.status = 'COMPLETED' "
            );

            List<Timestamp> dateParams = buildDateParams(from, to);
            if (!dateParams.isEmpty()) {
                sql.append("AND s.sale_date >= ? AND s.sale_date < ? ");
            }

            sql.append("GROUP BY si.product_id, si.product_name ")
               .append("ORDER BY total_qty DESC ")
               .append("LIMIT ?");

            ps = conn.prepareStatement(sql.toString());
            int paramIdx = setDateParams(ps, dateParams);
            ps.setInt(paramIdx, limit);

            rs = ps.executeQuery();

            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("productId",    rs.getInt("product_id"));
                row.put("productName",  rs.getString("product_name"));
                row.put("totalQty",     rs.getInt("total_qty"));
                row.put("totalRevenue", rs.getBigDecimal("total_revenue"));
                row.put("totalProfit",  rs.getBigDecimal("total_profit"));
                rows.add(row);
            }

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
        return rows;
    }

    public List<Map<String, Object>> getDailyRevenueTrend(LocalDate from, LocalDate to)
            throws SQLException {

        List<Map<String, Object>> rows = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            String sql =
                "SELECT DATE(s.sale_date)          AS sale_day, " +
                "       COUNT(s.id)                AS sales_count, " +
                "       SUM(s.total_amount)         AS revenue, " +
                "       COALESCE(SUM((si.unit_price - si.cost_price) * si.quantity), 0) AS profit " +
                "FROM   sales s " +
                "LEFT JOIN sale_items si ON si.sale_id = s.id " +
                "WHERE  s.status = 'COMPLETED' " +
                "  AND  s.sale_date >= ? " +
                "  AND  s.sale_date <  ? " +
                "GROUP BY DATE(s.sale_date) " +
                "ORDER BY sale_day ASC";

            ps = conn.prepareStatement(sql);
            ps.setTimestamp(1, Timestamp.valueOf(from.atStartOfDay()));
            ps.setTimestamp(2, Timestamp.valueOf(to.plusDays(1).atStartOfDay()));
            rs = ps.executeQuery();

            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("date",       rs.getDate("sale_day").toString());
                row.put("salesCount", rs.getInt("sales_count"));
                row.put("revenue",    rs.getBigDecimal("revenue"));
                row.put("profit",     rs.getBigDecimal("profit"));
                rows.add(row);
            }

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
        return rows;
    }

    public List<Map<String, Object>> getRevenueByPaymentMethod(LocalDate from, LocalDate to)
            throws SQLException {

        List<Map<String, Object>> rows = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            StringBuilder sql = new StringBuilder(
                "SELECT payment_method, " +
                "       COUNT(*) AS sales_count, " +
                "       SUM(total_amount) AS revenue " +
                "FROM   sales " +
                "WHERE  status = 'COMPLETED' "
            );
            List<Timestamp> dateParams = buildDateParams(from, to);
            if (!dateParams.isEmpty()) {
                sql.append("AND sale_date >= ? AND sale_date < ? ");
            }
            sql.append("GROUP BY payment_method ORDER BY revenue DESC");

            ps = conn.prepareStatement(sql.toString());
            setDateParams(ps, dateParams);
            rs = ps.executeQuery();

            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("paymentMethod", rs.getString("payment_method"));
                row.put("salesCount",    rs.getInt("sales_count"));
                row.put("revenue",       rs.getBigDecimal("revenue"));
                rows.add(row);
            }

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
        return rows;
    }

    // ══════════════════════════════════════════════════════════
    // STOCK VALIDATION (called before createSale)
    // ══════════════════════════════════════════════════════════

    public List<String> validateStock(List<SaleItem> items) throws SQLException {
        List<String> errors = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            ps = conn.prepareStatement(
                "SELECT id, name, current_stock, is_active FROM products WHERE id = ?");

            for (SaleItem item : items) {
                ps.setInt(1, item.getProductId());
                rs = ps.executeQuery();

                if (!rs.next()) {
                    errors.add("Product ID " + item.getProductId()
                            + " (" + item.getProductName() + ") no longer exists.");
                } else {
                    boolean active = rs.getBoolean("is_active");
                    int     stock  = rs.getInt("current_stock");
                    String  pname  = rs.getString("name");

                    if (!active) {
                        errors.add("\"" + pname + "\" has been deactivated and cannot be sold.");
                    } else if (stock < item.getQuantity()) {
                        errors.add("\"" + pname + "\" - only " + stock
                                + " unit(s) in stock, but " + item.getQuantity()
                                + " requested.");
                    }
                }
                rs.close();
            }

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
        return errors;
    }

    // ══════════════════════════════════════════════════════════
    // RECEIPT NUMBER GENERATION
    // ══════════════════════════════════════════════════════════

    private String generateReceiptNumber(Connection conn) throws SQLException {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(
                "SELECT COUNT(*) + 1 AS next_seq FROM sales " +
                "WHERE DATE(sale_date) = CURRENT_DATE");
            rs = ps.executeQuery();
            int seq = rs.next() ? rs.getInt("next_seq") : 1;

            String datePart = LocalDate.now()
                    .format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMdd"));
            return String.format("RCP-%s-%04d", datePart, seq);

        } finally {
            DatabaseUtil.close(rs, ps, null);
        }
    }

    // ══════════════════════════════════════════════════════════
    // PRIVATE - SQL helpers (called from inside transactions)
    // ══════════════════════════════════════════════════════════

    private int insertSaleHeader(Connection conn, Sale sale) throws SQLException {
        String sql =
            "INSERT INTO sales " +
            "  (receipt_number, sale_date, customer_name, customer_phone, payment_method, " +
            "   subtotal, discount_amount, tax_amount, total_amount, " +
            "   amount_paid, change_given, status, notes, served_by) " +
            "VALUES (?,?,?,?,?, ?,?,?,?, ?,?,?,?,?) " +
            "RETURNING id";

        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, sale.getReceiptNumber());
        ps.setTimestamp(2, sale.getSaleDate() != null
                ? Timestamp.valueOf(sale.getSaleDate())
                : new Timestamp(System.currentTimeMillis()));
        setNullableString(ps, 3, sale.getCustomerName());
        setNullableString(ps, 4, sale.getCustomerPhone());
        ps.setString(5, sale.getPaymentMethod());
        ps.setBigDecimal(6,  sale.getSubtotal());
        ps.setBigDecimal(7,  sale.getDiscountAmount());
        ps.setBigDecimal(8,  sale.getTaxAmount());
        ps.setBigDecimal(9,  sale.getTotalAmount());
        ps.setBigDecimal(10, sale.getAmountPaid());
        ps.setBigDecimal(11, sale.getChangeGiven());
        ps.setString(12, sale.getStatus());
        setNullableString(ps, 13, sale.getNotes());
        setNullableString(ps, 14, sale.getServedBy());

        ResultSet rs = ps.executeQuery();
        int id = rs.next() ? rs.getInt(1) : -1;
        DatabaseUtil.close(rs, ps, null);
        return id;
    }

    private void insertSaleItem(Connection conn, int saleId, SaleItem item)
            throws SQLException {
        String sql =
            "INSERT INTO sale_items " +
            "  (sale_id, product_id, product_name, quantity, unit_price, cost_price, discount_pct, line_total) " +
            "VALUES (?,?,?,?,?,?,?,?)";

        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setInt(1, saleId);
        ps.setInt(2, item.getProductId());
        ps.setString(3, item.getProductName());
        ps.setInt(4, item.getQuantity());
        ps.setBigDecimal(5, item.getUnitPrice());
        ps.setBigDecimal(6, item.getCostPrice() != null ? item.getCostPrice() : BigDecimal.ZERO);
        ps.setBigDecimal(7, item.getDiscountPct() != null ? item.getDiscountPct() : BigDecimal.ZERO);
        ps.setBigDecimal(8, item.getLineTotal());
        ps.executeUpdate();
        DatabaseUtil.close(null, ps, null);
    }

    private void deductStock(Connection conn, int productId, int qty)
            throws SQLException {

        PreparedStatement ps = conn.prepareStatement(
            "UPDATE products SET current_stock = current_stock - ? " +
            "WHERE id = ? AND current_stock >= ?");
        ps.setInt(1, qty);
        ps.setInt(2, productId);
        ps.setInt(3, qty);

        int rows = ps.executeUpdate();
        DatabaseUtil.close(null, ps, null);

        if (rows == 0) {
            throw new SQLException(
                "Insufficient stock for product id=" + productId
                + " - transaction rolled back.");
        }
    }

    private void restoreStock(Connection conn, int productId, int qty)
            throws SQLException {
        PreparedStatement ps = conn.prepareStatement(
            "UPDATE products SET current_stock = current_stock + ? WHERE id = ?");
        ps.setInt(1, qty);
        ps.setInt(2, productId);
        ps.executeUpdate();
        DatabaseUtil.close(null, ps, null);
    }

    private void updateSaleStatus(Connection conn, int saleId, String newStatus)
            throws SQLException {
        PreparedStatement ps = conn.prepareStatement(
            "UPDATE sales SET status = ? WHERE id = ?");
        ps.setString(1, newStatus);
        ps.setInt(2, saleId);
        ps.executeUpdate();
        DatabaseUtil.close(null, ps, null);
    }

    // ══════════════════════════════════════════════════════════
    // PRIVATE - Row mapping helpers
    // ══════════════════════════════════════════════════════════

    private Sale mapSaleRow(ResultSet rs, boolean withItemCount) throws SQLException {
        Sale s = new Sale();
        s.setId(rs.getInt("id"));
        s.setReceiptNumber(rs.getString("receipt_number"));
        s.setCustomerName(rs.getString("customer_name"));
        s.setCustomerPhone(rs.getString("customer_phone"));
        s.setPaymentMethod(rs.getString("payment_method"));
        s.setSubtotal(rs.getBigDecimal("subtotal"));
        s.setDiscountAmount(rs.getBigDecimal("discount_amount"));
        s.setTaxAmount(rs.getBigDecimal("tax_amount"));
        s.setTotalAmount(rs.getBigDecimal("total_amount"));
        s.setAmountPaid(rs.getBigDecimal("amount_paid"));
        s.setChangeGiven(rs.getBigDecimal("change_given"));
        s.setStatus(rs.getString("status"));
        s.setNotes(rs.getString("notes"));
        s.setServedBy(rs.getString("served_by"));

        Timestamp saleDate = rs.getTimestamp("sale_date");
        if (saleDate != null) s.setSaleDate(saleDate.toLocalDateTime());

        if (withItemCount) s.setItemCount(rs.getInt("item_count"));
        return s;
    }

    private SaleItem mapItemRow(ResultSet rs) throws SQLException {
        SaleItem item = new SaleItem();
        item.setId(rs.getInt("id"));
        item.setSaleId(rs.getInt("sale_id"));
        item.setProductId(rs.getInt("product_id"));
        item.setProductName(rs.getString("product_name"));
        item.setQuantity(rs.getInt("quantity"));
        item.setUnitPrice(rs.getBigDecimal("unit_price"));
        item.setCostPrice(rs.getBigDecimal("cost_price"));
        item.setDiscountPct(rs.getBigDecimal("discount_pct"));
        item.setLineTotal(rs.getBigDecimal("line_total"));

        try { item.setProductSku(rs.getString("product_sku")); }
        catch (SQLException ignored) {}

        return item;
    }

    // ══════════════════════════════════════════════════════════
    // PRIVATE - General helpers
    // ══════════════════════════════════════════════════════════

    private void setNullableString(PreparedStatement ps, int idx, String value)
            throws SQLException {
        if (value != null && !value.trim().isEmpty()) {
            ps.setString(idx, value.trim());
        } else {
            ps.setNull(idx, Types.VARCHAR);
        }
    }

    private List<Timestamp> buildDateParams(LocalDate from, LocalDate to) {
        List<Timestamp> params = new ArrayList<>();
        if (from != null && to != null) {
            params.add(Timestamp.valueOf(from.atStartOfDay()));
            params.add(Timestamp.valueOf(to.plusDays(1).atStartOfDay()));
        }
        return params;
    }

    private int setDateParams(PreparedStatement ps, List<Timestamp> params)
            throws SQLException {
        for (int i = 0; i < params.size(); i++) {
            ps.setTimestamp(i + 1, params.get(i));
        }
        return params.size() + 1;
    }
}