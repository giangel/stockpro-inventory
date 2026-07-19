package com.inventory.servlet;

import com.inventory.dao.InventoryDAO;
import com.inventory.dao.ProductDAO;
import com.inventory.model.InventoryTransaction;
import com.inventory.model.Product;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;

/**
 * ============================================================
 *  InventoryServlet - Controller (C in MVC)
 * ============================================================
 *
 *  PURPOSE:
 *    Handles all stock movement requests - Stock In, Stock Out,
 *    Adjustments, Damage write-offs, Returns, and the full
 *    transaction history page.
 *
 *  URL MAPPING:
 *    All requests to /inventory go through this servlet.
 *
 *  ACTION ROUTING TABLE:
 *    GET  ?action=list          -> showHistory()     -> inventory.jsp
 *    GET  ?action=stockin       -> showStockInForm()  -> inventory.jsp (modal open)
 *    GET  ?action=stockout      -> showStockOutForm() -> inventory.jsp (modal open)
 *    GET  ?action=adjust        -> showAdjustForm()   -> inventory.jsp (modal open)
 *    GET  ?action=lowstock      -> showLowStock()     -> inventory.jsp (filtered)
 *    POST ?action=record        -> handleRecord()     -> redirect with result
 *
 *  SESSION USAGE:
 *    The logged-in user's ID is read from session (userId) so we
 *    know WHO performed each stock transaction. This is crucial for
 *    the audit trail (performed_by column in inventory_transactions).
 *
 *  web.xml entry (add below CategoryServlet mapping):
 *  ─────────────────────────────────────────────────────────────
 *  <servlet>
 *      <servlet-name>InventoryServlet</servlet-name>
 *      <servlet-class>com.inventory.servlet.InventoryServlet</servlet-class>
 *  </servlet>
 *  <servlet-mapping>
 *      <servlet-name>InventoryServlet</servlet-name>
 *      <url-pattern>/inventory</url-pattern>
 *  </servlet-mapping>
 *  ─────────────────────────────────────────────────────────────
 *
 *  LOCATION: src/com/inventory/servlet/InventoryServlet.java
 * ============================================================
 */
@WebServlet("/inventory")
public class InventoryServlet extends HttpServlet {

    private final InventoryDAO inventoryDAO = new InventoryDAO();
    private final ProductDAO   productDAO   = new ProductDAO();

