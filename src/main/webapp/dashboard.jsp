<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core"      prefix="c"   %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"       prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"  %>
<%--
==========================================================================
  dashboard.jsp  -  StockPro Inventory System
==========================================================================

  REQUIRES: DashboardServlet to have run first (URL: /dashboard)
  DO NOT access this JSP directly via dashboard.jsp - always go via /dashboard

  Every value shown on this page is REAL data from PostgreSQL.
  No hardcoded numbers anywhere.

  Request attributes expected (all set by DashboardServlet):
    totalProducts       int
    lowStockCount       int
    outOfStockCount     int
    inventoryValue      BigDecimal
    grossRevenueToday   BigDecimal
    salesToday          int
    totalCategories     int
    lowStockProducts    List<Product>  (up to 7)
    products            List<Product>  (all active)
    recentTransactions  List<InventoryTransaction> (last 8)
    dayLabels           String[]       (7 day names for chart)
    revenueByDay        BigDecimal[]   (7 revenue figures)
    itemsSoldByDay      int[]          (7 items-sold figures)
    thisWeekRevenue     BigDecimal
    lastWeekRevenue     BigDecimal
    weeklyItemsSoldTotal int
    todayFormatted      String         (e.g. "Friday, 06 Jun 2026")
==========================================================================
--%>
<%
    // ── Session user (for the avatar + name display) ──────────
    com.inventory.model.User sessionUser =
        (com.inventory.model.User) session.getAttribute("loggedInUser");
    String userFullName = sessionUser != null ? sessionUser.getFullName()  : "Admin";
    String userRole     = sessionUser != null ? sessionUser.getRole()      : "";

    // Build 2-letter avatar initials
    String initials = "";
    for (String part : userFullName.trim().split("\\s+")) {
        if (!part.isEmpty()) initials += part.charAt(0);
        if (initials.length() == 2) break;
    }
    initials = initials.toUpperCase();

    // ── Chart data - pull from request attributes set by servlet
    // Convert Java arrays -> JSON strings for Chart.js
    String[]          dayLabels     = (String[])          request.getAttribute("dayLabels");
    java.math.BigDecimal[] revByDay = (java.math.BigDecimal[]) request.getAttribute("revenueByDay");
    int[]             itemsByDay    = (int[])              request.getAttribute("itemsSoldByDay");

    // Build JSON arrays safely
    StringBuilder labelsJson  = new StringBuilder("[");
    StringBuilder revenueJson = new StringBuilder("[");
    StringBuilder itemsJson   = new StringBuilder("[");

    if (dayLabels != null) {
        for (int i = 0; i < dayLabels.length; i++) {
            if (i > 0) { labelsJson.append(","); revenueJson.append(","); itemsJson.append(","); }
            labelsJson.append("'").append(dayLabels[i]).append("'");
            revenueJson.append(revByDay != null && revByDay[i] != null ? revByDay[i].toPlainString() : "0");
            itemsJson.append(itemsByDay != null ? itemsByDay[i] : 0);
        }
    } else {
        labelsJson.append("'Mon','Tue','Wed','Thu','Fri','Sat','Sun'");
        revenueJson.append("0,0,0,0,0,0,0");
        itemsJson.append("0,0,0,0,0,0,0");
    }
    labelsJson.append("]");
    revenueJson.append("]");
    itemsJson.append("]");

    // ── Weekly growth % ───────────────────────────────────────
    java.math.BigDecimal thisWeek = (java.math.BigDecimal) request.getAttribute("thisWeekRevenue");
    java.math.BigDecimal lastWeek = (java.math.BigDecimal) request.getAttribute("lastWeekRevenue");
    if (thisWeek == null) thisWeek = java.math.BigDecimal.ZERO;
    if (lastWeek == null) lastWeek = java.math.BigDecimal.ZERO;

    String growthPct   = "-";
    boolean growthUp   = true;
    if (lastWeek.compareTo(java.math.BigDecimal.ZERO) > 0) {
        java.math.BigDecimal pct = thisWeek.subtract(lastWeek)
            .divide(lastWeek, 4, java.math.RoundingMode.HALF_UP)
            .multiply(java.math.BigDecimal.valueOf(100))
            .setScale(1, java.math.RoundingMode.HALF_UP);
        growthUp   = pct.compareTo(java.math.BigDecimal.ZERO) >= 0;
        growthPct  = (growthUp ? "+" : "") + pct.toPlainString() + "%";
    } else if (thisWeek.compareTo(java.math.BigDecimal.ZERO) > 0) {
        growthPct = "New";
        growthUp  = true;
    }

    // ── Safe formatting helpers ───────────────────────────────
    java.math.BigDecimal grossRevenue =
        (java.math.BigDecimal) request.getAttribute("grossRevenueToday");
    java.math.BigDecimal inventoryValue =
        (java.math.BigDecimal) request.getAttribute("inventoryValue");
    if (grossRevenue   == null) grossRevenue   = java.math.BigDecimal.ZERO;
    if (inventoryValue == null) inventoryValue = java.math.BigDecimal.ZERO;

    int totalProducts   = request.getAttribute("totalProducts")   != null ? (int) request.getAttribute("totalProducts")   : 0;
    int lowStockCount   = request.getAttribute("lowStockCount")   != null ? (int) request.getAttribute("lowStockCount")   : 0;
    int outOfStockCount = request.getAttribute("outOfStockCount") != null ? (int) request.getAttribute("outOfStockCount") : 0;
    int salesToday      = request.getAttribute("salesToday")      != null ? (int) request.getAttribute("salesToday")      : 0;
    int weeklyItems     = request.getAttribute("weeklyItemsSoldTotal") != null ? (int) request.getAttribute("weeklyItemsSoldTotal") : 0;
    int totalCategories = request.getAttribute("totalCategories") != null ? (int) request.getAttribute("totalCategories") : 0;

    String todayFormatted = request.getAttribute("todayFormatted") != null
        ? (String) request.getAttribute("todayFormatted") : "";

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>StockPro | Executive Dashboard</title>

