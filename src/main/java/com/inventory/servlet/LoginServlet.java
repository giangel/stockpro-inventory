package com.inventory.servlet;

import com.inventory.model.User;
import com.inventory.util.DatabaseUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

/**
 * LoginServlet - PostgreSQL edition
 * -----------------------------------
 * GET  /login  -> shows login.jsp
 * POST /login  -> validates credentials against PostgreSQL, creates session
 */
@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    // ── GET: show the login page ──────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // If already logged in, skip the login page and route through the DashboardServlet
        HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute("loggedInUser") != null) {
            resp.sendRedirect(req.getContextPath() + "/dashboard");
            return;
        }

        req.getRequestDispatcher("/login.jsp").forward(req, resp);
    }

    // ── POST: validate credentials ────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // 1. Read form fields (trim whitespace)
        String username = req.getParameter("username");
        String password = req.getParameter("password");

        // 2. Guard against blank submissions
        if (username == null || username.trim().isEmpty()
         || password == null || password.trim().isEmpty()) {
            req.setAttribute("errorMessage", "Username and password are required.");
            req.getRequestDispatcher("/login.jsp").forward(req, resp);
            return;
        }

        username = username.trim();

        // 3. Query PostgreSQL
        Connection        conn = null;
        PreparedStatement ps   = null;
        ResultSet         rs   = null;

        try {
            conn = DatabaseUtil.getConnection();

            String sql =
                "SELECT id, full_name, username, password, role, is_active " +
                "FROM users " +
                "WHERE username = ? AND is_active = true";

            ps = conn.prepareStatement(sql);
            ps.setString(1, username);
            rs = ps.executeQuery();

            if (rs.next()) {
                String storedPassword = rs.getString("password");

                // 4. Password check
                if (storedPassword.equals(password)) {

                    // 5. Map ResultSet row -> User object
                    User user = new User();
                    user.setId(rs.getInt("id"));
                    user.setFullName(rs.getString("full_name"));
                    user.setUsername(rs.getString("username"));
                    user.setRole(rs.getString("role"));
                    user.setActive(rs.getBoolean("is_active"));

                    // 6. Create session and store user
                    HttpSession session = req.getSession(true);
                    session.setAttribute("loggedInUser", user);
                    session.setAttribute("username",     user.getUsername());
                    session.setAttribute("userFullName", user.getFullName());
                    session.setAttribute("userRole",     user.getRole());

                    // 7. Redirect to the Dashboard Servlet controller
                    // Changing this from /dashboard.jsp to /dashboard runs the DB query logic first!
                    resp.sendRedirect(req.getContextPath() + "/dashboard");

                } else {
                    req.setAttribute("errorMessage", "Invalid username or password.");
                    req.getRequestDispatcher("/login.jsp").forward(req, resp);
                }

            } else {
                req.setAttribute("errorMessage", "Invalid username or password.");
                req.getRequestDispatcher("/login.jsp").forward(req, resp);
            }

        } catch (Exception e) {
            e.printStackTrace();
            req.setAttribute("errorMessage",
                "Database error: " + e.getMessage() + ". Check your PostgreSQL connection.");
            req.getRequestDispatcher("/login.jsp").forward(req, resp);

        } finally {
            DatabaseUtil.close(rs, ps, conn);
        }
    }
}