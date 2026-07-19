
package com.inventory.servlet;

import com.inventory.dao.CategoryDAO;
import com.inventory.model.Category;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * CategoryServlet
 * ---------------
 * One servlet handles ALL category operations using an "action" query parameter.
 *
 * URL patterns (mapped to /categories in web.xml):
 *
 *   GET  /categories?action=list           -> show all categories (default)
 *   GET  /categories?action=new            -> show empty Add Category form
 *   GET  /categories?action=edit&id=3      -> show Edit Category form pre-filled
 *   POST /categories?action=create         -> save a new category to the DB
 *   POST /categories?action=update         -> save changes to an existing category
 *   GET  /categories?action=delete&id=3   -> delete a category (if safe)
 *
 * WHY action-based routing?
 *   A single servlet for one resource keeps the web.xml clean and makes
 *   the code easier to follow. This is a standard pattern for Java Servlet
 *   CRUD before REST frameworks existed.
 */
@WebServlet("/categories")
public class CategoryServlet extends HttpServlet {

    // Create ONE DAO instance shared across requests (it is stateless, so this is fine)
    private final CategoryDAO dao = new CategoryDAO();

    // ═══════════════════════════════════════════════════════════════════
    //  GET - read operations
    // ═══════════════════════════════════════════════════════════════════

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
                    deleteCategory(req, resp);
                    break;

