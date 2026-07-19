
package com.inventory.dao;

import com.inventory.model.Category;
import com.inventory.model.Product;
import com.inventory.model.Supplier;
import com.inventory.util.DatabaseUtil;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * ProductDAO - Data Access Object
 * --------------------------------
 * ALL database SQL for products lives here.
 * Servlets never write SQL - they call DAO methods.
 * This keeps code clean and easy to maintain.
 *
 * Pattern:
 *   Servlet -> calls ProductDAO method
 *   ProductDAO -> runs SQL against PostgreSQL
 *   ProductDAO -> returns Product objects (never raw ResultSets)
 */
public class ProductDAO {

    // ══════════════════════════════════════════════════════════
    // READ OPERATIONS
    // ══════════════════════════════════════════════════════════

    /**
     * Returns ALL active products, joined with category and supplier names.
     * Used by the product listing page.
     */
    public List<Product> getAllProducts() throws SQLException {
        List<Product> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            // LEFT JOIN so products without a supplier still appear
            String sql =
                "SELECT p.id, p.name, p.sku, p.description, " +
                "       p.category_id, c.name AS category_name, " +
                "       p.supplier_id, s.name AS supplier_name, " +
                "       p.unit, p.cost_price, p.selling_price, " +
                "       p.current_stock, p.reorder_level, p.is_active, " +
                "       p.created_at, p.updated_at " +
                "FROM   products p " +
                "JOIN   categories c ON p.category_id = c.id " +
                "LEFT JOIN suppliers s ON p.supplier_id = s.id " +
                "WHERE  p.is_active = true " +
                "ORDER  BY p.name ASC";

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
     * Returns a single product by its ID.
     * Used when opening the edit form.
     */
    public Product getProductById(int id) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();
            String sql =
                "SELECT p.id, p.name, p.sku, p.description, " +
                "       p.category_id, c.name AS category_name, " +
                "       p.supplier_id, s.name AS supplier_name, " +
                "       p.unit, p.cost_price, p.selling_price, " +
                "       p.current_stock, p.reorder_level, p.is_active, " +
                "       p.created_at, p.updated_at " +
                "FROM   products p " +
                "JOIN   categories c ON p.category_id = c.id " +
                "LEFT JOIN suppliers s ON p.supplier_id = s.id " +
                "WHERE  p.id = ?";

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
     * Returns products whose stock is at or below their reorder level.
     * Used by dashboard alerts panel.
     */
    public List<Product> getLowStockProducts() throws SQLException {
        List<Product> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();
            String sql =
                "SELECT p.id, p.name, p.sku, p.description, " +
                "       p.category_id, c.name AS category_name, " +
                "       p.supplier_id, s.name AS supplier_name, " +
                "       p.unit, p.cost_price, p.selling_price, " +
                "       p.current_stock, p.reorder_level, p.is_active, " +
                "       p.created_at, p.updated_at " +
                "FROM   products p " +
                "JOIN   categories c ON p.category_id = c.id " +
                "LEFT JOIN suppliers s ON p.supplier_id = s.id " +
                "WHERE  p.is_active = true " +
                "  AND  p.current_stock <= p.reorder_level " +
                "ORDER  BY p.current_stock ASC";

            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
        return list;
    }

    /** Total number of active products - for dashboard KPI card */
    public int getTotalProductCount() throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM products WHERE is_active = true");
            rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    /** Total inventory value (sum of cost_price * current_stock) */
    public BigDecimal getTotalInventoryValue() throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT COALESCE(SUM(cost_price * current_stock), 0) " +
                "FROM products WHERE is_active = true");
            rs = ps.executeQuery();
            return rs.next() ? rs.getBigDecimal(1) : BigDecimal.ZERO;
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    // ══════════════════════════════════════════════════════════
    // WRITE OPERATIONS
    // ══════════════════════════════════════════════════════════

    /**
     * Inserts a new product row into the database.
     * Returns the generated ID of the new product.
     */
    public int createProduct(Product p) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();

            // RETURNING id is PostgreSQL syntax -
            // it gives us back the auto-generated SERIAL id immediately
            String sql =
                "INSERT INTO products " +
                "  (name, sku, description, category_id, supplier_id, unit, " +
                "   cost_price, selling_price, current_stock, reorder_level) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) " +
                "RETURNING id";

            ps = conn.prepareStatement(sql);
            ps.setString(1,     p.getName());
            ps.setString(2,     p.getSku());
            ps.setString(3,     p.getDescription());
            ps.setInt(4,        p.getCategoryId());

            // supplier_id is nullable - use setNull if not provided
            if (p.getSupplierId() > 0) {
                ps.setInt(5, p.getSupplierId());
            } else {
                ps.setNull(5, Types.INTEGER);
            }

