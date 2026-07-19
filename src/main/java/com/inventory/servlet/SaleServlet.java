package com.inventory.servlet;

import com.inventory.dao.ProductDAO;
import com.inventory.dao.SaleDAO;
import com.inventory.model.Product;
import com.inventory.model.Sale;
import com.inventory.model.SaleItem;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * SaleServlet
 * ─────────────────────────────────────────────────────────────────
 * Single servlet that handles EVERY sales-related action, routed
 * by the "action" query parameter - consistent with CategoryServlet
 * and SupplierServlet in this codebase.
 *
 * URL map (all under /sales):
 * ┌─────────────────────────────────────┬────────────────────────────────────────────┐
 * │ GET  /sales?action=pos              │ Show the Point-of-Sale (POS) screen        │
 * │ POST /sales?action=checkout         │ Process cart -> save sale -> show receipt    │
 * │ GET  /sales?action=receipt&id=N     │ View/reprint a saved receipt               │
 * │ GET  /sales?action=history          │ Sales history list (with filters)           │
 * │ GET  /sales?action=void&id=N        │ Void a COMPLETED sale (with confirmation)  │
 * │ POST /sales?action=void&id=N        │ Execute the void (after confirmation)      │
 * │ GET  /sales?action=refund&id=N      │ Refund a COMPLETED sale (with confirmation)│
 * │ POST /sales?action=refund&id=N      │ Execute the refund (after confirmation)    │
 * │ GET  /sales?action=lookup           │ Search receipt by receipt number            │
 * └─────────────────────────────────────┴────────────────────────────────────────────┘
 *
 * Cart session key: "posCart" -> List<SaleItem>
 *   The cart lives in the HTTP session between POS page loads so that
 *   the cashier can add multiple items before checking out. It is
 *   cleared from the session immediately after a successful checkout.
 *
 * Flow for a POS sale:
 *   1. GET  /sales?action=pos        -> showPOS()       loads products
 *   2. POST /sales?action=addToCart  -> addToCart()     appends to session cart
 *   3. POST /sales?action=removeFromCart -> removeFromCart() removes one line
 *   4. POST /sales?action=checkout   -> processCheckout() saves to DB, clears cart
 *   5. GET  /sales?action=receipt&id=N -> showReceipt() loads full sale + items
 *
 * Web.xml registration (if not using @WebServlet):
 *   <servlet>
 *       <servlet-name>SaleServlet</servlet-name>
 *       <servlet-class>com.inventory.servlet.SaleServlet</servlet-class>
 *   </servlet>
 *   <servlet-mapping>
 *       <servlet-name>SaleServlet</servlet-name>
 *       <url-pattern>/sales</url-pattern>
 *   </servlet-mapping>
 */
@WebServlet("/sales")
public class SaleServlet extends HttpServlet {

    // ── Session key for the in-progress cart ──────────────────
    private static final String SESSION_CART = "posCart";

    // ── Date format used for filter params from the JSP forms ─
    private static final DateTimeFormatter DATE_FMT =
            DateTimeFormatter.ofPattern("yyyy-MM-dd");

    // ── DAO instances (stateless, safe to share) ──────────────
    private final SaleDAO    saleDAO    = new SaleDAO();
    private final ProductDAO productDAO = new ProductDAO();

    // ═══════════════════════════════════════════════════════════════════
    //  GET dispatcher
    // ═══════════════════════════════════════════════════════════════════

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "history"; // Points to history view by default

        try {
            switch (action) {
                case "history":
                case "list":
                    showHistory(req, resp); // Maps to your actual method below
                    break;
                case "pos":
                    // Loads live products and forwards to the POS interface
                    showPOS(req, resp);
                    break;
                case "view":
                case "receipt":
                    showReceipt(req, resp); // Both view and receipt use showReceipt
                    break;
                case "void":
                    showVoidConfirm(req, resp);
                    break;
                case "refund":
                    showRefundConfirm(req, resp);
                    break;
                case "lookup":
                    lookupReceipt(req, resp);
                    break;
                default:
                    showHistory(req, resp);
            }
        } catch (SQLException e) {
            handleDbError(req, resp, e, "/WEB-INF/views/sales-history.jsp");
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //  POST dispatcher
    // ═══════════════════════════════════════════════════════════════════

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null) action = "pos";