                default:
                    showList(req, resp);
            }

        } catch (SQLException e) {
            // Log to server console and show a friendly error on the JSP
            e.printStackTrace();
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
            try {
                req.getRequestDispatcher("/categories.jsp").forward(req, resp);
            } catch (Exception ignored) {}
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //  POST - write operations
    // ═══════════════════════════════════════════════════════════════════

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null) action = "list";

        try {
            switch (action) {
                case "create":
                    createCategory(req, resp);
                    break;
                case "update":
                    updateCategory(req, resp);
                    break;
                default:
                    showList(req, resp);
            }
        } catch (SQLException e) {
            e.printStackTrace();
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
            try {
                req.getRequestDispatcher("/categories.jsp").forward(req, resp);
            } catch (Exception ignored) {}
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //  PRIVATE ACTION HANDLERS
    // ═══════════════════════════════════════════════════════════════════

    /**
     * LIST - fetch all categories and forward to categories.jsp.
     *
     * We also attach:
     *   - totalCount      -> for the KPI card at the top
     *   - successMessage  -> flash message after create/update/delete
     *   - errorMessage    -> flash message if delete was blocked
     */
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        List<Category> categories = dao.getAllCategories();
        req.setAttribute("categories",  categories);
        req.setAttribute("totalCount",  categories.size());

        // Flash messages come in via redirect query params
        String success = req.getParameter("success");
        String error   = req.getParameter("error");

        if ("created".equals(success))   req.setAttribute("successMessage", "Category created successfully.");
        if ("updated".equals(success))   req.setAttribute("successMessage", "Category updated successfully.");
        if ("deleted".equals(success))   req.setAttribute("successMessage", "Category deleted successfully.");
        if ("hasproducts".equals(error)) req.setAttribute("errorMessage",
            "Cannot delete this category - it still has products linked to it. " +
            "Remove or reassign those products first.");
        if ("notfound".equals(error))    req.setAttribute("errorMessage",
            "Category not found. It may have already been deleted.");

        req.getRequestDispatcher("/categories.jsp").forward(req, resp);
    }

    /**
     * NEW FORM - forward to category-form.jsp with an empty Category object.
     * The JSP checks formMode to decide what title and button label to show.
     */
    private void showAddForm(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("formMode", "add");
        req.setAttribute("category", new Category()); // empty bean for the form
        req.getRequestDispatcher("/category-form.jsp").forward(req, resp);
    }

    /**
     * EDIT FORM - load the category by id and pre-fill the form.
     */
    private void showEditForm(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        int id = parseId(req.getParameter("id"));
        Category category = dao.getCategoryById(id);

        if (category == null) {
            resp.sendRedirect(req.getContextPath() + "/categories?action=list&error=notfound");
            return;
        }

        req.setAttribute("category", category);
        req.setAttribute("formMode", "edit");
        req.getRequestDispatcher("/category-form.jsp").forward(req, resp);
    }

    /**
     * CREATE - validate form input, then insert into the DB.
     *
     * Validation rules:
     *   - Name is required and must not be blank
     *   - Name must be unique (case-insensitive)
     *   - Description is optional
     *
     * If validation fails -> return to the form with error messages so the
     *   user does not lose what they typed.
     * If successful -> redirect to list with ?success=created
     */
    private void createCategory(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        // 1. Read form fields
        String name = req.getParameter("name");
        String desc = req.getParameter("description");

        // 2. Validate
        if (name == null || name.trim().isEmpty()) {
            req.setAttribute("errorMessage", "Category name is required.");
            req.setAttribute("formMode",     "add");
            // Preserve what the user typed so they can fix it
            Category c = new Category();
            c.setName(name == null ? "" : name);
            c.setDescription(desc);
            req.setAttribute("category", c);
            req.getRequestDispatcher("/category-form.jsp").forward(req, resp);
            return;
        }

        // Check for duplicate name
        if (dao.nameExists(name, 0)) {
            req.setAttribute("errorMessage", "A category with that name already exists.");
            req.setAttribute("formMode",     "add");
            Category c = new Category();
            c.setName(name);
            c.setDescription(desc);
            req.setAttribute("category", c);
            req.getRequestDispatcher("/category-form.jsp").forward(req, resp);
            return;
        }

        // 3. Build Category object and insert
        Category c = new Category();
        c.setName(name.trim());
        c.setDescription(desc);

        dao.createCategory(c);

        // 4. Redirect using POST -> REDIRECT -> GET pattern
        //    This prevents duplicate submissions if the user refreshes.
        resp.sendRedirect(req.getContextPath() + "/categories?action=list&success=created");
    }

    /**
     * UPDATE - validate then update the existing category row.
     */
    private void updateCategory(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {

        // 1. Read fields
        int    id   = parseId(req.getParameter("id"));
        String name = req.getParameter("name");
        String desc = req.getParameter("description");

        // 2. Re-load the original in case validation fails (keeps the id on the form)
        Category existing = dao.getCategoryById(id);
        if (existing == null) {
            resp.sendRedirect(req.getContextPath() + "/categories?action=list&error=notfound");
            return;
        }

        // 3. Validate name
        if (name == null || name.trim().isEmpty()) {
            req.setAttribute("errorMessage", "Category name is required.");
            req.setAttribute("formMode",     "edit");
            existing.setName(name == null ? "" : name);
            existing.setDescription(desc);
            req.setAttribute("category", existing);
            req.getRequestDispatcher("/category-form.jsp").forward(req, resp);
            return;
        }

        // Check for duplicate name (exclude THIS category's own id)
        if (dao.nameExists(name, id)) {
            req.setAttribute("errorMessage", "Another category already has that name.");
            req.setAttribute("formMode",     "edit");
            existing.setName(name);
            existing.setDescription(desc);
            req.setAttribute("category", existing);
            req.getRequestDispatcher("/category-form.jsp").forward(req, resp);
            return;
        }

        // 4. Apply changes and update
        existing.setName(name.trim());
        existing.setDescription(desc);
        dao.updateCategory(existing);

        resp.sendRedirect(req.getContextPath() + "/categories?action=list&success=updated");
    }

    /**
     * DELETE - soft or hard delete.
     *
     * Our CategoryDAO.deleteCategory() returns:
     *   -1  -> category has active products -> blocked
     *    0  -> category not found
     *    1  -> deleted OK
     *
     * We redirect back to the list with the appropriate query param.
     */
    private void deleteCategory(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, IOException {

        int id = parseId(req.getParameter("id"));

        int result = dao.deleteCategory(id);

        if (result == -1) {
            // Blocked - category has products
            resp.sendRedirect(req.getContextPath() + "/categories?action=list&error=hasproducts");
        } else if (result == 0) {
            // Not found
            resp.sendRedirect(req.getContextPath() + "/categories?action=list&error=notfound");
        } else {
            // Deleted
            resp.sendRedirect(req.getContextPath() + "/categories?action=list&success=deleted");
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //  UTILITY
    // ═══════════════════════════════════════════════════════════════════

    /**
     * Safely parses the "id" query parameter.
     * Returns 0 if the parameter is null, blank, or not a valid integer.
     * This prevents NumberFormatException from crashing the servlet.
     */
    private int parseId(String idStr) {
        if (idStr == null || idStr.trim().isEmpty()) return 0;
        try {
            return Integer.parseInt(idStr.trim());
        } catch (NumberFormatException e) {
            return 0;
        }
    }
}