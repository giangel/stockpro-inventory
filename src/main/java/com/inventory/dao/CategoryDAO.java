
package com.inventory.dao;

import com.inventory.model.Category;
import com.inventory.util.DatabaseUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * CategoryDAO - Data Access Object
 * ---------------------------------
 * ALL SQL for the categories table lives here.
 * Servlets never write SQL - they call DAO methods.
 *
 * Pattern (same as ProductDAO):
 *   CategoryServlet -> calls CategoryDAO method
 *   CategoryDAO     -> runs SQL against PostgreSQL
 *   CategoryDAO     -> returns Category objects (never raw ResultSets)
 *
 * WHY a DAO?
 *   Keeps database code in one place. If the table changes you only
 *   edit this file, not every servlet.
 */
public class CategoryDAO {

    // ══════════════════════════════════════════════════════════
    // READ OPERATIONS
    // ══════════════════════════════════════════════════════════

    /**
     * Returns ALL categories ordered alphabetically.
     * Used by the category list page.
     *
     * We also count how many products use each category using a
     * LEFT JOIN so categories with zero products still appear.
     */
	public List<Category> getAllCategories() throws SQLException {
	    List<Category> list = new ArrayList<>();
	    Connection conn = null;
	    PreparedStatement ps = null;
	    ResultSet rs = null;

	    try {
	        conn = DatabaseUtil.getConnection();
	        
	        // Fixed the broken string concatenation at the end of the query string
	        String sql =
	            "SELECT c.id, c.name, c.description, c.created_at, " +
	            "       COUNT(p.id) AS product_count " +
	            "FROM   categories c " +
	            "LEFT JOIN products p ON p.category_id = c.id " +
	            "                    AND p.is_active = true " +
	            "GROUP BY c.id, c.name, c.description, c.created_at " +
	            "ORDER BY c.name ASC"; // Keep it on the same line inside the quotes

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
     * Returns a single category by its ID.
     * Used when opening the edit form.
     */
    public Category getCategoryById(int id) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            String sql =
                "SELECT c.id, c.name, c.description, c.created_at, " +
                "       COUNT(p.id) AS product_count " +
                "FROM   categories c " +
                "LEFT JOIN products p ON p.category_id = c.id " +
                "                    AND p.is_active = true " +
                "WHERE  c.id = ? " +
                "GROUP BY c.id, c.name, c.description, c.created_at";

            ps = conn.prepareStatement(sql);
            ps.setInt(1, id);
            rs = ps.executeQuery();

            if (rs.next()) return mapRow(rs);
            return null;

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    /**
     * Returns the total number of categories - for KPI stats.
     */
    public int getTotalCategoryCount() throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement("SELECT COUNT(*) FROM categories");
            rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    // ══════════════════════════════════════════════════════════
    // WRITE OPERATIONS
    // ══════════════════════════════════════════════════════════

    /**
     * Inserts a new category row.
     * RETURNING id is PostgreSQL syntax - gives us the generated SERIAL id.
     */
    public int createCategory(Category c) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            String sql =
                "INSERT INTO categories (name, description) " +
                "VALUES (?, ?) " +
                "RETURNING id";

            ps = conn.prepareStatement(sql);
            ps.setString(1, c.getName().trim());

            // description is optional - use setNull if blank
            String desc = c.getDescription();
            if (desc != null && !desc.trim().isEmpty()) {
                ps.setString(2, desc.trim());
            } else {
                ps.setNull(2, Types.VARCHAR);
            }

            rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : -1;

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    /**
     * Updates an existing category row.
     * Returns the number of rows affected (1 = success, 0 = not found).
     */
    public int updateCategory(Category c) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;

        try {
            conn = DatabaseUtil.getConnection();

            String sql =
                "UPDATE categories SET name = ?, description = ? " +
                "WHERE id = ?";

            ps = conn.prepareStatement(sql);
            ps.setString(1, c.getName().trim());

            String desc = c.getDescription();
            if (desc != null && !desc.trim().isEmpty()) {
                ps.setString(2, desc.trim());
            } else {
                ps.setNull(2, Types.VARCHAR);
            }

            ps.setInt(3, c.getId());

            return ps.executeUpdate();

        } finally {
            DatabaseUtil.close(null, ps, conn);
        }
    }

    /**
     * Deletes a category ONLY if it has no products linked to it.
     *
     * WHY check first?
     *   products.category_id has a FOREIGN KEY constraint.
     *   Deleting a category that products reference will throw a
     *   PostgreSQL constraint violation error (ugly 500 page).
     *   We check gracefully and return a helpful message instead.
     *
     * Returns:
     *   0  = deleted successfully
     *  -1  = category has products, deletion blocked
     */
    public int deleteCategory(int id) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            // 1. Check if any active products use this category
            ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM products WHERE category_id = ? AND is_active = true");
            ps.setInt(1, id);
            rs = ps.executeQuery();

            if (rs.next() && rs.getInt(1) > 0) {
                return -1; // blocked - category has products
            }

            // 2. Safe to delete
            DatabaseUtil.close(rs, ps, null);
            ps = conn.prepareStatement("DELETE FROM categories WHERE id = ?");
            ps.setInt(1, id);
            return ps.executeUpdate(); // 1 = deleted, 0 = not found

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    // ══════════════════════════════════════════════════════════
    // VALIDATION HELPERS
    // ══════════════════════════════════════════════════════════

    /**
     * Checks if a category name already exists (case-insensitive).
     *
     * @param name      the name to check
     * @param excludeId pass 0 when creating; pass the category's id when editing
     *                  (so we don't flag a category as duplicate against itself)
     */
    public boolean nameExists(String name, int excludeId) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            // ILIKE is PostgreSQL case-insensitive LIKE
            ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM categories WHERE LOWER(name) = LOWER(?) AND id != ?");
            ps.setString(1, name.trim());
            ps.setInt(2, excludeId);
            rs = ps.executeQuery();
            return rs.next() && rs.getInt(1) > 0;
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    // ══════════════════════════════════════════════════════════
    // PRIVATE HELPERS
    // ══════════════════════════════════════════════════════════

    /**
     * Maps one ResultSet row -> one Category object.
     * Called from every SELECT method to avoid repeating the same mapping code.
     */
    private Category mapRow(ResultSet rs) throws SQLException {
        Category c = new Category();
        c.setId(rs.getInt("id"));
        c.setName(rs.getString("name"));
        c.setDescription(rs.getString("description"));
        c.setProductCount(rs.getInt("product_count"));

        Timestamp created = rs.getTimestamp("created_at");
        if (created != null) c.setCreatedAt(created.toLocalDateTime());

        return c;
    }
}