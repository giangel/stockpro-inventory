package com.inventory.servlet;

import com.inventory.dao.InventoryDAO;
import com.inventory.dao.ProductDAO;
import com.inventory.dao.SaleDAO;
import com.inventory.dao.CategoryDAO;
import com.inventory.model.Product;
import com.inventory.model.InventoryTransaction;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * ============================================================
 * DashboardServlet - Controller with Integrated Debug Logs
 * ============================================================
 */
@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {

    private final ProductDAO     productDAO     = new ProductDAO();
    private final InventoryDAO   inventoryDAO   = new InventoryDAO();
    private final SaleDAO        saleDAO        = new SaleDAO();
    private final CategoryDAO    categoryDAO    = new CategoryDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        System.out.println("\n[DASHBOARD DEBUG] doGet() initiated. Client requested /dashboard");
        resp.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        resp.setHeader("Pragma", "no-cache"); 
        resp.setDateHeader("Expires", 0);
        // ------------------------------------

        
        try {
            loadDashboardData(req);
            System.out.println("[DASHBOARD DEBUG] loadDashboardData completed successfully without SQLExceptions!");
         // Only forward if loading was successful
            req.getRequestDispatcher("/dashboard.jsp").forward(req, resp);
        
        } catch (SQLException e) {
        	// If an error occurs, log it and show a 500 page
            e.printStackTrace();
            throw new ServletException("Database failure", e);
        }
        	
        }

    // ── Main data loader with Console Print diagnostics ─────────

    private void loadDashboardData(HttpServletRequest req) throws SQLException {

        System.out.println("====== START DATABASE READ DIAGNOSTICS ======");

        // ── 1. PRODUCT KPIs ──────────────────────────────────────
        int totalProducts   = productDAO.getTotalProductCount();
        System.out.println("-> Total Active Products count in DB: " + totalProducts);

        List<Product> allProducts = productDAO.getAllProducts();
        System.out.println("-> Product List loaded. Total size: " + (allProducts != null ? allProducts.size() : "null"));

        // Count low-stock and out-of-stock from the live product list
        int lowStockCount   = 0;
        int outOfStockCount = 0;
        if (allProducts != null) {
            for (Product p : allProducts) {
                if (p.getCurrentStock() == 0) {
                    outOfStockCount++;
                    lowStockCount++; // out-of-stock is also low-stock
                } else if (p.getCurrentStock() <= p.getReorderLevel()) {
                    lowStockCount++;
                }
            }
        }
        System.out.println("-> Computed Out-Of-Stock: " + outOfStockCount + " | Low Stock: " + lowStockCount);

        BigDecimal inventoryValue = productDAO.getTotalInventoryValue();
        System.out.println("-> Total Inventory Valuation: ₦" + (inventoryValue != null ? inventoryValue.toPlainString() : "0.00"));

        // Top 7 low-stock products for the alert panel
        List<Product> lowStockProducts = productDAO.getLowStockProducts();
        System.out.println("-> Low Stock Warnings from DB: " + (lowStockProducts != null ? lowStockProducts.size() : "0") + " items");
        
        // Trim to 7 for the dashboard panel
        if (lowStockProducts != null && lowStockProducts.size() > 7) {
            lowStockProducts = lowStockProducts.subList(0, 7);
        }

        req.setAttribute("totalProducts",   totalProducts);
        req.setAttribute("lowStockCount",   lowStockCount);
        req.setAttribute("outOfStockCount", outOfStockCount);
        req.setAttribute("inventoryValue",  inventoryValue);
        req.setAttribute("lowStockProducts",lowStockProducts);
        req.setAttribute("products",        allProducts);

        // ── 2. CATEGORY & SUPPLIER COUNTS ───────────────────────
        try {
            int totalCategories = categoryDAO.getTotalCategoryCount();
            System.out.println("-> Total Categories in DB: " + totalCategories);
            req.setAttribute("totalCategories", totalCategories);
        } catch (Exception e) {
            System.err.println("-> Category extraction failed: " + e.getMessage());
            req.setAttribute("totalCategories", 0);
        }

        // ── 3. SALES KPIs (today) ────────────────────────────────
        try {
            Map<String, Object> todaySummary = saleDAO.getTodaySummary();
            BigDecimal grossRevenueToday =
                (BigDecimal) todaySummary.getOrDefault("totalRevenue", BigDecimal.ZERO);
            int salesToday =
                (int) todaySummary.getOrDefault("totalSales", 0);

            System.out.println("-> Sales Today Count: " + salesToday + " | Revenue: ₦" + grossRevenueToday);
            req.setAttribute("grossRevenueToday", grossRevenueToday);
            req.setAttribute("salesToday",        salesToday);
        } catch (Exception e) {
            System.err.println("-> Sales Summary extraction failed: " + e.getMessage());
            req.setAttribute("grossRevenueToday", BigDecimal.ZERO);
            req.setAttribute("salesToday",        0);
        }

        // ── 4. WEEKLY CHART DATA ─────────────────────────────────
        try {
            LocalDate today    = LocalDate.now();
            LocalDate weekStart = today.minusDays(6); // rolling 7-day window

            List<Map<String, Object>> weeklyTrend =
                saleDAO.getDailyRevenueTrend(weekStart, today);

            BigDecimal[] revenueByDay    = new BigDecimal[7];
            int[]        itemsSoldByDay  = new int[7];
            String[]     dayLabels       = new String[7];

            java.time.format.DateTimeFormatter dayFmt =
                java.time.format.DateTimeFormatter.ofPattern("EEE");
            java.time.format.DateTimeFormatter dateFmt =
                java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd");

            for (int i = 0; i < 7; i++) {
                LocalDate day = weekStart.plusDays(i);
                dayLabels[i]    = day.format(dayFmt);
                revenueByDay[i] = BigDecimal.ZERO;
                itemsSoldByDay[i] = 0;

                String dayStr = day.format(dateFmt);
                if (weeklyTrend != null) {
                    for (Map<String, Object> row : weeklyTrend) {
                        if (dayStr.equals(row.get("date"))) {
                            revenueByDay[i]   = (BigDecimal) row.getOrDefault("revenue", BigDecimal.ZERO);
                            itemsSoldByDay[i] = (int) row.getOrDefault("salesCount", 0);
                            break;
                        }
                    }
                }
            }

            BigDecimal thisWeekRevenue = BigDecimal.ZERO;
            int weeklyItemsTotal = 0;
            for (int i = 0; i < 7; i++) {
                if (revenueByDay[i] != null)
                    thisWeekRevenue = thisWeekRevenue.add(revenueByDay[i]);
                weeklyItemsTotal += itemsSoldByDay[i];
            }

            List<Map<String, Object>> lastWeekTrend =
                saleDAO.getDailyRevenueTrend(weekStart.minusDays(7), today.minusDays(7));
            BigDecimal lastWeekRevenue = BigDecimal.ZERO;
            if (lastWeekTrend != null) {
                for (Map<String, Object> row : lastWeekTrend) {
                    BigDecimal r = (BigDecimal) row.get("revenue");
                    if (r != null) lastWeekRevenue = lastWeekRevenue.add(r);
                }
            }

            System.out.println("-> Chart dataset compiled successfully. Weekly Items sold: " + weeklyItemsTotal);
            req.setAttribute("dayLabels",          dayLabels);
            req.setAttribute("revenueByDay",       revenueByDay);
            req.setAttribute("itemsSoldByDay",     itemsSoldByDay);
            req.setAttribute("thisWeekRevenue",    thisWeekRevenue);
            req.setAttribute("lastWeekRevenue",    lastWeekRevenue);
            req.setAttribute("weeklyItemsSoldTotal", weeklyItemsTotal);

        } catch (Exception e) {
            System.err.println("-> Weekly Trend compilation failed: " + e.getMessage());
            req.setAttribute("dayLabels",    new String[]{"Mon","Tue","Wed","Thu","Fri","Sat","Sun"});
            req.setAttribute("revenueByDay", new BigDecimal[]{BigDecimal.ZERO,BigDecimal.ZERO,
                BigDecimal.ZERO,BigDecimal.ZERO,BigDecimal.ZERO,BigDecimal.ZERO,BigDecimal.ZERO});
            req.setAttribute("itemsSoldByDay", new int[]{0,0,0,0,0,0,0});
            req.setAttribute("thisWeekRevenue",  BigDecimal.ZERO);
            req.setAttribute("lastWeekRevenue",  BigDecimal.ZERO);
            req.setAttribute("weeklyItemsSoldTotal", 0);
        }

        // ── 5. RECENT INVENTORY TRANSACTIONS ────────────────────
        try {
            List<InventoryTransaction> recentTx = inventoryDAO.getRecentTransactions(8);
            System.out.println("-> Recent Transactions loaded: " + (recentTx != null ? recentTx.size() : "0") + " events");
            req.setAttribute("recentTransactions", recentTx);
        } catch (Exception e) {
            System.err.println("-> Recent Transactions retrieval failed: " + e.getMessage());
            req.setAttribute("recentTransactions", new java.util.ArrayList<>());
        }

        // ── 6. TODAY'S DATE ──────────────────────────────────────
        java.time.format.DateTimeFormatter headingFmt =
            java.time.format.DateTimeFormatter.ofPattern("EEEE, dd MMM yyyy");
        req.setAttribute("todayFormatted",
            java.time.LocalDate.now().format(headingFmt));

        System.out.println("====== END DATABASE READ DIAGNOSTICS ======");
    }
}