        try {
            switch (action) {
                case "addToCart":      addToCart(req, resp);      break;
                case "removeFromCart": removeFromCart(req, resp);  break;
                case "updateCart":     updateCartQty(req, resp);   break;
                case "clearCart":      clearCart(req, resp);       break;
                case "checkout":       processCheckout(req, resp); break;
                case "void":           executeVoid(req, resp);     break;
                case "refund":         executeRefund(req, resp);   break;
                
                default:               showPOS(req, resp);
            }
        } catch (SQLException e) {
            handleDbError(req, resp, e, "/sales.jsp");
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //  GET HANDLERS
    // ═══════════════════════════════════════════════════════════════════

    /**
     * SHOW POS SCREEN
     * ─────────────────────────────────────────────────────────────
     * Loads the active product list and the current session cart,
     * then forwards to sales.jsp (the POS terminal page).
     *
     * Request attributes set:
     *   products   -> List<Product>  all active products (for the product grid)
     *   cart       -> List<SaleItem> current session cart
     *   cartTotal  -> BigDecimal     running total of all line totals in cart
     */
    private void showPOS(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        // Load all active, in-stock products for the product picker grid.
        // ProductDAO.getAllProducts() returns only is_active = true rows.
        List<Product> products = productDAO.getAllProducts();
        req.setAttribute("products", products);

        // Attach the current cart (may be empty list if nothing added yet)
        List<SaleItem> cart = getOrCreateCart(req.getSession());
        req.setAttribute("cart",      cart);
        req.setAttribute("cartTotal", sumCartTotal(cart));
        
        //Tells sales.jsp to display the POS block layout instead of the table!
        req.setAttribute("action", "pos");
        req.getRequestDispatcher("/sales.jsp").forward(req, resp);
    }

    /**
     * SHOW RECEIPT
     * ─────────────────────────────────────────────────────────────
     * Loads a completed sale by id (with all its line items) and
     * forwards to the receipt JSP for display or printing.
     *
     * GET /sales?action=receipt&id=42
     *
     * Request attributes set:
     *   sale       -> Sale (with items list populated)
     */
    private void showReceipt(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        int id = parseId(req.getParameter("id"));
        Sale sale = saleDAO.getSaleById(id);

        if (sale == null) {
            req.setAttribute("errorMessage", "Receipt not found. It may have been deleted.");
            req.getRequestDispatcher("/sales-history.jsp").forward(req, resp);
            return;
        }

        req.setAttribute("sale", sale);
        req.getRequestDispatcher("/sale-receipt.jsp").forward(req, resp);
    }

    /**
     * SHOW SALES HISTORY
     * ─────────────────────────────────────────────────────────────
     * Loads a filterable list of all sales, newest first.
     *
     * GET /sales?action=history
     * GET /sales?action=history&from=2025-01-01&to=2025-06-30
     *                          &status=COMPLETED&paymentMethod=CASH
     *
     * Request attributes set:
     *   sales          -> List<Sale>  (items NOT loaded - just headers)
     *   filterFrom     -> String      echoed back for the date input
     *   filterTo       -> String
     *   filterStatus   -> String
     *   filterPayment  -> String
     *   summary        -> Map<String,Object> today's KPI totals for the stat strip
     *   successMessage -> String (flash from void/refund redirect)
     *   errorMessage   -> String (flash from void/refund failure)
     */
    private void showHistory(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        // ── Read optional filter parameters ──────────────────────
        String fromStr  = req.getParameter("from");
        String toStr    = req.getParameter("to");
        String status   = req.getParameter("status");
        String payment  = req.getParameter("paymentMethod");

        LocalDate from = parseDate(fromStr);
        LocalDate to   = parseDate(toStr);

        // ── Fetch filtered list ───────────────────────────────────
        List<Sale> sales = saleDAO.getFilteredSales(from, to, status, payment);
        req.setAttribute("sales",         sales);
        req.setAttribute("filterFrom",    fromStr  != null ? fromStr  : "");
        req.setAttribute("filterTo",      toStr    != null ? toStr    : "");
        req.setAttribute("filterStatus",  status   != null ? status   : "");
        req.setAttribute("filterPayment", payment  != null ? payment  : "");

        // ── Today's KPI summary for the stat strip ────────────────
        Map<String, Object> summary = saleDAO.getTodaySummary();
        req.setAttribute("summary", summary);

        // ── Flash messages from redirects ─────────────────────────
        attachFlashMessages(req,
            new String[]{"voided","refunded"},
            new String[]{"Sale voided successfully. Stock has been restored.",
                         "Sale refunded successfully. Stock has been restored."},
            new String[]{"alreadyvoid","notfound","dbError"},
            new String[]{"This sale is already voided or refunded.",
                         "Sale not found - it may have already been removed.",
                         "A database error occurred. Please try again."});

        req.getRequestDispatcher("/sales-history.jsp").forward(req, resp);
    }

    /**
     * SHOW VOID CONFIRMATION PAGE
     * ─────────────────────────────────────────────────────────────
     * Loads the sale and forwards to a confirmation page before voiding.
     * This protects against accidental GET-based voiding (e.g. link-sharing).
     *
     * GET /sales?action=void&id=42
     */
    private void showVoidConfirm(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        Sale sale = loadSaleOrRedirect(req, resp);
        if (sale == null) return; // already redirected

        if (sale.isTerminal()) {
            resp.sendRedirect(req.getContextPath()
                    + "/sales?action=history&error=alreadyvoid");
            return;
        }

        req.setAttribute("sale",          sale);
        req.setAttribute("confirmAction", "void");
        req.getRequestDispatcher("/sale-confirm.jsp").forward(req, resp);
    }

    /**
     * SHOW REFUND CONFIRMATION PAGE
     * ─────────────────────────────────────────────────────────────
     * Same as void confirm, but sets confirmAction="refund".
     *
     * GET /sales?action=refund&id=42
     */
    private void showRefundConfirm(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        Sale sale = loadSaleOrRedirect(req, resp);
        if (sale == null) return;

        if (sale.isTerminal()) {
            resp.sendRedirect(req.getContextPath()
                    + "/sales?action=history&error=alreadyvoid");
            return;
        }

        req.setAttribute("sale",          sale);
        req.setAttribute("confirmAction", "refund");
        req.getRequestDispatcher("/sale-confirm.jsp").forward(req, resp);
    }

    /**
     * RECEIPT LOOKUP
     * ─────────────────────────────────────────────────────────────
     * Searches for a sale by receipt number typed by the cashier.
     *
     * GET /sales?action=lookup&receiptNumber=RCP-20250612-0042
     *
     * If found -> redirects to the receipt page.
     * If not found -> returns to history page with an error flash.
     */
    private void lookupReceipt(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, IOException {

        String rn = req.getParameter("receiptNumber");

        if (rn == null || rn.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/sales?action=history");
            return;
        }

        Sale sale = saleDAO.getSaleByReceiptNumber(rn.trim());

        if (sale == null) {
            resp.sendRedirect(req.getContextPath()
                    + "/sales?action=history&error=notfound");
        } else {
            resp.sendRedirect(req.getContextPath()
                    + "/sales?action=receipt&id=" + sale.getId());
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //  POST HANDLERS - cart management
    // ═══════════════════════════════════════════════════════════════════

    /**
     * ADD TO CART
     * ─────────────────────────────────────────────────────────────
     * Adds one product to the session cart, or increments its quantity
     * if the product is already in the cart.
     *
     * POST /sales?action=addToCart
     * Form params: productId, quantity (default 1)
     *
     * Validations:
     *   - Product must exist and be active.
     *   - Requested quantity must be > 0.
     *   - Total cart quantity for this product must not exceed available stock.
     *
     * After adding -> redirect to GET /sales?action=pos (PRG pattern).
     */
    private void addToCart(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, IOException {

        int productId = parseId(req.getParameter("productId"));
        int qty       = parsePositiveInt(req.getParameter("quantity"), 1);

        // Load the product from the DB - validates existence and gets live stock
        Product product = productDAO.getProductById(productId);

        if (product == null || !product.isActive()) {
            resp.sendRedirect(req.getContextPath()
                    + "/sales?action=pos&cartError=Product+not+found+or+inactive.");
            return;
        }

        // Check how much of this product is already in the cart
        List<SaleItem> cart = getOrCreateCart(req.getSession());
        int alreadyInCart = cartQuantityFor(cart, productId);
        int totalWanted   = alreadyInCart + qty;

        if (totalWanted > product.getCurrentStock()) { 
            String msg = "Only+" + product.getCurrentStock() + "+unit(s)+of+%22" + encodeParam(product.getName()) + "%22+in+stock.";
            resp.sendRedirect(req.getContextPath() + "/sales?action=pos&cartError=" + msg);
            return;
        }

        // Either add a new line or increment existing line
        SaleItem existing = findCartItem(cart, productId);
        if (existing != null) {
            // Increase quantity and recalculate line total
            existing.setQuantity(existing.getQuantity() + qty);
            existing.recalculate();
        } else {
            // Build a new SaleItem with snapshot pricing
            SaleItem item = new SaleItem(
                    product.getId(),
                    product.getName(),
                    qty,
                    product.getSellingPrice(),   // unit_price snapshot
                    product.getCostPrice()        // cost_price snapshot
            );
            item.setProductSku(product.getSku());
            cart.add(item);
        }

        resp.sendRedirect(req.getContextPath() + "/sales?action=pos");
    }

    /**
     * REMOVE FROM CART
     * ─────────────────────────────────────────────────────────────
     * Removes an entire line from the cart by productId.
     *
     * POST /sales?action=removeFromCart
     * Form params: productId
     */
    private void removeFromCart(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        int productId = parseId(req.getParameter("productId"));
        List<SaleItem> cart = getOrCreateCart(req.getSession());
        cart.removeIf(item -> item.getProductId() == productId);

        resp.sendRedirect(req.getContextPath() + "/sales?action=pos");
    }

    /**
     * UPDATE CART QUANTITY
     * ─────────────────────────────────────────────────────────────
     * Changes the quantity of an existing cart line.
     * If the new quantity is 0 or less, the item is removed.
     * If the new quantity exceeds stock, the request is rejected.
     *
     * POST /sales?action=updateCart
     * Form params: productId, quantity
     */
    private void updateCartQty(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, IOException {

        int productId = parseId(req.getParameter("productId"));
        int newQty    = parsePositiveInt(req.getParameter("quantity"), 0);

        List<SaleItem> cart = getOrCreateCart(req.getSession());

        if (newQty <= 0) {
            // Treat quantity=0 as a delete
            cart.removeIf(item -> item.getProductId() == productId);
        } else {
            // Validate new qty against live stock
            Product product = productDAO.getProductById(productId);
            if (product != null && newQty > product.getCurrentStock()) {
                String msg = "Only+" + product.getCurrentStock() + "+in+stock.";
                resp.sendRedirect(req.getContextPath() + "/sales?action=pos&cartError=" + msg);
                return;
            }
            SaleItem item = findCartItem(cart, productId);
            if (item != null) {
                item.setQuantity(newQty);
                item.recalculate();
            }
        }

        resp.sendRedirect(req.getContextPath() + "/sales?action=pos");
    }

    /**
     * CLEAR CART
     * ─────────────────────────────────────────────────────────────
     * Removes all items from the session cart.
     *
     * POST /sales?action=clearCart
     */
    private void clearCart(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        getOrCreateCart(req.getSession()).clear();
        resp.sendRedirect(req.getContextPath() + "/sales?action=pos");
    }

    // ═══════════════════════════════════════════════════════════════════
    //  POST HANDLERS - checkout & status changes
    // ═══════════════════════════════════════════════════════════════════

    /**
     * PROCESS CHECKOUT
     * ─────────────────────────────────────────────────────────────
     * Validates the cart and payment info, saves the sale to the DB
     * atomically (sale + items + stock deduction), then redirects to
     * the receipt page.
     *
     * POST /sales?action=checkout
     * Form params:
     *   customerName    (optional)
     *   customerPhone   (optional)
     *   paymentMethod   CASH | TRANSFER | POS | CREDIT
     *   discountAmount  (optional, default 0)
     *   taxAmount       (optional, default 0)
     *   amountPaid      (required - must be >= grandTotal for CASH/POS)
     *   notes           (optional)
     *
     * Validation steps (in order):
     *   1. Cart must not be empty.
     *   2. Payment method must be one of the 4 allowed values.
     *   3. amountPaid must be a valid positive number.
     *   4. For CASH and POS: amountPaid must be >= grandTotal.
     *   5. Live stock check via SaleDAO.validateStock() before DB write.
     *
     * On failure -> return to POS page with errorMessage attribute.
     * On success -> redirect to receipt page (PRG pattern).
     */
    private void processCheckout(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        HttpSession session = req.getSession();
        List<SaleItem> cart = getOrCreateCart(session);

        // ── Guard: empty cart ────────────────────────────────────
        if (cart.isEmpty()) {
            req.setAttribute("errorMessage", "Cart is empty. Add at least one product before checking out.");
            showPOS(req, resp);
            return;
        }

        // ── Read payment fields ───────────────────────────────────
        String customerName  = req.getParameter("customerName");
        String customerPhone = req.getParameter("customerPhone");
        String paymentMethod = req.getParameter("paymentMethod");
        String discountStr   = req.getParameter("discountAmount");
        String taxStr        = req.getParameter("taxAmount");
        String amountPaidStr = req.getParameter("amountPaid");
        String notes         = req.getParameter("notes");

        // ── Validate payment method ───────────────────────────────
        if (!isValidPaymentMethod(paymentMethod)) {
            req.setAttribute("errorMessage", "Please select a valid payment method.");
            showPOS(req, resp);
            return;
        }

        // ── Parse numeric fields safely ───────────────────────────
        BigDecimal discount   = parseBigDecimal(discountStr,  BigDecimal.ZERO);
        BigDecimal tax        = parseBigDecimal(taxStr,        BigDecimal.ZERO);
        BigDecimal amountPaid = parseBigDecimal(amountPaidStr, null);

        if (amountPaid == null || amountPaid.compareTo(BigDecimal.ZERO) < 0) {
            req.setAttribute("errorMessage", "Please enter a valid amount paid.");
            showPOS(req, resp);
            return;
        }

        // ── Build Sale object from cart ───────────────────────────
        Sale sale = new Sale();
        sale.setCustomerName(customerName);
        sale.setCustomerPhone(customerPhone);
        sale.setPaymentMethod(paymentMethod);
        sale.setDiscountAmount(discount);
        sale.setTaxAmount(tax);
        sale.setAmountPaid(amountPaid);
        sale.setNotes(notes);
        sale.setItems(new ArrayList<>(cart)); // copy so we can clear the session cart safely

        // Cashier name comes from the session (set at login)
        String servedBy = (String) session.getAttribute("username");
        if (servedBy == null) servedBy = (String) session.getAttribute("userFullName");
        sale.setServedBy(servedBy);

        // Compute totals
        sale.recalculateSubtotal(); // builds subtotal from items
        sale.recalculate();          // computes grandTotal and changeGiven

        // ── Validate: amountPaid must cover grandTotal for cash/POS ──
        if ((Sale.PAYMENT_CASH.equals(paymentMethod) || Sale.PAYMENT_POS.equals(paymentMethod))
                && amountPaid.compareTo(sale.getTotalAmount()) < 0) {

            req.setAttribute("errorMessage",
                    "Amount paid (₦" + fmt(amountPaid) + ") is less than the grand total ("
                    + "₦" + fmt(sale.getTotalAmount()) + "). Please collect the full amount.");
            showPOS(req, resp);
            return;
        }

        // ── Pre-flight stock validation ───────────────────────────
        // Check every cart item against live DB stock before committing.
        // This gives the cashier clear, item-level error messages.
        List<String> stockErrors = saleDAO.validateStock(cart);
        if (!stockErrors.isEmpty()) {
            req.setAttribute("errorMessage",
                    "Stock problem - could not complete sale:<br>"
                    + "<ul><li>" + String.join("</li><li>", stockErrors) + "</li></ul>");
            showPOS(req, resp);
            return;
        }

        // ── Commit sale to DB (atomic transaction) ────────────────
        int saleId = saleDAO.createSale(sale);

        if (saleId <= 0) {
            req.setAttribute("errorMessage",
                    "Unexpected error: sale was not saved. Please try again.");
            showPOS(req, resp);
            return;
        }

        // ── Success: clear the cart and redirect to receipt ────────
        // Clearing first prevents a browser-refresh from re-submitting.
        cart.clear();

        resp.sendRedirect(req.getContextPath()
                + "/sales?action=receipt&id=" + saleId + "&success=sale");
    }

    /**
     * EXECUTE VOID
     * ─────────────────────────────────────────────────────────────
     * Finalises voiding a sale after the cashier confirmed on the
     * sale-confirm.jsp page. Stock is restored inside the DAO transaction.
     *
     * POST /sales?action=void&id=42
     * Form param: confirmed=yes  (set by the confirm form submit button)
     */
    private void executeVoid(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, IOException {

        // Only proceed if the cashier explicitly confirmed
        if (!"yes".equals(req.getParameter("confirmed"))) {
            resp.sendRedirect(req.getContextPath() + "/sales?action=history");
            return;
        }

        int id     = parseId(req.getParameter("id"));
        int result = saleDAO.voidSale(id);

        if (result == 0) {
            resp.sendRedirect(req.getContextPath()
                    + "/sales?action=history&error=notfound");
        } else if (result == -1) {
            resp.sendRedirect(req.getContextPath()
                    + "/sales?action=history&error=alreadyvoid");
        } else {
            resp.sendRedirect(req.getContextPath()
                    + "/sales?action=history&success=voided");
        }
    }

    /**
     * EXECUTE REFUND
     * ─────────────────────────────────────────────────────────────
     * Same pattern as executeVoid but calls saleDAO.refundSale().
     *
     * POST /sales?action=refund&id=42
     * Form param: confirmed=yes
     */
    private void executeRefund(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, IOException {

        if (!"yes".equals(req.getParameter("confirmed"))) {
            resp.sendRedirect(req.getContextPath() + "/sales?action=history");
            return;
        }

        int id     = parseId(req.getParameter("id"));
        int result = saleDAO.refundSale(id);

        if (result == 0) {
            resp.sendRedirect(req.getContextPath()
                    + "/sales?action=history&error=notfound");
        } else if (result == -1) {
            resp.sendRedirect(req.getContextPath()
                    + "/sales?action=history&error=alreadyvoid");
        } else {
            resp.sendRedirect(req.getContextPath()
                    + "/sales?action=history&success=refunded");
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //  SESSION CART HELPERS
    // ═══════════════════════════════════════════════════════════════════

    /**
     * Returns the cart list from the session, creating an empty one if
     * it doesn't exist yet.
     *
     * WHY store the cart in the session?
     *   The POS screen is visited multiple times as the cashier adds
     *   items. The cart must survive across GET requests. Using the session
     *   is the standard Java Servlet approach - no client-side JS state
     *   needed, and it works even if the browser refreshes.
     */
    @SuppressWarnings("unchecked")
    private List<SaleItem> getOrCreateCart(HttpSession session) {
        List<SaleItem> cart = (List<SaleItem>) session.getAttribute(SESSION_CART);
        if (cart == null) {
            cart = new ArrayList<>();
            session.setAttribute(SESSION_CART, cart);
        }
        return cart;
    }

    /**
     * Finds an existing cart line by productId, or returns null if
     * the product is not yet in the cart.
     */
    private SaleItem findCartItem(List<SaleItem> cart, int productId) {
        for (SaleItem item : cart) {
            if (item.getProductId() == productId) return item;
        }
        return null;
    }

    /**
     * Returns how many units of a given product are already in the cart.
     * Returns 0 if the product is not in the cart.
     */
    private int cartQuantityFor(List<SaleItem> cart, int productId) {
        for (SaleItem item : cart) {
            if (item.getProductId() == productId) return item.getQuantity();
        }
        return 0;
    }

    /**
     * Sums all line totals in the cart.
     * Used to display the running total on the POS screen before checkout.
     */
    private BigDecimal sumCartTotal(List<SaleItem> cart) {
        BigDecimal total = BigDecimal.ZERO;
        for (SaleItem item : cart) {
            if (item.getLineTotal() != null) {
                total = total.add(item.getLineTotal());
            }
        }
        return total;
    }

    // ═══════════════════════════════════════════════════════════════════
    //  SHARED PRIVATE HELPERS
    // ═══════════════════════════════════════════════════════════════════

    /**
     * Loads a sale by the "id" request parameter and returns it.
     * If the id is missing/invalid or the sale is not found, it redirects
     * to the history page with an error flash and returns null.
     *
     * Callers must check for null and return immediately if it is.
     */
    private Sale loadSaleOrRedirect(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, IOException {
        int id = parseId(req.getParameter("id"));
        if (id <= 0) {
            resp.sendRedirect(req.getContextPath()
                    + "/sales?action=history&error=notfound");
            return null;
        }
        Sale sale = saleDAO.getSaleById(id);
        if (sale == null) {
            resp.sendRedirect(req.getContextPath()
                    + "/sales?action=history&error=notfound");
            return null;
        }
        return sale;
    }

    /**
     * Sets success and error flash message attributes on the request,
     * based on the "success" and "error" query parameters in the redirect URL.
     *
     * @param successKeys   query param values that indicate success
     * @param successMessages the message to show for each success key
     * @param errorKeys     query param values that indicate an error
     * @param errorMessages the message to show for each error key
     */
    private void attachFlashMessages(HttpServletRequest req,
                                     String[] successKeys, String[] successMessages,
                                     String[] errorKeys,   String[] errorMessages) {
        String success = req.getParameter("success");
        String error   = req.getParameter("error");

        for (int i = 0; i < successKeys.length; i++) {
            if (successKeys[i].equals(success)) {
                req.setAttribute("successMessage", successMessages[i]);
                break;
            }
        }
        for (int i = 0; i < errorKeys.length; i++) {
            if (errorKeys[i].equals(error)) {
                req.setAttribute("errorMessage", errorMessages[i]);
                break;
            }
        }
    }

    /**
     * Centralised DB error handler - logs the exception and forwards to
     * an error-capable JSP with a human-friendly message.
     */
    private void handleDbError(HttpServletRequest req, HttpServletResponse resp,
                                SQLException e, String jspPath)
            throws ServletException, IOException {
        e.printStackTrace(); // logs to Tomcat catalina.out
        req.setAttribute("errorMessage",
                "A database error occurred: " + e.getMessage()
                + " - please contact your system administrator.");
        try {
            req.getRequestDispatcher(jspPath).forward(req, resp);
        } catch (Exception ignored) {}
    }

    // ═══════════════════════════════════════════════════════════════════
    //  PURE UTILITY - parsing and formatting
    // ═══════════════════════════════════════════════════════════════════

    /**
     * Safely parses an integer from a String.
     * Returns 0 on null, blank, or non-numeric input.
     */
    private int parseId(String s) {
        if (s == null || s.trim().isEmpty()) return 0;
        try { return Integer.parseInt(s.trim()); }
        catch (NumberFormatException e) { return 0; }
    }

    /**
     * Parses a positive integer, returning a default if invalid or <= 0.
     */
    private int parsePositiveInt(String s, int defaultValue) {
        if (s == null || s.trim().isEmpty()) return defaultValue;
        try {
            int v = Integer.parseInt(s.trim());
            return v > 0 ? v : defaultValue;
        } catch (NumberFormatException e) { return defaultValue; }
    }

    /**
     * Parses a BigDecimal from a String.
     * Returns the supplied default if the string is null, blank, or invalid.
     * Negative values are clamped to zero (discounts / taxes can't be negative).
     */
    private BigDecimal parseBigDecimal(String s, BigDecimal defaultValue) {
        if (s == null || s.trim().isEmpty()) return defaultValue;
        try {
            BigDecimal v = new BigDecimal(s.trim());
            return v.compareTo(BigDecimal.ZERO) < 0 ? BigDecimal.ZERO : v;
        } catch (NumberFormatException e) { return defaultValue; }
    }

    /**
     * Parses a date string in "yyyy-MM-dd" format.
     * Returns null if the string is null, blank, or unparseable.
     */
    private LocalDate parseDate(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return LocalDate.parse(s.trim(), DATE_FMT); }
        catch (DateTimeParseException e) { return null; }
    }

    /**
     * Validates that the payment method string is one of the 4 allowed values.
     * Null or blank counts as invalid.
     */
    private boolean isValidPaymentMethod(String pm) {
        return Sale.PAYMENT_CASH.equals(pm)
            || Sale.PAYMENT_TRANSFER.equals(pm)
            || Sale.PAYMENT_POS.equals(pm)
            || Sale.PAYMENT_CREDIT.equals(pm);
    }

    /**
     * Formats a BigDecimal as a comma-separated money string, e.g.
     * 1234567.89 -> "1,234,567.89"
     * Used in error messages so the cashier sees the same format as the UI.
     */
    private String fmt(BigDecimal amount) {
        if (amount == null) return "0.00";
        return String.format("%,.2f", amount);
    }

    /**
     * URL-encodes a string for safe use in query parameters.
     * Replaces spaces with '+' and encodes special chars.
     */
    private String encodeParam(String s) {
        if (s == null) return "";
        try {
            return java.net.URLEncoder.encode(s, "UTF-8");
        } catch (java.io.UnsupportedEncodingException e) {
            return s.replace(" ", "+");
        }
    }
}