    // ══════════════════════════════════════════════════════════════
    //  doGet()
    // ══════════════════════════════════════════════════════════════
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null) action = "list";

        try {
            switch (action) {
                case "stockin":  showTransactionForm(req, resp, "STOCK_IN");  break;
                case "stockout": showTransactionForm(req, resp, "STOCK_OUT"); break;
                case "damage":   showTransactionForm(req, resp, "DAMAGE");    break;
                case "adjust":   showTransactionForm(req, resp, "ADJUSTMENT");break;
                case "return":   showTransactionForm(req, resp, "RETURN");    break;
                case "lowstock": showLowStock(req, resp);                     break;
                default:         showHistory(req, resp);
            }
        } catch (SQLException e) {
            e.printStackTrace();
            throw new ServletException("Database error: " + e.getMessage(), e);
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  doPost()
    // ══════════════════════════════════════════════════════════════
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        try {
            handleRecord(req, resp);
        } catch (SQLException e) {
            e.printStackTrace();
            throw new ServletException("Database error: " + e.getMessage(), e);
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  PRIVATE HANDLER METHODS
    // ══════════════════════════════════════════════════════════════

    /**
     * showHistory()
     * -------------
     * Loads the full transaction log and sends it to inventory.jsp.
     * Also loads summary KPIs (total in, total out, today's count).
     *
     * The JSP uses ${transactions}, ${totalIn}, ${totalOut}, ${todayCount}.
     */
    private void showHistory(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException, SQLException {

        // Load last 500 transactions (enough for all practical purposes;
        // for large stores, implement pagination later)
        List<InventoryTransaction> transactions =
            inventoryDAO.getAllTransactions(500);

        // Summary KPIs for the top stat cards
        int totalIn       = inventoryDAO.getTotalStockIn();
        int totalOut      = inventoryDAO.getTotalStockOut();
        int todayCount    = inventoryDAO.getTodayTransactionCount();
        int lowStockCount = inventoryDAO.getLowStockCount();
        int monthlyIn     = inventoryDAO.getStockInThisMonth();

        req.setAttribute("transactions",  transactions);
        req.setAttribute("totalIn",       totalIn);
        req.setAttribute("totalOut",      totalOut);
        req.setAttribute("todayCount",    todayCount);
        req.setAttribute("lowStockCount", lowStockCount);
        req.setAttribute("monthlyIn",     monthlyIn);

        // Pass through success / error flash messages from redirects
        String success = req.getParameter("success");
        String error   = req.getParameter("error");
        if (success != null) req.setAttribute("successMessage", success);
        if (error   != null) req.setAttribute("errorMessage",   error);

        req.getRequestDispatcher("/inventory.jsp").forward(req, resp);
    }

    /**
     * showTransactionForm()
     * ---------------------
     * Opens inventory.jsp with the Stock In/Out/Damage/Adjust modal
     * pre-opened. The JSP checks ${formMode} to know which modal to show.
     *
     * Also pre-selects a specific product if ?productId= is in the URL.
     * This lets the "Stock In" button on the products page link directly
     * to this form with that product pre-selected - great UX.
     *
     * @param transactionType  "STOCK_IN", "STOCK_OUT", "DAMAGE", "ADJUSTMENT", or "RETURN"
     */
    private void showTransactionForm(HttpServletRequest req, HttpServletResponse resp,
                                      String transactionType)
            throws ServletException, IOException, SQLException {

        // Load products for the dropdown in the form
        List<Product> products = productDAO.getAllProducts();

        // If a specific product was pre-selected (from products page button)
        int preSelectedProductId = parseId(req.getParameter("productId"));
        Product preSelectedProduct = null;
        if (preSelectedProductId > 0) {
            preSelectedProduct = productDAO.getProductById(preSelectedProductId);
        }

        // Also load history so the table renders behind the modal
        List<InventoryTransaction> transactions =
            inventoryDAO.getAllTransactions(100);

        req.setAttribute("products",             products);
        req.setAttribute("preSelectedProduct",   preSelectedProduct);
        req.setAttribute("preSelectedProductId", preSelectedProductId);
        req.setAttribute("transactions",         transactions);
        req.setAttribute("formMode",             transactionType);

        // KPIs for the stat cards (still needed for the page header)
        req.setAttribute("totalIn",       inventoryDAO.getTotalStockIn());
        req.setAttribute("totalOut",      inventoryDAO.getTotalStockOut());
        req.setAttribute("todayCount",    inventoryDAO.getTodayTransactionCount());
        req.setAttribute("lowStockCount", inventoryDAO.getLowStockCount());
        req.setAttribute("monthlyIn",     inventoryDAO.getStockInThisMonth());

        req.getRequestDispatcher("/inventory.jsp").forward(req, resp);
    }

    /**
     * showLowStock()
     * --------------
     * Loads inventory.jsp filtered to only show products at/below
     * their reorder level. Linked from the dashboard alerts panel.
     */
    private void showLowStock(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException, SQLException {

        List<Product> lowStockProducts = productDAO.getLowStockProducts();

        req.setAttribute("lowStockProducts", lowStockProducts);
        req.setAttribute("viewMode",         "lowstock");
        req.setAttribute("lowStockCount",    lowStockProducts.size());

        // Still load history so the page isn't broken
        req.setAttribute("transactions",  inventoryDAO.getAllTransactions(50));
        req.setAttribute("totalIn",       inventoryDAO.getTotalStockIn());
        req.setAttribute("totalOut",      inventoryDAO.getTotalStockOut());
        req.setAttribute("todayCount",    inventoryDAO.getTodayTransactionCount());
        req.setAttribute("monthlyIn",     inventoryDAO.getStockInThisMonth());

        req.getRequestDispatcher("/inventory.jsp").forward(req, resp);
    }

    /**
     * handleRecord()
     * --------------
     * Processes the Stock In / Out / Damage / Adjustment form submission.
     *
     * VALIDATION:
     *  1. Product must be selected
     *  2. Quantity must be > 0
     *  3. For STOCK_OUT and DAMAGE: quantity must not exceed current stock
     *     (InventoryDAO.recordTransaction() also enforces this, but we
     *      check here first for a better error message)
     *
     * ON SUCCESS:
     *   Redirect to /inventory?action=list&success=recorded
     *   with a message showing what happened (e.g. "+50 bags added")
     *
     * ON FAILURE:
     *   Redirect back with an error message.
     */
    private void handleRecord(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException, SQLException {

        // ── Read form fields ──────────────────────────────────────
        int    productId       = parseId(req.getParameter("productId"));
        String transactionType = clean(req.getParameter("transactionType"));
        int    quantity        = parseId(req.getParameter("quantity"));
        String referenceNote   = clean(req.getParameter("referenceNote"));
        String unitCostStr     = clean(req.getParameter("unitCost"));

        // For ADJUSTMENT, the user picks +/- with a separate dropdown
        String adjustDirection = clean(req.getParameter("adjustDirection"));

        // ── Read the logged-in user's ID from session ─────────────
        // This is crucial for the audit trail - we MUST know who did this.
        HttpSession session = req.getSession(false);
        int performedBy = 0;
        if (session != null && session.getAttribute("userId") != null) {
            performedBy = (Integer) session.getAttribute("userId");
        }

        // Fallback: if userId is not in session, try loggedInUser object
        if (performedBy == 0 && session != null
                && session.getAttribute("loggedInUser") != null) {
            com.inventory.model.User user =
                (com.inventory.model.User) session.getAttribute("loggedInUser");
            performedBy = user.getId();
        }

        // ── Client-side-equivalent server validation ──────────────
        if (productId <= 0) {
            redirect(resp, req, "error=noproduct");
            return;
        }
        if (quantity <= 0) {
            redirect(resp, req, "error=invalidqty");
            return;
        }
        if (transactionType == null || transactionType.isEmpty()) {
            redirect(resp, req, "error=notype");
            return;
        }

        // For adjustments, apply the direction sign to quantity
        if ("ADJUSTMENT".equals(transactionType) && "minus".equals(adjustDirection)) {
            quantity = -quantity; // negative means we remove stock
        }

        // ── Build the transaction object ──────────────────────────
        InventoryTransaction tx = new InventoryTransaction();
        tx.setProductId(productId);
        tx.setTransactionType(transactionType);
        tx.setQuantity(quantity);
        tx.setReferenceNote(referenceNote.isEmpty() ? null : referenceNote);
        tx.setPerformedBy(performedBy);

        // Parse unit cost if provided (optional, for stock-in receipts)
        if (!unitCostStr.isEmpty()) {
            try {
                tx.setUnitCost(new BigDecimal(unitCostStr));
            } catch (NumberFormatException e) {
                // Invalid number - ignore, treat as no cost
            }
        }

        // ── Record the transaction (atomic: insert + update stock) ─
        try {
            inventoryDAO.recordTransaction(tx);

            // Build a descriptive success message for the UI toast
            // e.g. "Stock In recorded: +50 units added. Stock now: 95"
            String typeLabel = tx.getTypeLabel();
            String sign      = tx.isStockIncreasing() ? "+" : "-";
            String msg       = typeLabel + " recorded: " + sign
                             + Math.abs(tx.getQuantity())
                             + " units. Stock now: " + tx.getStockAfter();

            // URL-encode the message (spaces -> %20 etc.) so it survives the redirect
            String encodedMsg = java.net.URLEncoder.encode(msg, "UTF-8");
            resp.sendRedirect(req.getContextPath()
                + "/inventory?action=list&success=" + encodedMsg);

        } catch (IllegalStateException e) {
            // This happens when stock would go negative
            // e.g. "Insufficient stock. Current: 5, Attempted: 20"
            String encodedErr = java.net.URLEncoder.encode(e.getMessage(), "UTF-8");
            resp.sendRedirect(req.getContextPath()
                + "/inventory?action=list&error=" + encodedErr);
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  PRIVATE UTILITIES
    // ══════════════════════════════════════════════════════════════

    /** Redirect helper */
    private void redirect(HttpServletResponse resp, HttpServletRequest req, String params)
            throws IOException {
        resp.sendRedirect(req.getContextPath() + "/inventory?action=list&" + params);
    }

    /** Safely parse integer from string - returns 0 on failure */
    private int parseId(String s) {
        if (s == null || s.trim().isEmpty()) return 0;
        try { return Integer.parseInt(s.trim()); }
        catch (NumberFormatException e) { return 0; }
    }

    /** Null-safe trim */
    private String clean(String s) {
        return s == null ? "" : s.trim();
    }
}
