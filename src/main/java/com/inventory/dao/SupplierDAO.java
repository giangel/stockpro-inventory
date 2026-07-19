package com.inventory.dao;

import com.inventory.model.Supplier;
import com.inventory.util.DatabaseUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * SupplierDAO - Data Access Object
 * ---------------------------------
 * ALL database SQL for suppliers lives here.
 * Servlets never write SQL - they call DAO methods.
 *
 * Operations:
 *   getAllSuppliers()          -> full list for the suppliers page
 *   getActiveSuppliers()      -> active only, for product form dropdown
 *   getSupplierById(id)       -> single supplier for edit form
 *   createSupplier(s)         -> INSERT new supplier
 *   updateSupplier(s)         -> UPDATE existing supplier
 *   deleteSupplier(id)        -> soft-delete (set is_active = false)
 *   emailExists(email, id)    -> duplicate email check
 *   getActiveSupplierCount()  -> count for dashboard KPI
 *   hasActiveProducts(id)     -> check before deletion
 */
public class SupplierDAO {

    // ══════════════════════════════════════════════════════════
    // READ OPERATIONS
    // ══════════════════════════════════════════════════════════

    /**
     * Returns ALL suppliers (active and inactive).
     * Also counts how many active products each supplier has.
     * Used by the suppliers listing page.
     */
    public List<Supplier> getAllSuppliers() throws SQLException {
        List<Supplier> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();
            String sql =
                "SELECT s.id, s.name, s.contact_name, s.phone, s.email, " +
                "       s.address, s.is_active, s.created_at, " +
                "       COUNT(p.id) AS product_count " +
                "FROM   suppliers s " +
                "LEFT JOIN products p ON p.supplier_id = s.id AND p.is_active = true " +
                "GROUP  BY s.id, s.name, s.contact_name, s.phone, " +
                "          s.email, s.address, s.is_active, s.created_at " +
                "ORDER  BY s.name ASC";

            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();

            while (rs.next()) {
                Supplier sup = mapRow(rs);
                sup.setProductCount(rs.getInt("product_count"));
                list.add(sup);
            }

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
        return list;
    }

    /**
     * Returns ONLY active suppliers.
     * Used by the product add/edit form dropdown.
     */
    public List<Supplier> getActiveSuppliers() throws SQLException {
        List<Supplier> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();
            String sql =
                "SELECT id, name, contact_name, phone, email, address, is_active, created_at " +
                "FROM   suppliers " +
                "WHERE  is_active = true " +
                "ORDER  BY name ASC";

            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
        return list;
    }

    /**
     * Returns a single supplier by ID.
     * Used when opening the edit form.
     * Returns null if no supplier found with that ID.
     */
    public Supplier getSupplierById(int id) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();
            String sql =
                "SELECT id, name, contact_name, phone, email, address, is_active, created_at " +
                "FROM   suppliers WHERE id = ?";

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
     * Total count of active suppliers.
     * Used by the dashboard KPI card.
     */
    public int getActiveSupplierCount() throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM suppliers WHERE is_active = true");
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
     * Inserts a new supplier row.
     * RETURNING id -> PostgreSQL gives back the new SERIAL id immediately.
     * Returns the generated id, or -1 on failure.
     */
    public int createSupplier(Supplier s) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();
            String sql =
                "INSERT INTO suppliers (name, contact_name, phone, email, address) " +
                "VALUES (?, ?, ?, ?, ?) RETURNING id";

            ps = conn.prepareStatement(sql);
            ps.setString(1, s.getName());
            ps.setString(2, nullIfBlank(s.getContactName()));
            ps.setString(3, nullIfBlank(s.getPhone()));
            ps.setString(4, nullIfBlank(s.getEmail()));
            ps.setString(5, nullIfBlank(s.getAddress()));

            rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : -1;

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    /**
     * Updates an existing supplier row.
     * Returns rows affected (1 = success, 0 = id not found).
     */
    public int updateSupplier(Supplier s) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;

        try {
            conn = DatabaseUtil.getConnection();
            String sql =
                "UPDATE suppliers " +
                "SET    name = ?, contact_name = ?, phone = ?, email = ?, address = ? " +
                "WHERE  id = ?";

            ps = conn.prepareStatement(sql);
            ps.setString(1, s.getName());
            ps.setString(2, nullIfBlank(s.getContactName()));
            ps.setString(3, nullIfBlank(s.getPhone()));
            ps.setString(4, nullIfBlank(s.getEmail()));
            ps.setString(5, nullIfBlank(s.getAddress()));
            ps.setInt(6,    s.getId());

            return ps.executeUpdate();

        } finally {
            DatabaseUtil.close(null, ps, conn);
        }
    }

    /**
     * Soft-delete: sets is_active = false instead of hard delete.
     * Products reference suppliers via supplier_id - hard delete would
     * break referential integrity or orphan product records.
     * Returns rows affected (1 = success).
     */
    public int deleteSupplier(int id) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;

        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "UPDATE suppliers SET is_active = false WHERE id = ?");
            ps.setInt(1, id);
            return ps.executeUpdate();

        } finally {
            DatabaseUtil.close(null, ps, conn);
        }
    }

    // ══════════════════════════════════════════════════════════
    // VALIDATION HELPERS
    // ══════════════════════════════════════════════════════════

    /**
     * Checks if an email already exists in the suppliers table.
     * Pass excludeId = 0 when creating a new supplier.
     * Pass the supplier's own id when editing (so it ignores itself).
     * Returns false automatically if email is blank (email is optional).
     */
    public boolean emailExists(String email, int excludeId) throws SQLException {
        if (email == null || email.isBlank()) return false;

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM suppliers WHERE email = ? AND id != ?");
            ps.setString(1, email.trim().toLowerCase());
            ps.setInt(2, excludeId);
            rs = ps.executeQuery();
            return rs.next() && rs.getInt(1) > 0;

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }

    /**
     * Returns true if this supplier has at least one active product linked to them.
     * Used before deletion to warn the user that products will lose their supplier.
     */
    public boolean hasActiveProducts(int supplierId) throws SQLException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DatabaseUtil.getConnection();
            ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM products " +
                "WHERE  supplier_id = ? AND is_active = true");
            ps.setInt(1, supplierId);
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
     * Maps one ResultSet row -> one Supplier object.
     * Called from every SELECT query to avoid writing the same code repeatedly.
     * Note: product_count column is NOT mapped here - set it separately
     *       because not all queries include it.
     */
    private Supplier mapRow(ResultSet rs) throws SQLException {
        Supplier s = new Supplier();
        s.setId(rs.getInt("id"));
        s.setName(rs.getString("name"));
        s.setContactName(rs.getString("contact_name"));
        s.setPhone(rs.getString("phone"));
        s.setEmail(rs.getString("email"));
        s.setAddress(rs.getString("address"));
        s.setActive(rs.getBoolean("is_active"));

        Timestamp created = rs.getTimestamp("created_at");
        if (created != null) s.setCreatedAt(created.toLocalDateTime());

        return s;
    }

    /**
     * Returns null if the string is blank/null.
     * PostgreSQL stores NULL for optional fields - cleaner than empty string "".
     */
    private String nullIfBlank(String s) {
        return (s == null || s.isBlank()) ? null : s.trim();
    }
}
