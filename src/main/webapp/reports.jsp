<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.util.List, java.util.Map, java.math.BigDecimal, com.inventory.model.Product" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core"      prefix="c"   %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"       prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"  %>
<%
    if (request.getAttribute("salesSummary") == null) {
        response.sendRedirect(request.getContextPath() + "/reports");
        return;
    }
%>
<%--
==========================================================================
  reports.jsp  -  Jare Pharmacy Inventory System
==========================================================================
  REQUIRES: ReportServlet to have run first (URL: /reports)
  DO NOT access this JSP directly via reports.jsp - always go via /reports

  Request attributes expected (all set by ReportServlet):
    salesSummary       Map<String,Object>  (totalSales, totalRevenue, avgOrderValue,
                                             totalProfit, totalItemsSold, refundedCount, voidCount)
    topProducts        List<Map<String,Object>> (productName, totalQty, totalRevenue, totalProfit)
    dailyTrend         List<Map<String,Object>> (date, salesCount, revenue, profit)
    paymentBreakdown   List<Map<String,Object>> (paymentMethod, salesCount, revenue)
    inventoryValue     BigDecimal
    lowStockProducts   List<Product>
    lowStockCount      int
    fromDate / toDate               String (yyyy-MM-dd, for the filter form)
    fromDateDisplay / toDateDisplay String (dd MMM yyyy, for headings)
==========================================================================
--%>
<%
    com.inventory.model.User sessionUser =
        (com.inventory.model.User) session.getAttribute("loggedInUser");
    String userFullName = sessionUser != null ? sessionUser.getFullName() : "Admin";
    String userRole      = sessionUser != null ? sessionUser.getRole()      : "";

    String initials = "AD";
    if (userFullName != null && userFullName.trim().length() > 0) {
        String[] parts = userFullName.trim().split("\\s+");
        initials = parts.length > 1
            ? ("" + parts[0].charAt(0) + parts[1].charAt(0)).toUpperCase()
            : userFullName.substring(0, Math.min(2, userFullName.length())).toUpperCase();
    }

    String ctx = request.getContextPath();

    Map<String, Object> salesSummary = (Map<String, Object>) request.getAttribute("salesSummary");
    if (salesSummary == null) salesSummary = new java.util.LinkedHashMap<>();

    Integer lowStockCount = (Integer) request.getAttribute("lowStockCount");
    if (lowStockCount == null) lowStockCount = 0;

    List<Map<String, Object>> dailyTrend = (List<Map<String, Object>>) request.getAttribute("dailyTrend");
    StringBuilder labelsJson  = new StringBuilder("[");
    StringBuilder revenueJson = new StringBuilder("[");
    if (dailyTrend != null) {
        for (int i = 0; i < dailyTrend.size(); i++) {
            Map<String, Object> row = dailyTrend.get(i);
            if (i > 0) { labelsJson.append(","); revenueJson.append(","); }
            labelsJson.append("\"").append(row.get("date")).append("\"");
            BigDecimal rev = (BigDecimal) row.get("revenue");
            revenueJson.append(rev != null ? rev.toPlainString() : "0");
        }
    }
    labelsJson.append("]");
    revenueJson.append("]");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Jare Pharmacy | Reports</title>

<!-- Google Font: Inter -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<!-- AdminLTE 3 -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">

<!-- DataTables -->
<link rel="stylesheet" href="https://cdn.datatables.net/1.13.4/css/dataTables.bootstrap4.min.css">
<link rel="stylesheet" href="https://cdn.datatables.net/responsive/2.4.1/css/responsive.bootstrap4.min.css">

<!-- SweetAlert2 -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css">

