
package com.inventory.servlet;

import com.inventory.dao.ProductDAO;
import com.inventory.model.Product;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;

/**
 * ProductServlet
 * --------------
 * One servlet handles ALL product operations using an "action" parameter.
 *
 * URL patterns:
 *   GET  /products?action=list          -> show all products
 *   GET  /products?action=new           -> show empty add form
 *   GET  /products?action=edit&id=5     -> show edit form pre-filled
 *   POST /products?action=create        -> save new product
 *   POST /products?action=update        -> save edited product
 *   GET  /products?action=delete&id=5  -> soft-delete product
 */
@WebServlet("/products")
public class ProductServlet extends HttpServlet {

    private final ProductDAO dao = new ProductDAO();

    // ── GET requests ─────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null) action = "list";

        try {
            switch (action) {

                case "list":
                    showList(req, resp);
                    break;

                case "new":
                    showAddForm(req, resp);
                    break;

                case "edit":
                    showEditForm(req, resp);
                    break;

                case "delete":
                    deleteProduct(req, resp);
                    break;

                default:
                    showList(req, resp);
            }

        } catch (SQLException e) {
            e.printStackTrace();
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
            req.getRequestDispatcher("/products.jsp").forward(req, resp);
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
                case "create":
                    createProduct(req, resp);
                    break;
                case "update":
                    updateProduct(req, resp);
                    break;
                default:
                    showList(req, resp);
            }
        } catch (SQLException e) {
            e.printStackTrace();
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
            req.getRequestDispatcher("/products.jsp").forward(req, resp);
        }
    }

    // ── Private action handlers ───────────────────────────────

    /** Load all products and forward to products.jsp */
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        List<Product> products = dao.getAllProducts();
        req.setAttribute("products",     products);
        req.setAttribute("totalCount",   products.size());
        req.setAttribute("lowStockCount",dao.getLowStockProducts().size());
        req.setAttribute("inventoryValue", dao.getTotalInventoryValue());
        req.getRequestDispatcher("/products.jsp").forward(req, resp);
    }

    /** Load categories + suppliers for dropdowns, forward to product-form.jsp */
    private void showAddForm(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        req.setAttribute("categories", dao.getAllCategories());
        req.setAttribute("suppliers",  dao.getAllSuppliers());
        req.setAttribute("formMode",   "add");         // tells JSP which title/button to show
        req.setAttribute("product",    new Product()); // empty product for the form
        req.getRequestDispatcher("/product-form.jsp").forward(req, resp);
    }

    /** Load specific product + dropdowns, forward to product-form.jsp for editing */
    private void showEditForm(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        int id = parseId(req.getParameter("id"));
        Product product = dao.getProductById(id);

        if (product == null) {
            resp.sendRedirect(req.getContextPath() + "/products?action=list&error=notfound");
            return;
        }

        req.setAttribute("product",    product);
        req.setAttribute("categories", dao.getAllCategories());
        req.setAttribute("suppliers",  dao.getAllSuppliers());
        req.setAttribute("formMode",   "edit");
        req.getRequestDispatcher("/product-form.jsp").forward(req, resp);
    }

    /** Read form data, validate, insert into DB, redirect */
    private void createProduct(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        Product p = buildProductFromRequest(req);

        // Server-side validation
        String validationError = validate(p, 0);
        if (validationError != null) {
            req.setAttribute("errorMessage", validationError);
            req.setAttribute("product",    p);
            req.setAttribute("categories", dao.getAllCategories());
            req.setAttribute("suppliers",  dao.getAllSuppliers());
            req.setAttribute("formMode",   "add");
            req.getRequestDispatcher("/product-form.jsp").forward(req, resp);
            return;
        }

        dao.createProduct(p);
        resp.sendRedirect(req.getContextPath() + "/products?action=list&success=created");
    }

    /** Read form data, validate, update DB row, redirect */
    private void updateProduct(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        int id = parseId(req.getParameter("id"));
        Product p = buildProductFromRequest(req);
        p.setId(id);

        String validationError = validate(p, id);
        if (validationError != null) {
            req.setAttribute("errorMessage", validationError);
            req.setAttribute("product",    p);
            req.setAttribute("categories", dao.getAllCategories());
            req.setAttribute("suppliers",  dao.getAllSuppliers());
            req.setAttribute("formMode",   "edit");
            req.getRequestDispatcher("/product-form.jsp").forward(req, resp);
            return;
        }

        dao.updateProduct(p);
        resp.sendRedirect(req.getContextPath() + "/products?action=list&success=updated");
    }

    /** Soft-delete the product and redirect back to list */
    private void deleteProduct(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, IOException {

        int id = parseId(req.getParameter("id"));
        dao.deleteProduct(id);
        resp.sendRedirect(req.getContextPath() + "/products?action=list&success=deleted");
    }

    // ── Helpers ───────────────────────────────────────────────

    /** Reads all form fields and builds a Product object */
    private Product buildProductFromRequest(HttpServletRequest req) {
        Product p = new Product();
        p.setName(        clean(req.getParameter("name")));
        p.setSku(         clean(req.getParameter("sku")));
        p.setDescription( clean(req.getParameter("description")));
        p.setCategoryId(  parseId(req.getParameter("categoryId")));
        p.setSupplierId(  parseId(req.getParameter("supplierId")));
        p.setUnit(        clean(req.getParameter("unit")));
        p.setCostPrice(   parseMoney(req.getParameter("costPrice")));
        p.setSellingPrice(parseMoney(req.getParameter("sellingPrice")));
        p.setCurrentStock(parseId(req.getParameter("currentStock")));
        p.setReorderLevel(parseId(req.getParameter("reorderLevel")));
        return p;
    }

    /** Returns an error message string, or null if everything is valid */
    private String validate(Product p, int excludeId) throws SQLException {
        if (p.getName() == null || p.getName().isEmpty())
            return "Product name is required.";
        if (p.getSku() == null || p.getSku().isEmpty())
            return "SKU is required.";
        if (p.getCategoryId() <= 0)
            return "Please select a category.";
        if (p.getUnit() == null || p.getUnit().isEmpty())
            return "Unit is required.";
        if (p.getSellingPrice() == null || p.getSellingPrice().compareTo(BigDecimal.ZERO) < 0)
            return "Selling price must be 0 or greater.";
        if (p.getCostPrice() == null || p.getCostPrice().compareTo(BigDecimal.ZERO) < 0)
            return "Cost price must be 0 or greater.";
        if (dao.skuExists(p.getSku(), excludeId))
            return "SKU \"" + p.getSku() + "\" is already used by another product.";
        return null;
    }

    /** Trim and null-safe string cleaner */
    private String clean(String s) {
        return (s == null) ? "" : s.trim();
    }

    /** Parse integer safely - returns 0 on failure */
    private int parseId(String s) {
        try { return Integer.parseInt(s == null ? "0" : s.trim()); }
        catch (NumberFormatException e) { return 0; }
    }

    /** Parse BigDecimal safely - returns ZERO on failure */
    private BigDecimal parseMoney(String s) {
        try { return new BigDecimal(s == null ? "0" : s.trim()); }
        catch (NumberFormatException e) { return BigDecimal.ZERO; }
    }
}