            ps.setString(6,        p.getUnit());
            ps.setBigDecimal(7,    p.getCostPrice());
            ps.setBigDecimal(8,    p.getSellingPrice());
            ps.setInt(9,           p.getCurrentStock());
            ps.setInt(10,          p.getReorderLevel());

            rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : -1;

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    /**
     * Updates an existing product row.
     * Returns number of rows affected (should be 1 on success).
     */
    public int updateProduct(Product p) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;

        try {
            conn = DatabaseUtil.getConnection();
            String sql =
                "UPDATE products SET " +
                "  name = ?, sku = ?, description = ?, " +
                "  category_id = ?, supplier_id = ?, unit = ?, " +
                "  cost_price = ?, selling_price = ?, " +
                "  current_stock = ?, reorder_level = ? " +
                "WHERE id = ?";

            ps = conn.prepareStatement(sql);
            ps.setString(1,     p.getName());
            ps.setString(2,     p.getSku());
            ps.setString(3,     p.getDescription());
            ps.setInt(4,        p.getCategoryId());

            if (p.getSupplierId() > 0) {
                ps.setInt(5, p.getSupplierId());
            } else {
                ps.setNull(5, Types.INTEGER);
            }

            ps.setString(6,        p.getUnit());
            ps.setBigDecimal(7,    p.getCostPrice());
            ps.setBigDecimal(8,    p.getSellingPrice());
            ps.setInt(9,           p.getCurrentStock());
            ps.setInt(10,          p.getReorderLevel());
            ps.setInt(11,          p.getId());

            return ps.executeUpdate();

        } finally {
            DatabaseUtil.close(null, ps, conn);
        }
    }

    /**
     * Soft-delete: sets is_active = false instead of actually deleting.
     * This preserves the product's history in transactions and sales.
     */
    public int deleteProduct(int id) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;

        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "UPDATE products SET is_active = false WHERE id = ?");
            ps.setInt(1, id);
            return ps.executeUpdate();
        } finally {
            DatabaseUtil.close(null, ps, conn);
        }
    }

    /**
     * Check if a SKU already exists (to prevent duplicates).
     * Pass excludeId = 0 when creating; pass the product's id when editing.
     */
    public boolean skuExists(String sku, int excludeId) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM products WHERE sku = ? AND id != ?");
            ps.setString(1, sku);
            ps.setInt(2, excludeId);
            rs = ps.executeQuery();
            return rs.next() && rs.getInt(1) > 0;
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    // ══════════════════════════════════════════════════════════
    // DROPDOWN SUPPORT - for the product add/edit form
    // ══════════════════════════════════════════════════════════

    /** All categories - for the category dropdown in the product form */
    public List<Category> getAllCategories() throws SQLException {
        List<Category> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT id, name FROM categories ORDER BY name ASC");
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(new Category(rs.getInt("id"), rs.getString("name")));
            }
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
        return list;
    }

    /** All active suppliers - for the supplier dropdown in the product form */
    public List<Supplier> getAllSuppliers() throws SQLException {
        List<Supplier> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT id, name FROM suppliers WHERE is_active = true ORDER BY name ASC");
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(new Supplier(rs.getInt("id"), rs.getString("name")));
            }
        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
        return list;
    }

    // ══════════════════════════════════════════════════════════
    // PRIVATE HELPERS
    // ══════════════════════════════════════════════════════════

    /**
     * Maps one ResultSet row -> one Product object.
     * Called from every SELECT method above to avoid repetition.
     */
    private Product mapRow(ResultSet rs) throws SQLException {
        Product p = new Product();
        p.setId(rs.getInt("id"));
        p.setName(rs.getString("name"));
        p.setSku(rs.getString("sku"));
        p.setDescription(rs.getString("description"));
        p.setCategoryId(rs.getInt("category_id"));
        p.setCategoryName(rs.getString("category_name"));
        p.setSupplierId(rs.getInt("supplier_id"));
        p.setSupplierName(rs.getString("supplier_name"));
        p.setUnit(rs.getString("unit"));
        p.setCostPrice(rs.getBigDecimal("cost_price"));
        p.setSellingPrice(rs.getBigDecimal("selling_price"));
        p.setCurrentStock(rs.getInt("current_stock"));
        p.setReorderLevel(rs.getInt("reorder_level"));
        p.setActive(rs.getBoolean("is_active"));

        Timestamp created = rs.getTimestamp("created_at");
        if (created != null) p.setCreatedAt(created.toLocalDateTime());

        Timestamp updated = rs.getTimestamp("updated_at");
        if (updated != null) p.setUpdatedAt(updated.toLocalDateTime());

        return p;
    }
}