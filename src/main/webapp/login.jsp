<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>StockPro - Sign In</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<%
    if (com.inventory.util.DatabaseUtil.testConnection()) {
        System.out.println("====== DATABASE CONNECTION SUCCESSFUL! ======");
    } else {
        System.out.println("====== DATABASE CONNECTION FAILED! ======");
    }
%>

<style>
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

body {
    font-family: 'Inter', -apple-system, sans-serif;
    background: #f1f5f9;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
}

.login-wrapper {
    display: flex;
    width: 860px;
    min-height: 520px;
    background: #fff;
    border-radius: 18px;
    overflow: hidden;
    border: 1px solid #e2e8f0;
    box-shadow: 0 8px 40px rgba(0,0,0,.06);
}

/* ── Left branding panel ── */
.brand-panel {
    width: 340px;
    background: #0f172a;
    padding: 44px 38px;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    flex-shrink: 0;
}
.brand-logo {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 44px;
}
.brand-logo-box {
    width: 40px;
    height: 40px;
    background: #2563eb;
    border-radius: 11px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
}
.brand-logo-box i { color: #fff; font-size: 18px; }
.brand-name { font-size: 19px; font-weight: 700; color: #fff; line-height: 1.1; }
.brand-name small { display: block; font-size: 11px; color: #475569; font-weight: 400; margin-top: 3px; }

.brand-tagline {
    font-size: 24px;
    font-weight: 700;
    color: #fff;
    line-height: 1.35;
    margin-bottom: 14px;
    letter-spacing: -0.01em;
}
.brand-sub {
    font-size: 13px;
    color: #64748b;
    line-height: 1.65;
    margin-bottom: 36px;
}

.brand-features { display: flex; flex-direction: column; gap: 11px; }
.brand-feature {
    display: flex;
    align-items: center;
    gap: 10px;
    font-size: 12.5px;
    color: #94a3b8;
}
.feature-icon {
    width: 26px;
    height: 26px;
    background: rgba(37,99,235,.2);
    border-radius: 7px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 11px;
    color: #60a5fa;
    flex-shrink: 0;
}

/* PostgreSQL badge */
.db-badge {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    background: rgba(52,211,153,.1);
    border: 1px solid rgba(52,211,153,.2);
    border-radius: 20px;
    padding: 4px 11px;
    font-size: 11px;
    font-weight: 600;
    color: #34d399;
    margin-top: 20px;
}
.db-dot { width: 6px; height: 6px; border-radius: 50%; background: #34d399; }

.brand-footer { font-size: 11px; color: #334155; }

/* ── Right form panel ── */
.form-panel {
    flex: 1;
    padding: 52px 46px;
    display: flex;
    flex-direction: column;
    justify-content: center;
}

.form-heading {
    font-size: 22px;
    font-weight: 700;
    color: #0f172a;
    margin-bottom: 5px;
    letter-spacing: -0.01em;
}
.form-sub {
    font-size: 13px;
    color: #64748b;
    margin-bottom: 28px;
}

/* Error alert */
.alert-error {
    background: #fef2f2;
    border: 1px solid #fecaca;
    border-radius: 10px;
    padding: 11px 15px;
    font-size: 13px;
    color: #dc2626;
    display: flex;
    align-items: center;
    gap: 9px;
    margin-bottom: 18px;
}

/* Form fields */
.form-group { margin-bottom: 17px; }
.form-label {
    display: block;
    font-size: 12.5px;
    font-weight: 600;
    color: #374151;
    margin-bottom: 7px;
}
.input-wrap { position: relative; }
.input-icon {
    position: absolute;
    left: 13px;
    top: 50%;
    transform: translateY(-50%);
    color: #9ca3af;
    font-size: 14px;
    pointer-events: none;
}
.form-input {
    width: 100%;
    height: 44px;
    padding: 0 40px 0 38px;
    border: 1px solid #d1d5db;
    border-radius: 10px;
    font-size: 13.5px;
    font-family: 'Inter', sans-serif;
    color: #0f172a;
    background: #f9fafb;
    transition: border-color .15s, background .15s, box-shadow .15s;
    outline: none;
}
.form-input:focus {
    border-color: #2563eb;
    background: #fff;
    box-shadow: 0 0 0 3px rgba(37,99,235,.1);
}
.form-input::placeholder { color: #9ca3af; }

/* Show/hide password toggle */
.pw-toggle {
    position: absolute;
    right: 12px;
    top: 50%;
    transform: translateY(-50%);
    background: none;
    border: none;
    cursor: pointer;
    color: #9ca3af;
    font-size: 14px;
    padding: 0;
    transition: color .12s;
}
.pw-toggle:hover { color: #374151; }

/* Remember me row */
.form-check {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 22px;
}
.form-check input[type="checkbox"] {
    width: 16px;
    height: 16px;
    accent-color: #2563eb;
    cursor: pointer;
}
.form-check label { font-size: 12.5px; color: #64748b; cursor: pointer; }

/* Submit button */
.btn-login {
    width: 100%;
    height: 46px;
    background: #2563eb;
    color: #fff;
    border: none;
    border-radius: 10px;
    font-size: 14px;
    font-weight: 600;
    font-family: 'Inter', sans-serif;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    transition: background .13s, transform .1s;
}
.btn-login:hover  { background: #1d4ed8; }
.btn-login:active { transform: scale(0.99); }
.btn-login:disabled { background: #93c5fd; cursor: not-allowed; }

/* Dev credentials hint */
.demo-hint {
    margin-top: 18px;
    background: #f0fdf4;
    border: 1px solid #bbf7d0;
    border-radius: 10px;
    padding: 11px 15px;
    font-size: 12px;
    color: #065f46;
    text-align: center;
    line-height: 1.6;
}

/* Responsive */
@media (max-width: 680px) {
    .login-wrapper { flex-direction: column; width: 100%; min-height: unset; }
    .brand-panel   { width: 100%; padding: 28px 24px; }
    .brand-tagline { font-size: 19px; }
    .form-panel    { padding: 28px 24px; }
}
</style>
</head>
<body>

<div class="login-wrapper">

    <!-- ── Left: branding ─────────────────────────────── -->
    <div class="brand-panel">
        <div>
            <div class="brand-logo">
                <div class="brand-logo-box"><i class="fas fa-cubes"></i></div>
                <div class="brand-name">StockPro <small>SME Inventory Hub</small></div>
            </div>

            <div class="brand-tagline">Smart inventory for Nigerian businesses</div>
            <div class="brand-sub">
                Track stock, process sales, and get real-time reports - all in one place.
            </div>

            <div class="brand-features">
                <div class="brand-feature">
                    <div class="feature-icon"><i class="fas fa-box"></i></div>
                    Real-time stock tracking
                </div>
                <div class="brand-feature">
                    <div class="feature-icon"><i class="fas fa-chart-line"></i></div>
                    Sales analytics &amp; reports
                </div>
                <div class="brand-feature">
                    <div class="feature-icon"><i class="fas fa-bell"></i></div>
                    Automatic low stock alerts
                </div>
                <div class="brand-feature">
                    <div class="feature-icon"><i class="fas fa-receipt"></i></div>
                    Instant printable receipts
                </div>
            </div>

            <div class="db-badge">
                <span class="db-dot"></span>
                PostgreSQL database
            </div>
        </div>

        <div class="brand-footer">&copy; 2025 StockPro - Built for Nigerian SMEs</div>
    </div>

    <!-- ── Right: login form ──────────────────────────── -->
    <div class="form-panel">
        <div class="form-heading">Welcome back</div>
        <div class="form-sub">Sign in to access your inventory dashboard</div>

        <%-- Error message set by LoginServlet on failed login --%>
        <%
            String errorMsg = (String) request.getAttribute("errorMessage");
            if (errorMsg != null && !errorMsg.isEmpty()) {
        %>
        <div class="alert-error">
            <i class="fas fa-circle-exclamation"></i>
            <%= errorMsg %>
        </div>
        <% } %>

        <form action="<%= request.getContextPath() %>/login" method="POST" id="loginForm">

            <div class="form-group">
                <label class="form-label" for="username">Username</label>
                <div class="input-wrap">
                    <i class="fas fa-user input-icon"></i>
                    <input
                        type="text"
                        id="username"
                        name="username"
                        class="form-input"
                        placeholder="Enter your username"
                        autocomplete="username"
                        required
                        value="<%= request.getParameter("username") != null
                                    ? request.getParameter("username") : "" %>"
                    >
                </div>
            </div>

            <div class="form-group">
                <label class="form-label" for="password">Password</label>
                <div class="input-wrap">
                    <i class="fas fa-lock input-icon"></i>
                    <input
                        type="password"
                        id="password"
                        name="password"
                        class="form-input"
                        placeholder="Enter your password"
                        autocomplete="current-password"
                        required
                    >
                    <button type="button" class="pw-toggle" id="pwToggle" title="Show / hide password">
                        <i class="fas fa-eye" id="eyeIcon"></i>
                    </button>
                </div>
            </div>

            <div class="form-check">
                <input type="checkbox" id="rememberMe" name="rememberMe">
                <label for="rememberMe">Keep me signed in</label>
            </div>

            <button type="submit" class="btn-login" id="submitBtn">
                <i class="fas fa-arrow-right-to-bracket"></i>
                Sign in to dashboard
            </button>

        </form>

        <%-- Remove this block before going to production --%>
        <div class="demo-hint">
            <strong>Default credentials</strong><br>
            Username: <strong>admin</strong> &nbsp;&bull;&nbsp; Password: <strong>admin123</strong>
        </div>

    </div>
</div>

<script>
document.getElementById('pwToggle').addEventListener('click', function () {
    var pw   = document.getElementById('password');
    var icon = document.getElementById('eyeIcon');
    if (pw.type === 'password') {
        pw.type        = 'text';
        icon.className = 'fas fa-eye-slash';
    } else {
        pw.type        = 'password';
        icon.className = 'fas fa-eye';
    }
});

document.getElementById('loginForm').addEventListener('submit', function () {
    var btn = document.getElementById('submitBtn');
    btn.disabled  = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>&nbsp; Signing in&hellip;';
});
</script>

</body>
</html>