<style>
/* ================================================================
   DESIGN TOKENS - identical to dashboard.jsp / categories.jsp
================================================================ */
:root {
    --blue:        #2563eb;
    --blue-light:  #eff6ff;
    --blue-mid:    #dbeafe;
    --slate-900:   #0f172a;
    --slate-700:   #374151;
    --slate-500:   #64748b;
    --slate-400:   #94a3b8;
    --slate-300:   #cbd5e1;
    --slate-200:   #e2e8f0;
    --slate-100:   #f1f5f9;
    --slate-50:    #f8fafc;
    --green:       #059669;
    --green-mid:   #bbf7d0;
    --amber:       #d97706;
    --amber-light: #fffbeb;
    --red:         #dc2626;
    --page-bg:     #f1f5f9;
    --border:      #e2e8f0;
    --border-soft: #f1f5f9;
    --radius-sm:   6px;
    --radius-md:   10px;
    --radius-lg:   12px;
    --shadow-md:   0 4px 12px rgba(0,0,0,.08);
}

*, *::before, *::after { box-sizing: border-box; }

body,.content-wrapper,.main-sidebar,.main-header,.main-footer{
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif !important;
}
body { font-size: 13px !important; }

/* ── SIDEBAR (pixel-perfect match with dashboard.jsp) ─────────── */
.main-sidebar { background: var(--slate-900) !important; box-shadow: none !important; border-right: none !important; width: 230px !important; }
.brand-link { background: var(--slate-900) !important; border-bottom: 1px solid rgba(255,255,255,.06) !important; padding: 16px !important; display:flex; align-items: center !important; text-decoration: none !important; }
.brand-logo-box { width:32px; height:32px; background: var(--blue); border-radius: 9px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.brand-logo-box i { color: #fff; font-size: 15px; }
.brand-text-wrap { margin-left: 10px; }
.brand-name { font-size: 15px; font-weight: 700; color: #fff; letter-spacing: -.01em; display: block; }
.brand-sub  { font-size: 10.5px; color: var(--slate-400); display: block; margin-top: 1px; }
.user-panel { background: transparent !important; border-bottom: 1px solid rgba(255,255,255,.06) !important; padding: 12px 16px !important; display: flex; align-items: center; gap: 10px; }
.sidebar-user-avatar { width: 32px; height: 32px; border-radius: 50%; background: #1e3a8a; display: flex; align-items: center; justify-content: center; font-size:12px; font-weight:700; color: #bfdbfe; flex-shrink: 0; }
.user-panel .info a { color: var(--slate-300) !important; font-size: 12.5px !important; font-weight: 600 !important; text-decoration: none !important; display: block; }
.user-panel .info small { color: var(--slate-500) !important; font-size: 10.5px !important; }

.nav-sidebar .nav-header{font-size:9.5px!important;font-weight:700!important;letter-spacing:.08em!important;color:#334155!important;text-transform:uppercase!important;padding:14px 16px 4px!important}
.nav-sidebar .nav-item .nav-link{color:#94a3b8!important;border-radius:8px!important;margin:1px 8px!important;padding:9px 12px!important;font-size:12.5px!important;font-weight:400!important;border-left:2px solid transparent!important;display:flex!important;align-items:center!important;gap:9px!important;transition:all .12s ease!important}
.nav-sidebar .nav-item .nav-link:hover{background:rgba(255,255,255,.05)!important;color:#e2e8f0!important}
.nav-sidebar .nav-item .nav-link.active{background:rgba(37,99,235,.18)!important;color:#60a5fa!important;border-left-color:#2563eb!important}
.nav-sidebar .nav-link .nav-icon{font-size:14px!important;width:16px!important;text-align:center;flex-shrink:0}
.nav-sidebar .nav-link p{margin:0!important;font-size:12.5px!important;line-height:1!important}
.nav-alert-badge{background:var(--red);color:#fff;font-size:9.5px;font-weight:700;border-radius:10px;padding:1px 6px;margin-left:6px}

.content-wrapper{background:#f1f5f9!important;padding:0!important}

/* ── TOPBAR ─────────────────────────────────────────────────── */
.topbar-breadcrumb{font-size:12px;color:var(--slate-500);display:flex;align-items:center;gap:6px;margin-left:8px}
.crumb-active{color:var(--slate-900);font-weight:600}
.live-badge{display:flex;align-items:center;gap:6px;background:var(--blue-light);color:var(--blue);font-size:11px;font-weight:600;padding:5px 10px;border-radius:20px}
.live-dot{width:6px;height:6px;border-radius:50%;background:var(--green);animation:pulse 1.8s infinite}
@keyframes pulse{0%{opacity:1}50%{opacity:.35}100%{opacity:1}}
.topbar-avatar{width:30px;height:30px;border-radius:50%;background:var(--blue);color:#fff;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700}
.topbar-user-wrap{display:flex;align-items:center;gap:8px}
.topbar-user-name{font-size:12.5px;font-weight:600;color:var(--slate-900);line-height:1.1}
.topbar-user-role{font-size:10.5px;color:var(--slate-400)}

/* ── PAGE ───────────────────────────────────────────────────── */
.page-content{padding:20px 24px 32px}
.page-heading{display:flex;align-items:center;justify-content:space-between;margin-bottom:18px;flex-wrap:wrap;gap:12px}
.page-title{font-size:20px;font-weight:700;color:var(--slate-900);letter-spacing:-.01em;margin:0}
.page-subtitle{font-size:12.5px;color:var(--slate-500);margin-top:2px}

/* ── FILTER BAR ─────────────────────────────────────────────── */
.filter-bar{background:#fff;border:1px solid var(--border);border-radius:var(--radius-lg);padding:14px 18px;margin-bottom:18px;display:flex;align-items:flex-end;gap:14px;flex-wrap:wrap}
.filter-field label{font-size:10.5px;font-weight:700;color:var(--slate-500);text-transform:uppercase;letter-spacing:.04em;margin-bottom:5px;display:block}
.filter-field input{border:1px solid var(--border);border-radius:var(--radius-sm);padding:7px 10px;font-size:12.5px;color:var(--slate-900)}
.filter-field input:focus{outline:none;border-color:var(--blue);box-shadow:0 0 0 3px var(--blue-light)}
.btn-apply{background:var(--blue);color:#fff;border:none;border-radius:var(--radius-sm);padding:8px 16px;font-size:12.5px;font-weight:600;cursor:pointer}
.btn-apply:hover{background:#1d4ed8;color:#fff}
.quick-range{display:flex;gap:6px;flex-wrap:wrap}
.quick-range a{font-size:11.5px;color:var(--slate-500);background:var(--slate-100);border-radius:20px;padding:5px 12px;text-decoration:none;font-weight:500}
.quick-range a:hover{background:var(--blue-light);color:var(--blue)}

/* ── SUMMARY STRIP ──────────────────────────────────────────── */
.summary-strip{display:flex;background:#fff;border:1px solid #e2e8f0;border-radius:12px;overflow:hidden;margin-bottom:18px;flex-wrap:wrap}
.summary-item{flex:1;min-width:150px;text-align:center;padding:16px;border-right:1px solid #f1f5f9}
.summary-item:last-child{border-right:none}
.summary-val{font-size:21px;font-weight:700;color:#0f172a;letter-spacing:-.01em}
.summary-lbl{font-size:10.5px;color:#94a3b8;margin-top:3px;text-transform:uppercase;letter-spacing:.05em}
.summary-val.green{color:var(--green)} .summary-val.amber{color:var(--amber)} .summary-val.red{color:var(--red)}

/* ── CARDS ──────────────────────────────────────────────────── */
.report-grid{display:grid;grid-template-columns:1.4fr 1fr;gap:18px;margin-bottom:18px}
@media(max-width:992px){.report-grid{grid-template-columns:1fr}}
.card-panel{background:#fff;border:1px solid var(--border);border-radius:var(--radius-lg);padding:18px;box-shadow:var(--shadow-md)}
.card-panel h3{font-size:13.5px;font-weight:700;color:var(--slate-900);margin:0 0 14px}
.card-panel h3 i{color:var(--blue);margin-right:6px}

table.report-table{width:100%;border-collapse:collapse;font-size:12.5px}
table.report-table th{text-align:left;color:var(--slate-500);font-size:10.5px;text-transform:uppercase;letter-spacing:.04em;font-weight:700;padding:8px 6px;border-bottom:1px solid var(--border)}
table.report-table td{padding:9px 6px;border-bottom:1px solid var(--border-soft);color:var(--slate-900)}
table.report-table tr:last-child td{border-bottom:none}
.rank-badge{display:inline-flex;align-items:center;justify-content:center;width:20px;height:20px;border-radius:50%;background:var(--blue-light);color:var(--blue);font-size:10.5px;font-weight:700}
.empty-state{text-align:center;padding:28px 16px;color:#94a3b8;font-size:12px}
.empty-state i{font-size:28px;display:block;margin-bottom:8px;color:#e2e8f0}

.low-badge{background:var(--amber-light);color:var(--amber);font-size:10px;font-weight:700;padding:2px 8px;border-radius:20px}
.out-badge{background:#fef2f2;color:var(--red);font-size:10px;font-weight:700;padding:2px 8px;border-radius:20px}

.main-footer{background:#fff!important;border-top:1px solid #e2e8f0!important;padding:12px 24px!important;font-size:11.5px!important;color:#94a3b8!important;text-align:center!important}

@media(max-width:768px){
    .page-heading{flex-direction:column;align-items:flex-start}
    .summary-strip{flex-wrap:wrap}
    .summary-item{min-width:50%;border-bottom:1px solid #f1f5f9}
}
</style>
</head>

<body class="hold-transition sidebar-mini layout-fixed layout-navbar-fixed">
<div class="wrapper">

<!-- ================================================================
     TOPBAR
================================================================ -->
<nav class="main-header navbar navbar-expand navbar-white navbar-light">
    <ul class="navbar-nav align-items-center">
        <li class="nav-item">
            <a class="nav-link px-2" data-widget="pushmenu" href="#" role="button">
                <i class="fas fa-bars" style="color:#64748b;font-size:16px"></i>
            </a>
        </li>
        <li class="nav-item d-none d-sm-flex align-items-center">
            <div class="topbar-breadcrumb">
                <i class="fas fa-home" style="font-size:12px"></i>
                <span style="color:#cbd5e1">/</span>
                <span class="crumb-active">Reports</span>
            </div>
        </li>
    </ul>
    <ul class="navbar-nav ml-auto align-items-center" style="gap:12px">
        <li class="nav-item d-none d-md-flex">
            <div class="live-badge">
                <div class="live-dot"></div>
                PostgreSQL connected
            </div>
        </li>
        <li class="nav-item dropdown">
            <a href="#" class="nav-link p-0" data-toggle="dropdown">
                <div class="topbar-user-wrap">
                    <div class="topbar-avatar"><%= initials %></div>
                    <div class="d-none d-sm-block">
                        <div class="topbar-user-name"><%= userFullName %></div>
                        <div class="topbar-user-role"><%= userRole %></div>
                    </div>
                    <i class="fas fa-chevron-down ml-1" style="font-size:10px;color:#94a3b8"></i>
                </div>
            </a>
            <div class="dropdown-menu dropdown-menu-right border-0"
                 style="box-shadow:0 8px 24px rgba(0,0,0,.12);min-width:180px;margin-top:6px;border-radius:12px">
                <div class="dropdown-header py-2 px-3"
                     style="font-size:11px;color:#94a3b8;font-weight:700;text-transform:uppercase">
                    My Account
                </div>
                <div class="dropdown-divider m-0"></div>
                <a href="<%= ctx %>/logout" class="dropdown-item py-2"
                   style="font-size:13px;color:#dc2626">
                    <i class="fas fa-sign-out-alt mr-2" style="width:16px"></i>Sign out
                </a>
            </div>
        </li>
    </ul>
</nav>

<!-- ================================================================
     SIDEBAR
================================================================ -->
<aside class="main-sidebar elevation-0">
    <a href="<%= ctx %>/dashboard" class="brand-link">
        <div class="brand-logo-box"><i class="fas fa-cubes"></i></div>
        <div class="brand-text-wrap">
            <span class="brand-name">Jare Pharmacy</span>
            <span class="brand-sub">SME Inventory Hub</span>
        </div>
    </a>
    <div class="sidebar">
        <div class="user-panel mt-2 mb-2">
            <div class="sidebar-user-avatar"><%= initials %></div>
            <div class="info">
                <a href="#"><%= userFullName %></a>
                <small><%= userRole %></small>
            </div>
        </div>
        <nav class="mt-1">
            <ul class="nav nav-pills nav-sidebar flex-column" data-widget="treeview" role="menu">
                <li class="nav-header">Main</li>
                <li class="nav-item">
                    <a href="<%= ctx %>/dashboard" class="nav-link">
                        <i class="nav-icon fas fa-tachometer-alt"></i><p>Dashboard</p>
                    </a>
                </li>
                <li class="nav-header">Catalogue</li>
                <li class="nav-item">
                    <a href="<%= ctx %>/products?action=list" class="nav-link">
                        <i class="nav-icon fas fa-box-open"></i><p>Products</p>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="<%= ctx %>/categories?action=list" class="nav-link">
                        <i class="nav-icon fas fa-tags"></i><p>Categories</p>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="<%= ctx %>/suppliers?action=list" class="nav-link">
                        <i class="nav-icon fas fa-truck"></i><p>Suppliers</p>
                    </a>
                </li>
                <li class="nav-header">Operations</li>
                <li class="nav-item">
                    <a href="<%= ctx %>/sales?action=pos" class="nav-link">
                        <i class="nav-icon fas fa-cash-register" style="color:#10b981"></i>
                        <p>Point of Sale</p>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="<%= ctx %>/inventory?action=list" class="nav-link">
                        <i class="nav-icon fas fa-warehouse"></i>
                        <p>Inventory
                            <% if (lowStockCount > 0) { %>
                            <span class="nav-alert-badge"><%= lowStockCount %></span>
                            <% } %>
                        </p>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="<%= ctx %>/reports" class="nav-link active">
                        <i class="nav-icon fas fa-chart-bar"></i><p>Reports</p>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="<%= ctx %>/logout" class="nav-link"
                       style="color:#ef4444!important">
                        <i class="nav-icon fas fa-sign-out-alt"></i><p>Sign Out</p>
                    </a>
                </li>
            </ul>
        </nav>
    </div>
</aside>

<!-- ================================================================
     MAIN CONTENT
================================================================ -->
<div class="content-wrapper">
<div class="page-content">

    <div class="page-heading">
        <div>
            <h1 class="page-title">Reports</h1>
            <div class="page-subtitle">
                Showing data from <strong><%= request.getAttribute("fromDateDisplay") %></strong>
                to <strong><%= request.getAttribute("toDateDisplay") %></strong>
            </div>
        </div>
    </div>

    <!-- ── FILTER BAR ─────────────────────────────────────────── -->
    <form class="filter-bar" method="get" action="<%= ctx %>/reports">
        <div class="filter-field">
            <label>From</label>
            <input type="date" name="from" value="<%= request.getAttribute("fromDate") %>">
        </div>
        <div class="filter-field">
            <label>To</label>
            <input type="date" name="to" value="<%= request.getAttribute("toDate") %>">
        </div>
        <button type="submit" class="btn-apply"><i class="fas fa-filter mr-1"></i>Apply</button>
        <div class="quick-range">
            <a href="<%= ctx %>/reports?from=<%= java.time.LocalDate.now() %>&to=<%= java.time.LocalDate.now() %>">Today</a>
            <a href="<%= ctx %>/reports?from=<%= java.time.LocalDate.now().minusDays(6) %>&to=<%= java.time.LocalDate.now() %>">Last 7 days</a>
            <a href="<%= ctx %>/reports?from=<%= java.time.LocalDate.now().minusDays(29) %>&to=<%= java.time.LocalDate.now() %>">Last 30 days</a>
            <a href="<%= ctx %>/reports?from=<%= java.time.LocalDate.now().withDayOfMonth(1) %>&to=<%= java.time.LocalDate.now() %>">This month</a>
        </div>
    </form>

    <!-- ── SUMMARY STRIP ──────────────────────────────────────── -->
    <div class="summary-strip">
        <div class="summary-item">
            <div class="summary-val">₦<fmt:formatNumber value="${salesSummary.totalRevenue}" pattern="#,##0.00"/></div>
            <div class="summary-lbl">Total Revenue</div>
        </div>
        <div class="summary-item">
            <div class="summary-val green">₦<fmt:formatNumber value="${salesSummary.totalProfit}" pattern="#,##0.00"/></div>
            <div class="summary-lbl">Gross Profit</div>
        </div>
        <div class="summary-item">
            <div class="summary-val">${salesSummary.totalSales}</div>
            <div class="summary-lbl">Completed Sales</div>
        </div>
        <div class="summary-item">
            <div class="summary-val">₦<fmt:formatNumber value="${salesSummary.avgOrderValue}" pattern="#,##0.00"/></div>
            <div class="summary-lbl">Avg. Order Value</div>
        </div>
        <div class="summary-item">
            <div class="summary-val">${salesSummary.totalItemsSold}</div>
            <div class="summary-lbl">Items Sold</div>
        </div>
        <div class="summary-item">
            <div class="summary-val <c:if test='${lowStockCount > 0}'>amber</c:if>">${lowStockCount}</div>
            <div class="summary-lbl">Low Stock Items</div>
        </div>
    </div>

    <!-- ── REVENUE TREND CHART ────────────────────────────────── -->
    <div class="card-panel" style="margin-bottom:18px">
        <h3><i class="fas fa-chart-line"></i>Revenue Trend</h3>
        <div style="height:260px">
            <canvas id="revenueTrendChart"></canvas>
        </div>
    </div>

    <div class="report-grid">
        <!-- ── TOP SELLING PRODUCTS ────────────────────────────── -->
        <div class="card-panel">
            <h3><i class="fas fa-crown"></i>Top Selling Products</h3>
            <c:choose>
                <c:when test="${empty topProducts}">
                    <div class="empty-state">
                        <i class="fas fa-box-open"></i>
                        No sales recorded in this period.
                    </div>
                </c:when>
                <c:otherwise>
                    <table class="report-table">
                        <thead>
                            <tr><th>#</th><th>Product</th><th>Qty Sold</th><th>Revenue</th><th>Profit</th></tr>
                        </thead>
                        <tbody>
                            <c:forEach items="${topProducts}" var="p" varStatus="st">
                                <tr>
                                    <td><span class="rank-badge">${st.count}</span></td>
                                    <td>${p.productName}</td>
                                    <td>${p.totalQty}</td>
                                    <td>₦<fmt:formatNumber value="${p.totalRevenue}" pattern="#,##0.00"/></td>
                                    <td>₦<fmt:formatNumber value="${p.totalProfit}" pattern="#,##0.00"/></td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </c:otherwise>
            </c:choose>
        </div>

        <!-- ── PAYMENT METHOD BREAKDOWN ────────────────────────── -->
        <div class="card-panel">
            <h3><i class="fas fa-wallet"></i>Revenue by Payment Method</h3>
            <c:choose>
                <c:when test="${empty paymentBreakdown}">
                    <div class="empty-state">
                        <i class="fas fa-receipt"></i>
                        No payments recorded in this period.
                    </div>
                </c:when>
                <c:otherwise>
                    <table class="report-table">
                        <thead>
                            <tr><th>Method</th><th>Sales</th><th>Revenue</th></tr>
                        </thead>
                        <tbody>
                            <c:forEach items="${paymentBreakdown}" var="pm">
                                <tr>
                                    <td>${pm.paymentMethod}</td>
                                    <td>${pm.salesCount}</td>
                                    <td>₦<fmt:formatNumber value="${pm.revenue}" pattern="#,##0.00"/></td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </c:otherwise>
            </c:choose>
        </div>
    </div>

    <!-- ── LOW STOCK / INVENTORY SNAPSHOT ─────────────────────── -->
    <div class="card-panel">
        <h3><i class="fas fa-warehouse"></i>Inventory Snapshot
            <span style="float:right;font-weight:400;color:var(--slate-500);font-size:12px">
                Current inventory value: <strong style="color:var(--slate-900)">₦<fmt:formatNumber value="${inventoryValue}" pattern="#,##0.00"/></strong>
            </span>
        </h3>
        <c:choose>
            <c:when test="${empty lowStockProducts}">
                <div class="empty-state">
                    <i class="fas fa-check-circle"></i>
                    All products are above their reorder level.
                </div>
            </c:when>
            <c:otherwise>
                <table class="report-table">
                    <thead>
                        <tr><th>Product</th><th>SKU</th><th>Current Stock</th><th>Reorder Level</th><th>Status</th></tr>
                    </thead>
                    <tbody>
                        <c:forEach items="${lowStockProducts}" var="prod">
                            <tr>
                                <td>${prod.name}</td>
                                <td>${prod.sku}</td>
                                <td>${prod.currentStock}</td>
                                <td>${prod.reorderLevel}</td>
                                <td>
                                    <c:choose>
                                        <c:when test="${prod.currentStock == 0}">
                                            <span class="out-badge">OUT OF STOCK</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="low-badge">LOW STOCK</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </c:otherwise>
        </c:choose>
    </div>

</div><%-- /page-content --%>
</div><%-- /content-wrapper --%>

<footer class="main-footer">
    Jare Pharmacy Inventory System &copy; <%= java.time.Year.now().getValue() %>
</footer>

</div><%-- /wrapper --%>

<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.4/jquery.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/4.6.2/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>
<script src="https://cdn.datatables.net/1.13.4/js/jquery.dataTables.min.js"></script>
<script src="https://cdn.datatables.net/1.13.4/js/dataTables.bootstrap4.min.js"></script>
<script src="https://cdn.datatables.net/responsive/2.4.1/js/dataTables.responsive.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<script>
$(function () {
    var labels  = <%= labelsJson.toString() %>;
    var revenue = <%= revenueJson.toString() %>;

    var ctx = document.getElementById('revenueTrendChart').getContext('2d');
    var gradient = ctx.createLinearGradient(0, 0, 0, 220);
    gradient.addColorStop(0, 'rgba(37,99,235,0.15)');
    gradient.addColorStop(1, 'rgba(37,99,235,0.0)');

    new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Revenue (₦)',
                data: revenue,
                borderColor: '#2563eb',
                backgroundColor: gradient,
                borderWidth: 2.5,
                tension: 0.4,
                fill: true,
                pointBackgroundColor: '#2563eb',
                pointBorderColor: '#ffffff',
                pointBorderWidth: 2,
                pointRadius: 4,
                pointHoverRadius: 6
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: '#0f172a',
                    titleColor: '#f1f5f9',
                    bodyColor: '#94a3b8',
                    padding: 12, cornerRadius: 8,
                    callbacks: {
                        label: function (c) { return ' Revenue: ₦' + c.parsed.y.toLocaleString(); }
                    }
                }
            },
            scales: {
                x: { ticks: { color: '#94a3b8', font: { family: 'Inter', size: 11 } } },
                y: {
                    grid: { color: '#f1f5f9', drawBorder: false },
                    ticks: {
                        color: '#94a3b8',
                        font: { family: 'Inter', size: 11 },
                        callback: function (v) {
                            return v >= 1000000 ? '₦' + (v/1000000).toFixed(1) + 'M'
                                 : v >= 1000    ? '₦' + Math.round(v/1000) + 'k'
                                 : '₦' + v;
                        }
                    }
                }
            }
        }
    });
});
</script>
</body>
</html>
