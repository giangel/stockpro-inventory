package com.inventory.servlet;

import com.inventory.dao.ProductDAO;
import com.inventory.model.Product;
import com.inventory.util.DatabaseUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/reports")
public class ReportServlet extends HttpServlet {

    private final ProductDAO productDAO = new ProductDAO();
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ISO_LOCAL_DATE;
    private static final String COMPLETED = "COMPLETED";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        resp.setHeader("Pragma", "no-cache");
        resp.setDateHeader("Expires", 0);

        LocalDate today = LocalDate.now();
        LocalDate from  = parseDateParam(req.getParameter("from"), today.minusDays(29));
        LocalDate to    = parseDateParam(req.getParameter("to"), today);

        if (from.isAfter(to)) {
            LocalDate tmp = from; from = to; to = tmp;
        }

        try {
            loadReportData(req, from, to);
            req.getRequestDispatcher("/reports.jsp").forward(req, resp);
        } catch (SQLException e) {
            e.printStackTrace();
            throw new ServletException("Database failure while building report", e);
        }
    }

    private LocalDate parseDateParam(String raw, LocalDate fallback) {
        if (raw == null || raw.trim().isEmpty()) return fallback;
        try { return LocalDate.parse(raw.trim(), DATE_FMT); }
        catch (Exception e) { return fallback; }
    }

    private void loadReportData(HttpServletRequest req, LocalDate from, LocalDate to)
            throws SQLException {

        Timestamp fromTs = Timestamp.valueOf(from.atStartOfDay());
        Timestamp toTs   = Timestamp.valueOf(to.plusDays(1).atStartOfDay());

        req.setAttribute("salesSummary",     getSalesSummary(fromTs, toTs));
        req.setAttribute("topProducts",      getTopSellingProducts(10, fromTs, toTs));
        req.setAttribute("dailyTrend",       getDailyRevenueTrend(fromTs, toTs));
        req.setAttribute("paymentBreakdown", getRevenueByPaymentMethod(fromTs, toTs));

        BigDecimal inventoryValue = productDAO.getTotalInventoryValue();
        req.setAttribute("inventoryValue", inventoryValue);

        List<Product> lowStockProducts = productDAO.getLowStockProducts();
        req.setAttribute("lowStockProducts", lowStockProducts);
        req.setAttribute("lowStockCount", lowStockProducts != null ? lowStockProducts.size() : 0);

        req.setAttribute("fromDate", from.format(DATE_FMT));
        req.setAttribute("toDate", to.format(DATE_FMT));
        req.setAttribute("fromDateDisplay", from.format(DateTimeFormatter.ofPattern("dd MMM yyyy")));
        req.setAttribute("toDateDisplay", to.format(DateTimeFormatter.ofPattern("dd MMM yyyy")));
    }

    private Map<String, Object> getSalesSummary(Timestamp from, Timestamp to) throws SQLException {
        Map<String, Object> summary = new LinkedHashMap<>();
        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();

            ps = conn.prepareStatement(
                "SELECT COUNT(*) AS total_sales, COALESCE(SUM(total_amount), 0) AS total_revenue " +
                "FROM sales WHERE status = ? AND sale_date >= ? AND sale_date < ?");
            ps.setString(1, COMPLETED);
            ps.setTimestamp(2, from);
            ps.setTimestamp(3, to);
            rs = ps.executeQuery();

            int totalSales = 0;
            BigDecimal totalRevenue = BigDecimal.ZERO;
            if (rs.next()) {
                totalSales = rs.getInt("total_sales");
                totalRevenue = rs.getBigDecimal("total_revenue");
            }
            DatabaseUtil.close(rs, ps, null);

            ps = conn.prepareStatement(
                "SELECT COALESCE(SUM((si.unit_price - si.cost_price) * si.quantity), 0) AS total_profit, " +
                "       COALESCE(SUM(si.quantity), 0) AS items_sold " +
                "FROM sale_items si " +
                "JOIN sales s ON s.id = si.sale_id " +
                "WHERE s.status = ? AND s.sale_date >= ? AND s.sale_date < ?");
            ps.setString(1, COMPLETED);
            ps.setTimestamp(2, from);
            ps.setTimestamp(3, to);
            rs = ps.executeQuery();

            BigDecimal totalProfit = BigDecimal.ZERO;
            int itemsSold = 0;
            if (rs.next()) {
                totalProfit = rs.getBigDecimal("total_profit");
                itemsSold = rs.getInt("items_sold");
            }

            summary.put("totalSales", totalSales);
            summary.put("totalRevenue", totalRevenue);
            summary.put("totalProfit", totalProfit);
            summary.put("totalItemsSold", itemsSold);
            summary.put("avgOrderValue",
                totalSales > 0
                    ? totalRevenue.divide(BigDecimal.valueOf(totalSales), 2, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO);
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
        return summary;
    }

    private List<Map<String, Object>> getTopSellingProducts(int limit, Timestamp from, Timestamp to)
            throws SQLException {
        List<Map<String, Object>> rows = new ArrayList<>();
        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT si.product_id, si.product_name, " +
                "       SUM(si.quantity) AS total_qty, " +
                "       SUM(si.subtotal) AS total_revenue, " +
                "       SUM((si.unit_price - si.cost_price) * si.quantity) AS total_profit " +
                "FROM sale_items si " +
                "JOIN sales s ON s.id = si.sale_id " +
                "WHERE s.status = ? AND s.sale_date >= ? AND s.sale_date < ? " +
                "GROUP BY si.product_id, si.product_name " +
                "ORDER BY total_qty DESC " +
                "LIMIT ?");
            ps.setString(1, COMPLETED);
            ps.setTimestamp(2, from);
            ps.setTimestamp(3, to);
            ps.setInt(4, limit);
            rs = ps.executeQuery();

            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("productId", rs.getInt("product_id"));
                row.put("productName", rs.getString("product_name"));
                row.put("totalQty", rs.getInt("total_qty"));
                row.put("totalRevenue", rs.getBigDecimal("total_revenue"));
                row.put("totalProfit", rs.getBigDecimal("total_profit"));
                rows.add(row);
            }
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
        return rows;
    }

    private List<Map<String, Object>> getDailyRevenueTrend(Timestamp from, Timestamp to)
            throws SQLException {
        Map<String, Map<String, Object>> byDay = new LinkedHashMap<>();
        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();

            ps = conn.prepareStatement(
                "SELECT DATE(sale_date) AS sale_day, COUNT(*) AS sales_count, " +
                "       SUM(total_amount) AS revenue " +
                "FROM sales " +
                "WHERE status = ? AND sale_date >= ? AND sale_date < ? " +
                "GROUP BY DATE(sale_date) " +
                "ORDER BY sale_day ASC");
            ps.setString(1, COMPLETED);
            ps.setTimestamp(2, from);
            ps.setTimestamp(3, to);
            rs = ps.executeQuery();

            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                String day = rs.getDate("sale_day").toString();
                row.put("date", day);
                row.put("salesCount", rs.getInt("sales_count"));
                row.put("revenue", rs.getBigDecimal("revenue"));
                row.put("profit", BigDecimal.ZERO);
                byDay.put(day, row);
            }
            DatabaseUtil.close(rs, ps, null);

            ps = conn.prepareStatement(
                "SELECT DATE(s.sale_date) AS sale_day, " +
                "       COALESCE(SUM((si.unit_price - si.cost_price) * si.quantity), 0) AS profit " +
                "FROM sales s " +
                "JOIN sale_items si ON si.sale_id = s.id " +
                "WHERE s.status = ? AND s.sale_date >= ? AND s.sale_date < ? " +
                "GROUP BY DATE(s.sale_date)");
            ps.setString(1, COMPLETED);
            ps.setTimestamp(2, from);
            ps.setTimestamp(3, to);
            rs = ps.executeQuery();

            while (rs.next()) {
                String day = rs.getDate("sale_day").toString();
                Map<String, Object> row = byDay.get(day);
                if (row != null) row.put("profit", rs.getBigDecimal("profit"));
            }
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
        return new ArrayList<>(byDay.values());
    }

    private List<Map<String, Object>> getRevenueByPaymentMethod(Timestamp from, Timestamp to)
            throws SQLException {
        List<Map<String, Object>> rows = new ArrayList<>();
        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT payment_method, COUNT(*) AS sales_count, SUM(total_amount) AS revenue " +
                "FROM sales " +
                "WHERE status = ? AND sale_date >= ? AND sale_date < ? " +
                "GROUP BY payment_method " +
                "ORDER BY revenue DESC");
            ps.setString(1, COMPLETED);
            ps.setTimestamp(2, from);
            ps.setTimestamp(3, to);
            rs = ps.executeQuery();

            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("paymentMethod", rs.getString("payment_method"));
                row.put("salesCount", rs.getInt("sales_count"));
                row.put("revenue", rs.getBigDecimal("revenue"));
                rows.add(row);
            }
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
        return rows;
    }
}