package com.inventory.filter;

import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * AuthFilter
 * ----------
 * Runs before EVERY request to the application.
 * If the user is not logged in, they are sent to the login page.
 * This protects dashboard.jsp, products.jsp, and every other page.
 *
 * Public URLs (no login required):
 *   /login      the login page and servlet
 *   /logout     the logout servlet
 *   /assets/    CSS, JS, image files
 */
@WebFilter("/*")
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  req  = (HttpServletRequest)  request;
        HttpServletResponse resp = (HttpServletResponse) response;

        String uri = req.getRequestURI();
        String ctx = req.getContextPath();

        // ── Allow public resources through without login ──────
        boolean isPublic =
               uri.equals(ctx + "/login")
            || uri.equals(ctx + "/login.jsp")
            || uri.startsWith(ctx + "/logout")
            || uri.startsWith(ctx + "/assets/")
            || uri.endsWith(".css")
            || uri.endsWith(".js")
            || uri.endsWith(".png")
            || uri.endsWith(".jpg")
            || uri.endsWith(".ico")
            || uri.endsWith(".woff2")
            || uri.endsWith(".woff");

        if (isPublic) {
            chain.doFilter(request, response);
            return;
        }

        // ── Check session for logged-in user ──────────────────
        HttpSession session = req.getSession(false);
        boolean     loggedIn = (session != null)
                            && (session.getAttribute("loggedInUser") != null);

        if (loggedIn) {
            chain.doFilter(request, response); // authenticated - continue
        } else {
            resp.sendRedirect(ctx + "/login"); // not authenticated - redirect
        }
    }

    @Override public void init(FilterConfig fc) {}
    @Override public void destroy() {}
}
