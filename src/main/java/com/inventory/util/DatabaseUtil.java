package com.inventory.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * DatabaseUtil - PostgreSQL edition
 * ----------------------------------
 * Single class that manages all database connections.
 */
public class DatabaseUtil {

    // ── Configuration using Environment Variables with fallbacks ────
    private static final String HOST     = getEnvOrDefault("DB_HOST", "localhost");
    private static final String PORT     = getEnvOrDefault("DB_PORT", "5432");
    private static final String DB_NAME  = getEnvOrDefault("DB_NAME", "inventory_db");
    private static final String USERNAME = getEnvOrDefault("DB_USER", "postgres");
    private static final String PASSWORD = getEnvOrDefault("DB_PASSWORD", "3693");
    private static final String SSL_MODE = getEnvOrDefault("DB_SSLMODE", "prefer");

    private static final String URL =
        "jdbc:postgresql://" + HOST + ":" + PORT + "/" + DB_NAME
        + "?currentSchema=public"
        + "&reWriteBatchedInserts=true"
        + "&sslmode=" + SSL_MODE;

    private static String getEnvOrDefault(String key, String fallback) {
        String value = System.getenv(key);
        return (value != null && !value.trim().isEmpty()) ? value : fallback;
    }

    // Load the PostgreSQL JDBC driver once when the class is first used
    static {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(
                "PostgreSQL JDBC Driver not found.\n" +
                "Download postgresql-42.x.x.jar from https://jdbc.postgresql.org/download/\n" +
                "and place it in WEB-INF/lib/", e);
        }
    }

    /**
     * Opens and returns a fresh PostgreSQL connection.
     */
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USERNAME, PASSWORD);
    }

    /**
     * Safely closes any combination of Connection, Statement,
     * PreparedStatement, and ResultSet.
     */
    public static void close(AutoCloseable... resources) {
        for (AutoCloseable resource : resources) {
            if (resource != null) {
                try {
                    resource.close();
                } catch (Exception e) {
                    System.err.println("Warning: could not close DB resource - " + e.getMessage());
                }
            }
        }
    }

    /**
     * Quick test - call this from a JSP or servlet to verify the connection works.
     */
    public static boolean testConnection() {
        try (Connection conn = getConnection()) {
            return conn != null && !conn.isClosed();
        } catch (SQLException e) {
            System.err.println("PostgreSQL connection test FAILED: " + e.getMessage());
            return false;
        }
    }
}