package com.inventory.servlet;

import com.inventory.dao.SupplierDAO;
import com.inventory.model.Supplier;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * SupplierServlet
 * ---------------
 * Handles ALL supplier operations using a single "action" parameter.
 *
 * URL patterns:
 *   GET  /suppliers?action=list          -> show all suppliers
 *   GET  /suppliers?action=new           -> show empty add form
 *   GET  /suppliers?action=edit&id=3     -> show edit form pre-filled
 *   GET  /suppliers?action=delete&id=3   -> soft-delete supplier
 *   POST /suppliers?action=create        -> save new supplier to DB
 *   POST /suppliers?action=update        -> save edited supplier to DB
 *
 * Why one servlet for everything?
 *   Keeps all supplier logic in one place.
 *   Easy to find, easy to maintain.
 *   Standard pattern for Java web apps without a framework.
 */
@WebServlet("/suppliers")
public class SupplierServlet extends HttpServlet {

    private final SupplierDAO dao = new SupplierDAO();

    // ── GET requests ──────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null) action = "list";

        try {
            switch (action) {
                case "list":   showList(req, resp);       break;
                case "new":    showForm(req, resp, false); break;
                case "edit":   showEditForm(req, resp);   break;
                case "delete": deleteSupplier(req, resp); break;
                default:       showList(req, resp);
            }
        } catch (SQLException e) {
            e.printStackTrace();
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
            try {
                req.getRequestDispatcher("/suppliers.jsp").forward(req, resp);
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }
    }

    // ── POST requests ─────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null) action = "list";

        try {
            switch (action) {
                case "create": createSupplier(req, resp); break;
                case "update": updateSupplier(req, resp); break;
                default:       showList(req, resp);
            }
        } catch (SQLException e) {
            e.printStackTrace();
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
            try {
                req.getRequestDispatcher("/suppliers.jsp").forward(req, resp);
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }
    }

    // ══════════════════════════════════════════════════════════
    // PRIVATE ACTION HANDLERS
    // ══════════════════════════════════════════════════════════

    /**
     * Loads all suppliers from DB and forwards to suppliers.jsp.
     * Also reads success/error flash params passed via redirect.
     */
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        List<Supplier> suppliers = dao.getAllSuppliers();
        req.setAttribute("suppliers",    suppliers);
        req.setAttribute("totalCount",   suppliers.size());
        req.setAttribute("activeCount",  dao.getActiveSupplierCount());
        req.getRequestDispatcher("/suppliers.jsp").forward(req, resp);
    }

    /**
     * Prepares an empty form for adding a new supplier.
     * Sets formMode = "add" so the JSP shows the right title and button.
     */
    private void showForm(HttpServletRequest req, HttpServletResponse resp,
                          boolean isEdit)
            throws SQLException, ServletException, IOException {

        if (!isEdit) {
            req.setAttribute("supplier", new Supplier());
            req.setAttribute("formMode", "add");
        }
        req.getRequestDispatcher("/supplier-form.jsp").forward(req, resp);
    }

    /**
     * Loads an existing supplier by ID and forwards to the edit form.
     * If the ID is invalid or not found, redirects back to list with an error.
     */
    private void showEditForm(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        int id = parseId(req.getParameter("id"));
        Supplier supplier = dao.getSupplierById(id);

        if (supplier == null) {
            resp.sendRedirect(req.getContextPath() + "/suppliers?action=list&error=notfound");
            return;
        }

        req.setAttribute("supplier", supplier);
        req.setAttribute("formMode", "edit");
        req.getRequestDispatcher("/supplier-form.jsp").forward(req, resp);
    }

    /**
     * Reads form data, validates, inserts into DB, then redirects.
     * On validation failure: re-shows the form with an error message
     * so the user doesn't lose their input.
     */
    private void createSupplier(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        Supplier s = buildFromRequest(req);

        String error = validate(s, 0);
        if (error != null) {
            req.setAttribute("errorMessage", error);
            req.setAttribute("supplier",     s);
            req.setAttribute("formMode",     "add");
            req.getRequestDispatcher("/supplier-form.jsp").forward(req, resp);
            return;
        }

        dao.createSupplier(s);
        resp.sendRedirect(req.getContextPath() + "/suppliers?action=list&success=created");
    }

    /**
     * Reads form data, validates, updates DB row, then redirects.
     * On failure: re-shows the edit form with the error message.
     */
    private void updateSupplier(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        int id = parseId(req.getParameter("id"));
        Supplier s = buildFromRequest(req);
        s.setId(id);

        String error = validate(s, id);
        if (error != null) {
            req.setAttribute("errorMessage", error);
            req.setAttribute("supplier",     s);
            req.setAttribute("formMode",     "edit");
            req.getRequestDispatcher("/supplier-form.jsp").forward(req, resp);
            return;
        }

        dao.updateSupplier(s);
        resp.sendRedirect(req.getContextPath() + "/suppliers?action=list&success=updated");
    }

    /**
     * Soft-deletes a supplier (sets is_active = false).
     *
     * Safety check: if the supplier still has active products linked to them,
     * we block the deletion and redirect with a warning instead.
     * This prevents products from losing their supplier reference silently.
     */
    private void deleteSupplier(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, IOException {

        int id = parseId(req.getParameter("id"));

        if (dao.hasActiveProducts(id)) {
            // Block deletion - supplier still has products
            resp.sendRedirect(req.getContextPath() +
                "/suppliers?action=list&error=hasproducts");
            return;
        }

        dao.deleteSupplier(id);
        resp.sendRedirect(req.getContextPath() + "/suppliers?action=list&success=deleted");
    }

    // ══════════════════════════════════════════════════════════
    // HELPERS
    // ══════════════════════════════════════════════════════════

    /**
     * Reads all supplier form fields from the request and
     * builds a Supplier object. Used by both create and update.
     */
    private Supplier buildFromRequest(HttpServletRequest req) {
        Supplier s = new Supplier();
        s.setName(        clean(req.getParameter("name")));
        s.setContactName( clean(req.getParameter("contactName")));
        s.setPhone(       clean(req.getParameter("phone")));
        s.setEmail(       clean(req.getParameter("email")));
        s.setAddress(     clean(req.getParameter("address")));
        return s;
    }

    /**
     * Server-side validation.
     * Returns an error message string if invalid, null if all good.
     *
     * Client-side JS also validates, but server-side is mandatory -
     * users can bypass client-side validation by crafting raw HTTP requests.
     */
    private String validate(Supplier s, int excludeId) throws SQLException {
        if (s.getName() == null || s.getName().isEmpty())
            return "Supplier name is required.";
        if (s.getName().length() > 150)
            return "Supplier name must be 150 characters or less.";
        if (s.getEmail() != null && !s.getEmail().isEmpty()) {
            if (!s.getEmail().matches("^[\\w._%+\\-]+@[\\w.\\-]+\\.[a-zA-Z]{2,}$"))
                return "Please enter a valid email address.";
            if (dao.emailExists(s.getEmail(), excludeId))
                return "Email \"" + s.getEmail() + "\" is already registered to another supplier.";
        }
        if (s.getPhone() != null && !s.getPhone().isEmpty()) {
            if (s.getPhone().length() > 20)
                return "Phone number must be 20 characters or less.";
        }
        return null; // all good
    }

    /** Trims whitespace and handles null safely */
    private String clean(String s) {
        return (s == null) ? "" : s.trim();
    }

    /** Parses an integer safely - returns 0 on null or parse error */
    private int parseId(String s) {
        try { return Integer.parseInt(s == null ? "0" : s.trim()); }
        catch (NumberFormatException e) { return 0; }
    }
}
