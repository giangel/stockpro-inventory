package com.inventory.servlet;


import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * LogoutServlet
 * Invalidates the HTTP session (logs the user out) and
 * redirects them to the login page.
 *
 * The sidebar logout link should point to:
 *   href="<%= request.getContextPath() %>/logout"
 */
@WebServlet("/logout")
public class LogoutServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false); // false = don't create new session
        if (session != null) {
            session.invalidate(); // wipes all session attributes
        }

        resp.sendRedirect(req.getContextPath() + "/login");
    }
}