<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
<link rel="stylesheet" href="https://cdn.datatables.net/1.13.4/css/dataTables.bootstrap4.min.css">
<link rel="stylesheet" href="https://cdn.datatables.net/responsive/2.4.1/css/responsive.bootstrap4.min.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css">

<style>
/* ── GLOBAL ─────────────────────────────────────────────────── */
*,*::before,*::after{box-sizing:border-box}
body,.content-wrapper,.main-sidebar,.main-header,.main-footer{
    font-family:'Inter',-apple-system,BlinkMacSystemFont,sans-serif!important}
body{background:#f1f5f9!important;color:#0f172a!important;font-size:13px!important}

/* ── SIDEBAR ─────────────────────────────────────────────────── */
.main-sidebar{background:#0f172a!important;box-shadow:none!important;border-right:none!important;width:230px!important}
.brand-link{background:#0f172a!important;border-bottom:1px solid rgba(255,255,255,.06)!important;padding:16px!important;display:flex!important;align-items:center!important;gap:10px!important;text-decoration:none!important}
.brand-logo-box{width:32px;height:32px;background:#2563eb;border-radius:9px;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.brand-logo-box i{color:#fff;font-size:15px}
.brand-text-wrap .brand-name{font-size:15px;font-weight:700;color:#fff;letter-spacing:-.01em;display:block}
.brand-text-wrap .brand-sub{font-size:10px;color:#475569;font-weight:400;display:block;margin-top:1px}
.user-panel{background:transparent!important;border-bottom:1px solid rgba(255,255,255,.06)!important;padding:12px 16px!important;display:flex;align-items:center;gap:10px}
.sidebar-user-avatar{width:32px;height:32px;border-radius:50%;background:#1e3a8a;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;color:#bfdbfe;flex-shrink:0}
.user-panel .info a{color:#cbd5e1!important;font-size:12.5px!important;font-weight:600!important;text-decoration:none!important;display:block}
.user-panel .info small{color:#475569;font-size:10.5px}
.nav-sidebar .nav-header{font-size:9.5px!important;font-weight:700!important;letter-spacing:.08em!important;color:#334155!important;text-transform:uppercase!important;padding:14px 16px 4px!important}
.nav-sidebar .nav-item .nav-link{color:#94a3b8!important;border-radius:8px!important;margin:1px 8px!important;padding:9px 12px!important;font-size:12.5px!important;font-weight:400!important;border-left:2px solid transparent!important;display:flex!important;align-items:center!important;gap:9px!important;transition:all .12s ease!important}
.nav-sidebar .nav-item .nav-link:hover{background:rgba(255,255,255,.05)!important;color:#e2e8f0!important}
.nav-sidebar .nav-item .nav-link.active{background:rgba(37,99,235,.18)!important;color:#60a5fa!important;border-left-color:#2563eb!important}
.nav-sidebar .nav-link .nav-icon{font-size:14px!important;width:16px!important;text-align:center;flex-shrink:0}
.nav-sidebar .nav-link p{margin:0!important;font-size:12.5px!important;line-height:1!important}
.nav-alert-badge{margin-left:auto;background:#dc2626;color:#fff;font-size:9px;font-weight:700;padding:2px 7px;border-radius:20px;line-height:1.4}

/* ── TOPBAR ─────────────────────────────────────────────────── */
.main-header.navbar{background:#fff!important;border-bottom:1px solid #e2e8f0!important;box-shadow:none!important;min-height:54px!important;padding:0 20px!important}
.topbar-breadcrumb{font-size:12px;color:#64748b;display:flex;align-items:center;gap:5px;margin-left:8px}
.topbar-breadcrumb .crumb-active{color:#0f172a;font-weight:600}
.live-badge{display:flex;align-items:center;gap:6px;font-size:11px;font-weight:600;color:#059669;background:#f0fdf4;border:1px solid #bbf7d0;border-radius:20px;padding:4px 11px}
.live-dot{width:7px;height:7px;border-radius:50%;background:#22c55e;flex-shrink:0}
.topbar-bell{position:relative;cursor:pointer;color:#64748b;font-size:17px;padding:6px}
.topbar-bell .bell-dot{position:absolute;top:4px;right:4px;width:8px;height:8px;border-radius:50%;background:#dc2626;border:1.5px solid #fff}
.topbar-user-wrap{display:flex;align-items:center;gap:8px;cursor:pointer;padding:4px 8px;border-radius:9px;transition:background .12s}
.topbar-user-wrap:hover{background:#f1f5f9}
.topbar-avatar{width:32px;height:32px;border-radius:50%;background:#dbeafe;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;color:#1d4ed8;flex-shrink:0}
.topbar-user-name{font-size:12.5px;font-weight:600;color:#0f172a;line-height:1.2}
.topbar-user-role{font-size:10.5px;color:#94a3b8}

/* ── CONTENT ─────────────────────────────────────────────────── */
.content-wrapper{background:#f1f5f9!important;padding:0!important}
.page-content{padding:22px 24px}
.page-heading{display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:20px;flex-wrap:wrap;gap:12px}
.page-heading h2{font-size:20px;font-weight:700;color:#0f172a;margin:0 0 3px;letter-spacing:-.01em}
.page-heading p{font-size:12px;color:#64748b;margin:0}
.btn-primary-custom{background:#2563eb!important;color:#fff!important;border:none!important;border-radius:8px!important;padding:8px 16px!important;font-size:12.5px!important;font-weight:600!important;cursor:pointer!important;display:flex!important;align-items:center!important;gap:6px!important;transition:background .12s!important;text-decoration:none!important}
.btn-primary-custom:hover{background:#1d4ed8!important;color:#fff!important}
.btn-secondary-custom{background:#fff!important;color:#374151!important;border:1px solid #d1d5db!important;border-radius:8px!important;padding:8px 16px!important;font-size:12.5px!important;font-weight:500!important;cursor:pointer!important;display:flex!important;align-items:center!important;gap:6px!important;transition:background .12s!important;text-decoration:none!important}
.btn-secondary-custom:hover{background:#f9fafb!important;color:#111827!important}

/* ── KPI CARDS ────────────────────────────────────────────────── */
.kpi-row{margin-bottom:16px}
.kpi-card{background:#fff;border:1px solid #e2e8f0;border-radius:12px;padding:18px;position:relative;overflow:hidden;transition:box-shadow .15s,transform .15s;height:100%}
.kpi-card:hover{box-shadow:0 8px 20px rgba(0,0,0,.06);transform:translateY(-1px)}
.kpi-card::after{content:'';position:absolute;bottom:0;left:0;right:0;height:3px;border-radius:0 0 12px 12px}
.kpi-card.blue::after  {background:#2563eb}
.kpi-card.green::after {background:#22c55e}
.kpi-card.amber::after {background:#f59e0b}
.kpi-card.purple::after{background:#7c3aed}
.kpi-top{display:flex;align-items:center;justify-content:space-between;margin-bottom:12px}
.kpi-label{font-size:10.5px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.06em}
.kpi-icon-box{width:38px;height:38px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:17px;flex-shrink:0}
.kpi-value{font-size:26px;font-weight:700;color:#0f172a;line-height:1;margin-bottom:7px;letter-spacing:-.02em}
.kpi-value.naira{font-size:20px}
.kpi-value.alert{color:#d97706}
.kpi-trend{display:flex;align-items:center;gap:4px;font-size:11.5px;font-weight:500}
.trend-up{color:#059669}.trend-down{color:#dc2626}.trend-info{color:#64748b}

/* ── PANELS ─────────────────────────────────────────────────── */
.panel{background:#fff;border:1px solid #e2e8f0;border-radius:12px;overflow:hidden;margin-bottom:16px}
.panel-header{display:flex;align-items:center;justify-content:space-between;padding:14px 18px;border-bottom:1px solid #f1f5f9}
.panel-title{font-size:13.5px;font-weight:600;color:#0f172a;display:flex;align-items:center;gap:8px}
.panel-title i{font-size:15px;color:#94a3b8}
.panel-body{padding:16px 18px}
.panel-body-flush{padding:0}
.pill-btn{background:#f1f5f9;color:#64748b;border:none;border-radius:20px;padding:5px 13px;font-size:11px;font-weight:600;cursor:pointer;transition:background .12s;font-family:inherit;text-decoration:none;display:inline-block}
.pill-btn:hover{background:#e2e8f0;color:#374151}
.pill-btn.active-blue{background:#eff6ff;color:#1d4ed8}

/* ── CHART ─────────────────────────────────────────────────── */
.chart-container{position:relative;height:240px}
.chart-footer{display:flex;border-top:1px solid #f1f5f9;margin-top:14px}
.chart-stat{flex:1;text-align:center;padding:12px 0;border-right:1px solid #f1f5f9}
.chart-stat:last-child{border-right:none}
.chart-stat-val{font-size:14px;font-weight:700;color:#0f172a}
.chart-stat-lbl{font-size:10.5px;color:#94a3b8;margin-top:2px}

/* ── LOW STOCK ALERT LIST ───────────────────────────────────── */
.alert-list-item{display:flex;align-items:center;gap:10px;padding:10px 18px;border-bottom:1px solid #f8fafc;transition:background .1s}
.alert-list-item:hover{background:#fafafa}
.alert-list-item:last-of-type{border-bottom:none}
.alert-dot{width:9px;height:9px;border-radius:50%;flex-shrink:0}
.dot-critical{background:#dc2626}.dot-warning{background:#f59e0b}
.alert-info{flex:1;min-width:0}
.alert-product-name{font-size:12.5px;font-weight:600;color:#0f172a;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.alert-product-sku{font-size:10.5px;color:#94a3b8;margin-top:1px;font-family:monospace}
.stock-badge{font-size:10.5px;font-weight:700;padding:3px 9px;border-radius:20px;flex-shrink:0}
.stock-badge.critical{background:#fef2f2;color:#dc2626}
.stock-badge.warning{background:#fffbeb;color:#b45309}
.alert-footer{padding:10px 18px;border-top:1px solid #f1f5f9}

/* ── PRODUCT TABLE ──────────────────────────────────────────── */
#inventoryTable thead th{background:#f8fafc!important;color:#64748b!important;font-size:10.5px!important;font-weight:700!important;text-transform:uppercase!important;letter-spacing:.06em!important;border-bottom:1px solid #e2e8f0!important;border-top:none!important;padding:11px 14px!important;white-space:nowrap}
#inventoryTable tbody td{font-size:12.5px!important;color:#1e293b!important;padding:12px 14px!important;border-bottom:1px solid #f8fafc!important;vertical-align:middle!important}
#inventoryTable tbody tr:hover td{background:#fafafa!important}
#inventoryTable tbody tr:last-child td{border-bottom:none!important}
.product-cell{display:flex;align-items:center;gap:10px}
.product-thumb{width:32px;height:32px;background:#eff6ff;border-radius:8px;display:flex;align-items:center;justify-content:center;color:#3b82f6;font-size:14px;flex-shrink:0}
.product-name{font-weight:600;color:#0f172a;font-size:12.5px;line-height:1.2}
.product-supplier{font-size:10.5px;color:#94a3b8;margin-top:1px}
.sku-chip{font-family:'Courier New',monospace;font-size:11px;font-weight:700;color:#2563eb;background:#eff6ff;padding:3px 8px;border-radius:6px;display:inline-block}
.status-badge{display:inline-block;font-size:10.5px;font-weight:700;padding:4px 10px;border-radius:20px}
.status-instock{background:#f0fdf4;color:#15803d}
.status-lowstock{background:#fffbeb;color:#b45309}
.status-critical{background:#fef2f2;color:#dc2626}
.tbl-btn{width:28px;height:28px;border-radius:7px;border:none;cursor:pointer;display:inline-flex;align-items:center;justify-content:center;font-size:12.5px;transition:background .12s;margin-right:3px}
.tbl-btn-edit{background:#eff6ff;color:#2563eb}
.tbl-btn-delete{background:#fef2f2;color:#dc2626}
.tbl-btn-edit:hover{background:#dbeafe}
.tbl-btn-delete:hover{background:#fecaca}

/* DataTables */
.dataTables_wrapper .dataTables_filter input{border:1px solid #e2e8f0!important;border-radius:8px!important;font-size:12px!important;padding:6px 12px!important;color:#0f172a!important;font-family:inherit!important;margin-left:6px}
.dataTables_wrapper .dataTables_filter input:focus{outline:none!important;border-color:#93c5fd!important}
.dataTables_wrapper .dataTables_length select{border:1px solid #e2e8f0!important;border-radius:7px!important;font-size:12px!important;font-family:inherit!important;padding:4px 8px!important}
.dataTables_wrapper .dataTables_info,.dataTables_wrapper .dataTables_paginate{font-size:11.5px!important;color:#94a3b8!important;padding:10px 16px!important;border-top:1px solid #f1f5f9!important}
.dataTables_wrapper .paginate_button{border-radius:7px!important;font-size:12px!important;font-family:inherit!important;padding:4px 9px!important;border:none!important}
.dataTables_wrapper .paginate_button.current,.dataTables_wrapper .paginate_button.current:hover{background:#2563eb!important;color:#fff!important;border:none!important}
.dataTables_wrapper .paginate_button:hover{background:#f1f5f9!important;color:#374151!important;border:none!important}

/* ── TRANSACTIONS FEED ──────────────────────────────────────── */
.txn-item{display:flex;align-items:center;gap:12px;padding:10px 18px;border-bottom:1px solid #f8fafc;transition:background .1s}
.txn-item:hover{background:#fafafa}
.txn-item:last-child{border-bottom:none}
.txn-icon{width:36px;height:36px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0}
.txn-stock-in{background:#f0fdf4;color:#059669}
.txn-stock-out{background:#fffbeb;color:#d97706}
.txn-sale{background:#eff6ff;color:#3b82f6}
.txn-damage{background:#fef2f2;color:#dc2626}
.txn-details{flex:1;min-width:0}
.txn-title{font-size:12.5px;font-weight:600;color:#0f172a;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.txn-meta{font-size:10.5px;color:#94a3b8;margin-top:2px}
.txn-amount{font-size:12.5px;font-weight:700;white-space:nowrap}
.txn-amount.positive{color:#059669}
.txn-amount.negative{color:#dc2626}
.txn-amount.neutral{color:#64748b}

/* ── SUMMARY STRIP ──────────────────────────────────────────── */
.summary-strip{display:flex;background:#fff;border:1px solid #e2e8f0;border-radius:12px;overflow:hidden;margin-bottom:16px}
.summary-item{flex:1;text-align:center;padding:16px;border-right:1px solid #f1f5f9}
.summary-item:last-child{border-right:none}
.summary-val{font-size:22px;font-weight:700;color:#0f172a;letter-spacing:-.01em}
.summary-lbl{font-size:10.5px;color:#94a3b8;margin-top:3px;text-transform:uppercase;letter-spacing:.05em}

/* empty state */
.empty-txn{text-align:center;padding:28px 16px;color:#94a3b8;font-size:12px}
.empty-txn i{font-size:28px;display:block;margin-bottom:8px;color:#e2e8f0}

/* ── FOOTER ─────────────────────────────────────────────────── */
.main-footer{background:#fff!important;border-top:1px solid #e2e8f0!important;padding:12px 24px!important;font-size:11.5px!important;color:#94a3b8!important;text-align:center!important}

@media(max-width:768px){
    .page-heading{flex-direction:column}
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
                <span class="crumb-active">Dashboard</span>
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
        <li class="nav-item d-none d-lg-flex align-items-center">
            <span style="font-size:11.5px;color:#94a3b8">
                <i class="far fa-calendar-alt mr-1"></i>
                <%= todayFormatted %>
            </span>
        </li>
        <li class="nav-item">
            <div class="topbar-bell" id="notifBtn"
                 title="<%= lowStockCount %> low stock alerts">
                <i class="fas fa-bell"></i>
                <% if (lowStockCount > 0) { %><span class="bell-dot"></span><% } %>
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
            <span class="brand-name">StockPro</span>
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
                    <a href="<%= ctx %>/dashboard" class="nav-link active">
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
                    <a href="<%= ctx %>/reports.jsp" class="nav-link">
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

    <%-- Page heading --%>
    <div class="page-heading">
        <div>
            <h2>Executive Dashboard</h2>
            <p>Live inventory diagnostics &amp; sales analytics - <%= todayFormatted %></p>
        </div>
        <div class="d-flex" style="gap:8px;flex-wrap:wrap">
            <a href="<%= ctx %>/reports.jsp" class="btn-secondary-custom">
                <i class="fas fa-download"></i> Export report
            </a>
            <a href="<%= ctx %>/products?action=new" class="btn-primary-custom">
                <i class="fas fa-plus"></i> New product
            </a>
        </div>
    </div>

    <%-- ── ROW 1: KPI CARDS ───────────────────────────────────────── --%>
    <div class="row kpi-row">

        <%-- Total Products - REAL from productDAO.getTotalProductCount() --%>
        <div class="col-xl-3 col-sm-6 mb-3">
            <div class="kpi-card blue">
                <div class="kpi-top">
                    <span class="kpi-label">Total products</span>
                    <div class="kpi-icon-box" style="background:#eff6ff">
                        <i class="fas fa-boxes-stacked" style="color:#2563eb"></i>
                    </div>
                </div>
                <div class="kpi-value"><%= totalProducts %></div>
                <div class="kpi-trend trend-info">
                    <i class="fas fa-tags" style="font-size:10px"></i>
                    <%= totalCategories %> categories
                </div>
            </div>
        </div>

        <%-- Gross Revenue Today - REAL from saleDAO.getTodaySummary() --%>
        <div class="col-xl-3 col-sm-6 mb-3">
            <div class="kpi-card green">
                <div class="kpi-top">
                    <span class="kpi-label">Gross revenue (today)</span>
                    <div class="kpi-icon-box" style="background:#f0fdf4">
                        <i class="fas fa-chart-line" style="color:#059669"></i>
                    </div>
                </div>
                <div class="kpi-value naira">
                    &#x20A6;<%= String.format("%,.2f", grossRevenue) %>
                </div>
                <div class="kpi-trend <%= growthUp ? "trend-up" : "trend-down" %>">
                    <i class="fas <%= growthUp ? "fa-arrow-trend-up" : "fa-arrow-trend-down" %>"
                       style="font-size:10px"></i>
                    <%= growthPct %> vs last week
                </div>
            </div>
        </div>

        <%-- Low Stock - REAL count from product list --%>
        <div class="col-xl-3 col-sm-6 mb-3">
            <div class="kpi-card amber">
                <div class="kpi-top">
                    <span class="kpi-label">Low stock alerts</span>
                    <div class="kpi-icon-box" style="background:#fffbeb">
                        <i class="fas fa-triangle-exclamation" style="color:#d97706"></i>
                    </div>
                </div>
                <div class="kpi-value alert"><%= lowStockCount %></div>
                <div class="kpi-trend <%= lowStockCount > 0 ? "trend-down" : "trend-up" %>">
                    <% if (lowStockCount > 0) { %>
                    <i class="fas fa-circle-exclamation" style="font-size:10px"></i>
                    <%= outOfStockCount %> out of stock
                    <% } else { %>
                    <i class="fas fa-circle-check" style="font-size:10px"></i>
                    All stock levels healthy
                    <% } %>
                </div>
            </div>
        </div>

        <%-- Sales Today - REAL from saleDAO.getTodaySummary() --%>
        <div class="col-xl-3 col-sm-6 mb-3">
            <div class="kpi-card purple">
                <div class="kpi-top">
                    <span class="kpi-label">Receipts (today)</span>
                    <div class="kpi-icon-box" style="background:#faf5ff">
                        <i class="fas fa-receipt" style="color:#7c3aed"></i>
                    </div>
                </div>
                <div class="kpi-value"><%= salesToday %></div>
                <div class="kpi-trend trend-info">
                    <i class="fas fa-box" style="font-size:10px"></i>
                    <%= weeklyItems %> items sold this week
                </div>
            </div>
        </div>

    </div><%-- /KPI ROW --%>

    <%-- ── ROW 2: CHART + LOW STOCK PANEL ───────────────────────── --%>
    <div class="row">

        <%-- Sales Chart --%>
        <div class="col-lg-8 mb-3">
            <div class="panel h-100" style="margin-bottom:0">
                <div class="panel-header">
                    <div class="panel-title">
                        <i class="fas fa-chart-area"></i>
                        Weekly transaction velocity
                    </div>
                   <div style="display:flex;gap:6px">
    <button class="pill-btn active-blue" id="btnRevenue" onclick="toggleChartView('revenue')">Revenue</button>
    <button class="pill-btn" id="btnVolume" onclick="toggleChartView('volume')">Volume</button>
</div>
                </div>
                <div class="panel-body">
                    <div class="chart-container">
                        <canvas id="salesChart"></canvas>
                    </div>
                    <div class="chart-footer">
                        <div class="chart-stat">
                            <div class="chart-stat-val">
                                &#x20A6;<%= String.format("%,.0f", thisWeek) %>
                            </div>
                            <div class="chart-stat-lbl">This week</div>
                        </div>
                        <div class="chart-stat">
                            <div class="chart-stat-val">
                                &#x20A6;<%= String.format("%,.0f", lastWeek) %>
                            </div>
                            <div class="chart-stat-lbl">Last week</div>
                        </div>
                        <div class="chart-stat">
                            <div class="chart-stat-val"
                                 style="color:<%= growthUp ? "#059669" : "#dc2626" %>">
                                <%= growthPct %>
                            </div>
                            <div class="chart-stat-lbl">Weekly growth</div>
                        </div>
                        <div class="chart-stat">
                            <div class="chart-stat-val"><%= weeklyItems %></div>
                            <div class="chart-stat-lbl">Items sold</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <%-- Low Stock Alert Panel - REAL data from productDAO.getLowStockProducts() --%>
        <div class="col-lg-4 mb-3">
            <div class="panel h-100" style="margin-bottom:0;display:flex;flex-direction:column">
                <div class="panel-header">
                    <div class="panel-title">
                        <i class="fas fa-bell" style="color:#dc2626"></i>
                        Depleted stock warnings
                    </div>
                    <span style="font-size:10.5px;font-weight:700;color:#dc2626;background:#fef2f2;padding:3px 9px;border-radius:20px">
                        <%= lowStockCount %> items
                    </span>
                </div>

                <div style="flex:1;overflow:auto">
                    <%
                    java.util.List<com.inventory.model.Product> lowList =
                        (java.util.List<com.inventory.model.Product>)
                            request.getAttribute("lowStockProducts");
                    if (lowList == null || lowList.isEmpty()) {
                    %>
                        <div class="empty-txn">
                            <i class="fas fa-check-circle" style="color:#22c55e;font-size:32px"></i>
                            <p style="margin-top:8px;font-size:12px">All stock levels are healthy!</p>
                        </div>
                    <%
                    } else {
                        for (com.inventory.model.Product lp : lowList) {
                            boolean isCritical = lp.getCurrentStock() == 0
                                || lp.getCurrentStock() <= (lp.getReorderLevel() / 2);
                    %>
                        <div class="alert-list-item">
                            <div class="alert-dot <%= isCritical ? "dot-critical" : "dot-warning" %>"></div>
                            <div class="alert-info">
                                <div class="alert-product-name"><%= lp.getName() %></div>
                                <div class="alert-product-sku">
                                    <%= lp.getSku() %> &bull; Min: <%= lp.getReorderLevel() %>
                                </div>
                            </div>
                            <span class="stock-badge <%= isCritical ? "critical" : "warning" %>">
                                <%= lp.getCurrentStock() %> left
                            </span>
                        </div>
                    <%
                        }
                    }
                    %>
                </div>

                <div class="alert-footer">
                    <a href="<%= ctx %>/inventory?action=lowstock"
                       class="pill-btn"
                       style="display:block;text-align:center;width:100%">
                        View all <%= lowStockCount %> low stock items &rarr;
                    </a>
                </div>
            </div>
        </div>

    </div><%-- /ROW 2 --%>

    <%-- ── ROW 3: PRODUCT TABLE + RECENT TRANSACTIONS ─────────────── --%>
    <div class="row">

        <%-- Live Product Table - REAL data from productDAO.getAllProducts() --%>
        <div class="col-lg-8 mb-3">
            <div class="panel" style="margin-bottom:0">
                <div class="panel-header">
                    <div class="panel-title">
                        <i class="fas fa-layer-group"></i>
                        Live storage audit ledger
                    </div>
                    <a href="<%= ctx %>/products?action=new"
                       class="btn-primary-custom"
                       style="font-size:11.5px;padding:6px 12px;text-decoration:none">
                        <i class="fas fa-plus"></i> Add product
                    </a>
                </div>
                <div class="panel-body-flush">
                    <table id="inventoryTable" class="table table-hover w-100">
                        <thead>
                            <tr>
                                <th>Product</th>
                                <th>SKU</th>
                                <th>Category</th>
                                <th class="text-right">Unit price</th>
                                <th class="text-center">Stock</th>
                                <th class="text-center">Status</th>
                                <th class="text-center">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                        java.util.List<com.inventory.model.Product> pList =
                            (java.util.List<com.inventory.model.Product>)
                                request.getAttribute("products");
                        if (pList == null || pList.isEmpty()) {
                        %>
                            <tr>
                                <td colspan="7" style="text-align:center;padding:32px;color:#94a3b8">
                                    <i class="fas fa-box-open"
                                       style="font-size:28px;display:block;margin-bottom:8px;color:#e2e8f0"></i>
                                    No products found.
                                    <a href="<%= ctx %>/products?action=new"
                                       style="color:#2563eb;font-weight:600">Add your first product</a>
                                </td>
                            </tr>
                        <%
                        } else {
                            for (com.inventory.model.Product p : pList) {
                                boolean isOut = p.getCurrentStock() == 0;
                                boolean isLow = !isOut && p.getCurrentStock() <= p.getReorderLevel();
                                String statusClass = isOut ? "status-critical"
                                                   : isLow ? "status-lowstock"
                                                   : "status-instock";
                                String statusLabel = isOut ? "Out of stock"
                                                   : isLow ? "Low stock"
                                                   : "In stock";
                                String stockColour = isOut ? "color:#dc2626"
                                                   : isLow ? "color:#d97706"
                                                   : "color:#0f172a";
                        %>
                            <tr>
                                <td>
                                    <div class="product-cell">
                                        <div class="product-thumb"><i class="fas fa-box"></i></div>
                                        <div>
                                            <div class="product-name"><%= p.getName() %></div>
                                            <div class="product-supplier">
                                                <%= p.getSupplierName() != null && !p.getSupplierName().isEmpty()
                                                    ? p.getSupplierName() : "No supplier" %>
                                            </div>
                                        </div>
                                    </div>
                                </td>
                                <td><span class="sku-chip"><%= p.getSku() %></span></td>
                                <td style="color:#64748b">
                                    <%= p.getCategoryName() != null ? p.getCategoryName() : "-" %>
                                </td>
                                <td class="text-right" style="font-weight:600">
                                    &#x20A6;<%= p.getSellingPrice() != null
                                        ? String.format("%,.2f", p.getSellingPrice()) : "0.00" %>
                                </td>
                                <td class="text-center" style="font-weight:700;<%= stockColour %>">
                                    <%= p.getCurrentStock() %> <%= p.getUnit() %>
                                </td>
                                <td class="text-center">
                                    <span class="status-badge <%= statusClass %>"><%= statusLabel %></span>
                                </td>
                                <td class="text-center">
                                    <button class="tbl-btn tbl-btn-edit"
                                            onclick="editProduct(<%= p.getId() %>)"
                                            title="Edit">
                                        <i class="fas fa-pen"></i>
                                    </button>
                                    <button class="tbl-btn tbl-btn-delete"
                                            onclick="deleteProduct(<%= p.getId() %>,'<%= p.getName().replace("'","") %>')"
                                            title="Delete">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                </td>
                            </tr>
                        <%
                            }
                        }
                        %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <%-- Recent Transactions - REAL data from inventoryDAO.getRecentTransactions(8) --%>
        <div class="col-lg-4 mb-3">
            <div class="panel" style="margin-bottom:0;display:flex;flex-direction:column">
                <div class="panel-header">
                    <div class="panel-title">
                        <i class="fas fa-arrow-right-arrow-left"></i>
                        Recent stock movements
                    </div>
                    <a href="<%= ctx %>/inventory?action=list"
                       class="pill-btn" style="text-decoration:none">View all</a>
                </div>
                <div style="flex:1">
                    <%
                    java.util.List<com.inventory.model.InventoryTransaction> txList =
                        (java.util.List<com.inventory.model.InventoryTransaction>)
                            request.getAttribute("recentTransactions");
                    if (txList == null || txList.isEmpty()) {
                    %>
                        <div class="empty-txn">
                            <i class="fas fa-exchange-alt"></i>
                            No stock movements yet. Use the Inventory page to record stock in or out.
                        </div>
                    <%
                    } else {
                        for (com.inventory.model.InventoryTransaction tx : txList) {
                            boolean isIn  = tx.isStockIncreasing();
                            boolean isOut = tx.isStockDecreasing();
                            String iconClass = isIn  ? "txn-stock-in"
                                             : isOut ? "txn-stock-out" : "txn-damage";
                            String icon      = isIn  ? "fa-arrow-down"
                                             : isOut ? "fa-arrow-up" : "fa-exclamation";
                            String amtClass  = isIn  ? "positive"
                                             : isOut ? "negative" : "neutral";
                    %>
                        <div class="txn-item">
                            <div class="txn-icon <%= iconClass %>">
                                <i class="fas <%= icon %>"></i>
                            </div>
                            <div class="txn-details">
                                <div class="txn-title">
                                    <%= tx.getTypeLabel() %> - <%= tx.getProductName() %>
                                </div>
                                <div class="txn-meta">
                                    <%= tx.getFormattedDate() %>
                                    <% if (tx.getPerformedByName() != null) { %>
                                    &bull; <%= tx.getPerformedByName() %>
                                    <% } %>
                                </div>
                            </div>
                            <div class="txn-amount <%= amtClass %>">
                                <%= tx.getSignedQuantity() %> <%= tx.getProductUnit() %>
                            </div>
                        </div>
                    <%
                        }
                    }
                    %>
                </div>
            </div>
        </div>

    </div><%-- /ROW 3 --%>

    <%-- ── ROW 4: SUMMARY STRIP - all REAL values ─────────────────── --%>
    <div class="summary-strip">
        <div class="summary-item">
            <div class="summary-val"><%= totalProducts %></div>
            <div class="summary-lbl">Total products</div>
        </div>
        <div class="summary-item">
            <div class="summary-val" style="font-size:16px;color:#059669">
                &#x20A6;<%= String.format("%,.0f", inventoryValue) %>
            </div>
            <div class="summary-lbl">Inventory value</div>
        </div>
        <div class="summary-item">
            <div class="summary-val" style="color:#d97706"><%= lowStockCount %></div>
            <div class="summary-lbl">Low stock items</div>
        </div>
        <div class="summary-item">
            <div class="summary-val" style="color:#dc2626"><%= outOfStockCount %></div>
            <div class="summary-lbl">Out of stock</div>
        </div>
        <div class="summary-item">
            <div class="summary-val"><%= totalCategories %></div>
            <div class="summary-lbl">Categories</div>
        </div>
        <div class="summary-item">
            <div class="summary-val" style="color:#2563eb"><%= salesToday %></div>
            <div class="summary-lbl">Sales today</div>
        </div>
    </div>

</div><%-- /page-content --%>
</div><%-- /content-wrapper --%>

<footer class="main-footer">
    <strong>StockPro Inventory System</strong> -
    &copy; 2025 Designed for Nigerian SMEs
</footer>

</div><%-- /wrapper --%>

<!-- ================================================================
     SCRIPTS
================================================================ -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.4/jquery.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/4.6.2/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>
<script src="https://cdn.datatables.net/1.13.4/js/jquery.dataTables.min.js"></script>
<script src="https://cdn.datatables.net/1.13.4/js/dataTables.bootstrap4.min.js"></script>
<script src="https://cdn.datatables.net/responsive/2.4.1/js/dataTables.responsive.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<script>
$(document).ready(function () {

    // ── 1. DataTable ─────────────────────────────────────────
    // 7 columns: Product, SKU, Category, Price, Stock, Status, Action
    // columnDefs targets [6] = Action (0-indexed) - no sort
  if ($('#inventoryTable').length > 0) {
        $('#inventoryTable').DataTable({
            responsive: true,
            pageLength: 5,
            lengthChange: false,
            language: {
                emptyTable: "No inventory data available at the moment.",
                info: "Showing _START_ to _END_ of _TOTAL_ products"
            },
            columnDefs: [
                { orderable: false, targets: [-1] } 
            ]
        });
    }
    // ── 2. Sales chart ────────────────────────────────────────
    // Data arrays come from DashboardServlet via Java scriptlets above
    var labels    = <%=labelsJson%>;
    var revenues  = <%=revenueJson%>;
    var itemsSold = <%=itemsJson%>;

    var ctx = document.getElementById('salesChart').getContext('2d');
    var gradient = ctx.createLinearGradient(0, 0, 0, 220);
    gradient.addColorStop(0, 'rgba(37,99,235,0.15)');
    gradient.addColorStop(1, 'rgba(37,99,235,0.0)');

    new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [
                {
                    label: 'Gross revenue (₦)',
                    data: revenues,
                    borderColor: '#2563eb',
                    backgroundColor: gradient,
                    borderWidth: 2.5,
                    tension: 0.4,
                    fill: true,
                    pointBackgroundColor: '#2563eb',
                    pointBorderColor: '#ffffff',
                    pointBorderWidth: 2,
                    pointRadius: 5,
                    pointHoverRadius: 7,
                    yAxisID: 'y'
                },
                {
                    label: 'Sales count',
                    data: itemsSold,
                    borderColor: '#7c3aed',
                    backgroundColor: 'transparent',
                    borderWidth: 2,
                    borderDash: [5, 5],
                    tension: 0.4,
                    pointBackgroundColor: '#7c3aed',
                    pointBorderColor: '#ffffff',
                    pointBorderWidth: 2,
                    pointRadius: 4,
                    pointHoverRadius: 6,
                    yAxisID: 'y1'
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: { mode: 'index', intersect: false },
            plugins: {
                legend: {
                    position: 'top', align: 'end',
                    labels: {
                        boxWidth: 10, boxHeight: 10, borderRadius: 3,
                        useBorderRadius: true,
                        font: { family: 'Inter', size: 11, weight: '500' },
                        color: '#64748b', padding: 16
                    }
                },
                tooltip: {
                    backgroundColor: '#0f172a',
                    titleColor: '#f1f5f9',
                    bodyColor: '#94a3b8',
                    padding: 12, cornerRadius: 8,
                    titleFont: { family: 'Inter', weight: '600' },
                    bodyFont:  { family: 'Inter' },
                    callbacks: {
                        label: function (ctx) {
                            if (ctx.datasetIndex === 0)
                                return ' Revenue: ₦' + ctx.parsed.y.toLocaleString();
                            return ' Sales: ' + ctx.parsed.y;
                        }
                    }
                }
            },
            scales: {
                x: {
                    grid: { display: false },
                    ticks: { color: '#94a3b8', font: { family: 'Inter', size: 11 } }
                },
                y: {
                    type: 'linear', position: 'left',
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
                },
                y1: {
                    type: 'linear', position: 'right',
                    grid: { drawOnChartArea: false },
                    ticks: { color: '#7c3aed', font: { family: 'Inter', size: 11 } }
                }
            }
        }
    });

    // ── 3. Bell notification click ────────────────────────────
    $('#notifBtn').on('click', function () {
        var lowCount = <%= lowStockCount %>;
        var outCount = <%= outOfStockCount %>;
        if (lowCount === 0) {
            Swal.fire({
                title: 'All Clear!',
                text: 'No stock alerts - all product levels are healthy.',
                icon: 'success',
                confirmButtonColor: '#2563eb'
            });
            return;
        }
        Swal.fire({
            title: 'Stock Alerts',
            html: '<p style="color:#64748b;font-size:14px;text-align:left;line-height:1.6">' +
                  'You have <strong style="color:#d97706">' + lowCount + ' product(s)</strong> ' +
                  'below their minimum reorder level.<br>' +
                  '<strong style="color:#dc2626">' + outCount + ' item(s)</strong> are completely out of stock.' +
                  '</p>',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Go to inventory',
            cancelButtonText:  'Dismiss',
            confirmButtonColor: '#2563eb'
        }).then(function (result) {
            if (result.isConfirmed)
                window.location.href = '<%= ctx %>/inventory?action=lowstock';
        });
    });
});

// ── 4. Table action handlers ──────────────────────────────────
function editProduct(productId) {
    window.location.href = '<%= ctx %>/products?action=edit&id=' + productId;
}

function deleteProduct(productId, productName) {
    Swal.fire({
        title: 'Delete product?',
        html: '<p style="color:#64748b;font-size:14px">Deleting <strong>' + productName +
              '</strong> hides it from inventory. All sales history is preserved.</p>',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Yes, delete it',
        cancelButtonText:  'Cancel',
        confirmButtonColor: '#dc2626',
        reverseButtons: true
    }).then(function (result) {
        if (result.isConfirmed)
            window.location.href = '<%= ctx %>/products?action=delete&id=' + productId;
    });
}
</script>
</body>
</html>
