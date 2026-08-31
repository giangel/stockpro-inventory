<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
    com.inventory.model.Sale,
    com.inventory.model.SaleItem,
    com.inventory.model.User,
    java.util.List,
    java.math.BigDecimal,
    java.time.format.DateTimeFormatter
"%>
<%
    User sessionUser = (User) session.getAttribute("loggedInUser");
    String userInitials = "";
    if (sessionUser != null && sessionUser.getFullName() != null) {
        for (String p : sessionUser.getFullName().split(" "))
            if (!p.isEmpty()) userInitials += p.charAt(0);
        if (userInitials.length() > 2) userInitials = userInitials.substring(0, 2);
    }
    userInitials = userInitials.toUpperCase();

    Sale sale = (Sale) request.getAttribute("sale");
    String ctx = request.getContextPath();

    /* If sale is null, show a not-found message */
    if (sale == null) {
        response.sendRedirect(ctx + "/sales?action=history&error=notfound");
        return;
    }

    List<SaleItem> items = sale.getItems();
    if (items == null) items = new java.util.ArrayList<>();

    /* Formatting helpers */
    DateTimeFormatter dtFmt  = DateTimeFormatter.ofPattern("dd MMMM yyyy, hh:mm a");
    DateTimeFormatter dateFmt = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    String saleDateTime = sale.getSaleDate() != null
        ? sale.getSaleDate().format(dtFmt) : "-";
    String saleDate = sale.getSaleDate() != null
        ? sale.getSaleDate().format(dateFmt) : "-";

    /* Null-safe values */
    BigDecimal subtotal     = sale.getSubtotal()       != null ? sale.getSubtotal()       : BigDecimal.ZERO;
    BigDecimal discount     = sale.getDiscountAmount() != null ? sale.getDiscountAmount() : BigDecimal.ZERO;
    BigDecimal tax          = sale.getTaxAmount()      != null ? sale.getTaxAmount()      : BigDecimal.ZERO;
    BigDecimal grandTotal   = sale.getTotalAmount()     != null ? sale.getTotalAmount()     : BigDecimal.ZERO;
    BigDecimal amountPaid   = sale.getAmountPaid()     != null ? sale.getAmountPaid()     : BigDecimal.ZERO;
    BigDecimal changeGiven  = sale.getChangeGiven()    != null ? sale.getChangeGiven()    : BigDecimal.ZERO;

    String custName   = sale.getCustomerName()  != null ? sale.getCustomerName()  : "Walk-in Customer";
    String custPhone  = sale.getCustomerPhone() != null ? sale.getCustomerPhone() : "";
    String payMethod  = sale.getPaymentMethod() != null ? sale.getPaymentMethod() : "CASH";
    String servedBy   = sale.getServedBy()      != null ? sale.getServedBy()      : (sessionUser != null ? sessionUser.getFullName() : "-");
    String notes      = sale.getNotes()         != null ? sale.getNotes()         : "";
    String status     = sale.getStatus()        != null ? sale.getStatus()        : "COMPLETED";
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Jare Pharmacy | Receipt <%= sale.getReceiptNumber() %></title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css">
<style>
/* ── global ─────────────────────────────────────────────────── */
*,*::before,*::after{box-sizing:border-box}
body,.content-wrapper,.main-sidebar,.main-header,.main-footer{
    font-family:'Inter',-apple-system,sans-serif!important}
body{background:#f1f5f9!important;color:#0f172a!important;font-size:13px!important}

/* ── sidebar (same as all pages) ───────────────────────────── */
.main-sidebar{background:#0f172a!important;box-shadow:none!important;width:230px!important}
.brand-link{background:#0f172a!important;border-bottom:1px solid rgba(255,255,255,.06)!important;
    padding:16px!important;display:flex!important;align-items:center!important;
    gap:10px!important;text-decoration:none!important}
.brand-logo-box{width:32px;height:32px;background:#2563eb;border-radius:9px;
    display:flex;align-items:center;justify-content:center;flex-shrink:0}
.brand-logo-box i{color:#fff;font-size:15px}
.brand-text-wrap .brand-name{font-size:15px;font-weight:700;color:#fff;display:block}
.brand-text-wrap .brand-sub{font-size:10px;color:#475569;display:block;margin-top:1px}
.user-panel{background:transparent!important;border-bottom:1px solid rgba(255,255,255,.06)!important;
    padding:12px 16px!important;display:flex;align-items:center;gap:10px}
.sb-avatar{width:32px;height:32px;border-radius:50%;background:#1e3a8a;display:flex;
    align-items:center;justify-content:center;font-size:12px;font-weight:700;
    color:#bfdbfe;flex-shrink:0}
.user-panel .info a{color:#cbd5e1!important;font-size:12.5px!important;font-weight:600!important;
    text-decoration:none!important;display:block}
.user-panel .info small{color:#475569;font-size:10.5px}
.nav-sidebar .nav-header{font-size:9.5px!important;font-weight:700!important;
    letter-spacing:.08em!important;color:#334155!important;text-transform:uppercase!important;
    padding:14px 16px 4px!important}
.nav-sidebar .nav-item .nav-link{color:#94a3b8!important;border-radius:8px!important;
    margin:1px 8px!important;padding:9px 12px!important;font-size:12.5px!important;
    border-left:2px solid transparent!important;display:flex!important;
    align-items:center!important;gap:9px!important;transition:all .12s!important}
.nav-sidebar .nav-item .nav-link:hover{background:rgba(255,255,255,.05)!important;color:#e2e8f0!important}
.nav-sidebar .nav-item .nav-link.active{background:rgba(37,99,235,.18)!important;
    color:#60a5fa!important;border-left-color:#2563eb!important}
.nav-sidebar .nav-link .nav-icon{font-size:14px!important;width:16px!important;flex-shrink:0}
.nav-sidebar .nav-link p{margin:0!important;font-size:12.5px!important;line-height:1!important}

/* ── topbar ─────────────────────────────────────────────────── */
.main-header.navbar{background:#fff!important;border-bottom:1px solid #e2e8f0!important;
    box-shadow:none!important;min-height:54px!important;padding:0 20px!important}
.topbar-breadcrumb{font-size:12px;color:#64748b;display:flex;align-items:center;
    gap:5px;margin-left:8px}
.topbar-breadcrumb a{color:#64748b;text-decoration:none}
.topbar-breadcrumb a:hover{color:#2563eb}
.crumb-active{color:#0f172a;font-weight:600}
.topbar-user-wrap{display:flex;align-items:center;gap:8px;cursor:pointer;
    padding:4px 8px;border-radius:9px;transition:background .12s}
.topbar-user-wrap:hover{background:#f1f5f9}
.topbar-avatar{width:32px;height:32px;border-radius:50%;background:#dbeafe;
    display:flex;align-items:center;justify-content:center;
    font-size:12px;font-weight:700;color:#1d4ed8;flex-shrink:0}
.topbar-user-name{font-size:12.5px;font-weight:600;color:#0f172a;line-height:1.2}
.topbar-user-role{font-size:10.5px;color:#94a3b8}

/* ── content wrapper ────────────────────────────────────────── */
.content-wrapper{background:#f1f5f9!important;padding:0!important}
.page-content{padding:22px 24px}

/* ── action toolbar (above receipt) ────────────────────────── */
.action-toolbar{display:flex;align-items:center;justify-content:space-between;
    margin-bottom:20px;flex-wrap:wrap;gap:12px}
.toolbar-left{display:flex;align-items:center;gap:10px;flex-wrap:wrap}
.toolbar-right{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
.toolbar-title h2{font-size:18px;font-weight:700;color:#0f172a;
    margin:0 0 3px;letter-spacing:-.01em}
.toolbar-title p{font-size:12px;color:#64748b;margin:0}

/* buttons */
.btn-pri{background:#2563eb;color:#fff;border:none;border-radius:8px;
    padding:9px 16px;font-size:13px;font-weight:600;cursor:pointer;
    display:inline-flex;align-items:center;gap:6px;text-decoration:none;
    transition:background .12s;font-family:'Inter',sans-serif}
.btn-pri:hover{background:#1d4ed8;color:#fff}
.btn-sec{background:#fff;color:#374151;border:1px solid #d1d5db;border-radius:8px;
    padding:9px 16px;font-size:13px;font-weight:500;cursor:pointer;
    display:inline-flex;align-items:center;gap:6px;text-decoration:none;
    transition:background .12s;font-family:'Inter',sans-serif}
.btn-sec:hover{background:#f9fafb;color:#111827}
.btn-amber{background:#d97706;color:#fff;border:none;border-radius:8px;
    padding:9px 16px;font-size:13px;font-weight:600;cursor:pointer;
    display:inline-flex;align-items:center;gap:6px;text-decoration:none;
    transition:background .12s;font-family:'Inter',sans-serif}
.btn-amber:hover{background:#b45309;color:#fff}
.btn-red{background:#dc2626;color:#fff;border:none;border-radius:8px;
    padding:9px 16px;font-size:13px;font-weight:600;cursor:pointer;
    display:inline-flex;align-items:center;gap:6px;text-decoration:none;
    transition:background .12s;font-family:'Inter',sans-serif}
.btn-red:hover{background:#b91c1c;color:#fff}

/* ── status banner (VOID / REFUNDED) ───────────────────────── */
.status-banner{display:flex;align-items:center;gap:12px;border-radius:12px;
    padding:14px 18px;margin-bottom:20px;font-size:13.5px;font-weight:600}
.banner-void    {background:#fef2f2;border:1.5px solid #fca5a5;color:#991b1b}
.banner-refunded{background:#fffbeb;border:1.5px solid #fcd34d;color:#92400e}
.banner-icon{width:38px;height:38px;border-radius:10px;display:flex;
    align-items:center;justify-content:center;font-size:18px;flex-shrink:0}
.banner-void     .banner-icon{background:#fecaca;color:#dc2626}
.banner-refunded .banner-icon{background:#fde68a;color:#d97706}
.banner-text p{margin:3px 0 0;font-size:12px;font-weight:400;opacity:.8}

/* ── two-column layout ──────────────────────────────────────── */
.receipt-layout{display:grid;grid-template-columns:1fr 340px;gap:18px;
    align-items:start}

/* ── receipt card (the printable area) ─────────────────────── */
.receipt-card{background:#fff;border:1px solid #e2e8f0;border-radius:14px;
    overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,.04)}

/* receipt header */
.receipt-header{background:linear-gradient(135deg,#0f172a 0%,#1e3a8a 100%);
    padding:28px 28px 24px;position:relative;overflow:hidden}
.receipt-header::before{content:'';position:absolute;top:-30px;right:-30px;
    width:120px;height:120px;border-radius:50%;
    background:rgba(255,255,255,.04)}
.receipt-header::after{content:'';position:absolute;bottom:-20px;right:40px;
    width:80px;height:80px;border-radius:50%;
    background:rgba(255,255,255,.03)}
.biz-logo{display:flex;align-items:center;gap:12px;margin-bottom:18px}
.biz-logo-icon{width:42px;height:42px;background:#2563eb;border-radius:11px;
    display:flex;align-items:center;justify-content:center;flex-shrink:0}
.biz-logo-icon i{color:#fff;font-size:19px}
.biz-name{font-size:18px;font-weight:700;color:#fff;letter-spacing:-.01em}
.biz-tag{font-size:11px;color:#94a3b8;margin-top:2px}
.biz-contact{display:flex;flex-wrap:wrap;gap:14px;margin-bottom:18px}
.biz-contact-item{display:flex;align-items:center;gap:5px;
    font-size:11px;color:#94a3b8}
.biz-contact-item i{font-size:10px}
.receipt-number-row{display:flex;align-items:center;justify-content:space-between;
    padding:12px 16px;background:rgba(255,255,255,.07);border-radius:9px}
.receipt-number{font-family:'Courier New',monospace;font-size:16px;
    font-weight:700;color:#fff;letter-spacing:.04em}
.receipt-date-text{font-size:11px;color:#94a3b8;text-align:right}

/* status stamp on receipt */
.receipt-stamp{position:absolute;top:18px;right:18px;padding:5px 12px;
    border-radius:20px;font-size:10px;font-weight:700;letter-spacing:.06em;
    text-transform:uppercase;border:1.5px solid}
.stamp-completed{background:rgba(34,197,94,.15);color:#4ade80;border-color:#4ade80}
.stamp-void     {background:rgba(239,68,68,.2); color:#f87171;border-color:#f87171}
.stamp-refunded {background:rgba(251,191,36,.2);color:#fbbf24;border-color:#fbbf24}

/* receipt body sections */
.receipt-body{padding:0}
.receipt-section{padding:18px 24px;border-bottom:1px solid #f1f5f9}
.receipt-section:last-child{border-bottom:none}
.section-label{font-size:10px;font-weight:700;color:#94a3b8;
    text-transform:uppercase;letter-spacing:.07em;margin-bottom:10px;
    display:flex;align-items:center;gap:6px}
.section-label i{font-size:11px}

/* customer info grid */
.info-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.info-item{display:flex;flex-direction:column;gap:2px}
.info-item-label{font-size:10.5px;color:#94a3b8}
.info-item-value{font-size:13px;font-weight:600;color:#0f172a}

/* items table */
.items-table{width:100%;border-collapse:collapse}
.items-table thead th{font-size:10px;font-weight:700;color:#94a3b8;
    text-transform:uppercase;letter-spacing:.06em;padding:6px 0;
    border-bottom:1px solid #e2e8f0;text-align:left}
.items-table thead th.num{text-align:right}
.items-table tbody tr{border-bottom:1px solid #f8fafc}
.items-table tbody tr:last-child{border-bottom:none}
.items-table tbody td{padding:11px 0;font-size:13px;color:#1e293b;
    vertical-align:top}
.item-name{font-weight:600;color:#0f172a;line-height:1.3}
.item-meta{font-size:11px;color:#94a3b8;margin-top:2px;font-family:monospace}
.item-qty{font-size:12.5px;font-weight:600;color:#64748b;text-align:center}
.item-price{font-size:12.5px;color:#374151;text-align:right}
.item-total{font-size:13px;font-weight:700;color:#0f172a;text-align:right}
.item-discount{font-size:10.5px;color:#dc2626;font-weight:600}

/* totals section */
.totals-table{width:100%;border-collapse:collapse}
.totals-table tr td{padding:5px 0;font-size:13px}
.totals-table tr td:last-child{text-align:right;font-weight:500;color:#0f172a}
.totals-table tr td:first-child{color:#64748b}
.totals-divider{border-top:1px solid #e2e8f0;margin:8px 0}
.grand-row td{font-size:16px!important;font-weight:700!important;
    padding-top:10px!important}
.grand-row td:last-child{color:#0f172a!important}
.change-row td{color:#059669!important;font-weight:600!important}

/* payment method badge in totals */
.pay-method-row{display:flex;align-items:center;justify-content:space-between;
    background:#f8fafc;border-radius:9px;padding:10px 14px;margin-top:8px}
.pay-method-label{font-size:11.5px;color:#64748b;display:flex;align-items:center;gap:6px}
.pay-method-value{font-size:12px;font-weight:700;padding:4px 10px;border-radius:20px}
.pay-cash    {background:#f0fdf4;color:#15803d}
.pay-transfer{background:#eff6ff;color:#1d4ed8}
.pay-pos     {background:#faf5ff;color:#7c3aed}
.pay-credit  {background:#fffbeb;color:#b45309}

/* receipt footer */
.receipt-footer{background:#f8fafc;padding:18px 24px;text-align:center;
    border-top:1px dashed #e2e8f0}
.receipt-footer p{font-size:12px;color:#64748b;margin:0 0 6px;line-height:1.5}
.receipt-footer .tagline{font-size:11px;color:#94a3b8;margin:0}
.receipt-barcode{font-family:'Courier New',monospace;font-size:13px;
    color:#64748b;letter-spacing:.15em;margin:8px 0;font-weight:600}

/* ── side panel (info cards) ────────────────────────────────── */
.side-panel{display:flex;flex-direction:column;gap:14px}
.info-card{background:#fff;border:1px solid #e2e8f0;border-radius:12px;
    overflow:hidden}
.info-card-header{padding:12px 16px;border-bottom:1px solid #f1f5f9;
    display:flex;align-items:center;gap:8px}
.info-card-header h4{font-size:12.5px;font-weight:700;color:#0f172a;margin:0}
.info-card-header i{font-size:14px;color:#94a3b8}
.info-card-body{padding:14px 16px}

/* detail rows in side card */
.detail-row{display:flex;align-items:flex-start;justify-content:space-between;
    gap:8px;padding:5px 0;border-bottom:1px solid #f8fafc;font-size:12.5px}
.detail-row:last-child{border-bottom:none;padding-bottom:0}
.detail-key{color:#64748b;flex-shrink:0}
.detail-val{color:#0f172a;font-weight:500;text-align:right}

/* timeline in side card */
.timeline{display:flex;flex-direction:column;gap:0}
.tl-item{display:flex;gap:12px;padding-bottom:14px;position:relative}
.tl-item:last-child{padding-bottom:0}
.tl-item::before{content:'';position:absolute;left:11px;top:22px;
    bottom:0;width:1.5px;background:#e2e8f0}
.tl-item:last-child::before{display:none}
.tl-dot{width:24px;height:24px;border-radius:50%;display:flex;align-items:center;
    justify-content:center;font-size:10px;flex-shrink:0;z-index:1}
.tl-dot.green{background:#d1fae5;color:#059669}
.tl-dot.blue {background:#dbeafe;color:#2563eb}
.tl-dot.red  {background:#fee2e2;color:#dc2626}
.tl-dot.amber{background:#fde68a;color:#d97706}
.tl-content{flex:1;min-width:0}
.tl-title{font-size:12.5px;font-weight:600;color:#0f172a}
.tl-time {font-size:11px;color:#94a3b8;margin-top:1px}

/* profit insight card */
.profit-card{background:linear-gradient(135deg,#f0fdf4,#dcfce7);
    border:1px solid #bbf7d0;border-radius:12px;padding:16px}
.profit-card h4{font-size:12px;font-weight:700;color:#065f46;
    text-transform:uppercase;letter-spacing:.05em;margin:0 0 10px}
.profit-row{display:flex;justify-content:space-between;
    font-size:12.5px;margin-bottom:6px}
.profit-row:last-child{margin-bottom:0}
.profit-label{color:#16a34a}
.profit-value{font-weight:700;color:#065f46}

/* notes card */
.notes-card{background:#fffbeb;border:1px solid #fcd34d;border-radius:10px;
    padding:14px 16px}
.notes-card h4{font-size:11px;font-weight:700;color:#92400e;
    text-transform:uppercase;letter-spacing:.05em;margin:0 0 6px;
    display:flex;align-items:center;gap:6px}
.notes-card p{font-size:12.5px;color:#78350f;margin:0;line-height:1.6}

/* ── footer ─────────────────────────────────────────────────── */
.main-footer{background:#fff!important;border-top:1px solid #e2e8f0!important;
    padding:12px 24px!important;font-size:11.5px!important;
    color:#94a3b8!important;text-align:center!important}

/* ── PRINT STYLES ───────────────────────────────────────────── */
@media print {
    .main-sidebar,
    .main-header,
    .main-footer,
    .action-toolbar,
    .side-panel,
    .status-banner,
    body>.wrapper>.main-header { display:none!important }

    body,.content-wrapper{background:#fff!important;margin:0!important;padding:0!important}
    .content-wrapper{margin-left:0!important}
    .page-content{padding:0!important}
    .receipt-layout{grid-template-columns:1fr;display:block}
    .receipt-card{border:none!important;box-shadow:none!important;
        border-radius:0!important;max-width:80mm;margin:0 auto}
    .receipt-header{-webkit-print-color-adjust:exact;print-color-adjust:exact}
    @page{margin:8mm;size:A5 portrait}
}

/* ── responsive ─────────────────────────────────────────────── */
@media(max-width:900px){
    .receipt-layout{grid-template-columns:1fr}
    .side-panel{display:grid;grid-template-columns:1fr 1fr;gap:14px}
}
@media(max-width:600px){
    .side-panel{grid-template-columns:1fr}
    .info-grid{grid-template-columns:1fr}
}
</style>
</head>
<body class="hold-transition sidebar-mini layout-fixed layout-navbar-fixed">
<div class="wrapper">

<%-- ══════════ TOPBAR ══════════ --%>
<nav class="main-header navbar navbar-expand navbar-white navbar-light">
    <ul class="navbar-nav align-items-center">
        <li class="nav-item">
            <a class="nav-link px-2" data-widget="pushmenu" href="#" role="button">
                <i class="fas fa-bars" style="color:#64748b;font-size:16px"></i>
            </a>
        </li>
        <li class="nav-item d-none d-sm-flex align-items-center">
            <div class="topbar-breadcrumb">
                <i class="fas fa-home" style="font-size:12px;color:#94a3b8"></i>
                <span style="color:#cbd5e1">/</span>
                <a href="<%= ctx %>/dashboard">Dashboard</a>
                <span style="color:#cbd5e1">/</span>
                <a href="<%= ctx %>/sales?action=history">Sales</a>
                <span style="color:#cbd5e1">/</span>
                <span class="crumb-active"><%= sale.getReceiptNumber() %></span>
            </div>
        </li>
    </ul>
    <ul class="navbar-nav ml-auto align-items-center" style="gap:12px">
        <li class="nav-item dropdown">
            <a href="#" class="nav-link p-0" data-toggle="dropdown">
                <div class="topbar-user-wrap">
                    <div class="topbar-avatar"><%= userInitials %></div>
                    <div class="d-none d-sm-block">
                        <div class="topbar-user-name">
                            <%= sessionUser != null ? sessionUser.getFullName() : "User" %>
                        </div>
                        <div class="topbar-user-role">
                            <%= sessionUser != null ? sessionUser.getRole() : "" %>
                        </div>
                    </div>
                </div>
            </a>
            <div class="dropdown-menu dropdown-menu-right border-0"
                 style="box-shadow:0 8px 24px rgba(0,0,0,.12);min-width:180px;
                        margin-top:6px;border-radius:12px">
                <div class="dropdown-divider m-0"></div>
                <a href="<%= ctx %>/logout" class="dropdown-item py-2"
                   style="font-size:13px;color:#dc2626">
                    <i class="fas fa-sign-out-alt mr-2"></i>Sign out
                </a>
            </div>
        </li>
    </ul>
</nav>

<%-- ══════════ SIDEBAR ══════════ --%>
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
            <div class="sb-avatar"><%= userInitials %></div>
            <div class="info">
                <a href="#"><%= sessionUser != null ? sessionUser.getFullName() : "User" %></a>
                <small><%= sessionUser != null ? sessionUser.getRole() : "" %></small>
            </div>
        </div>
        <nav class="mt-1">
            <ul class="nav nav-pills nav-sidebar flex-column"
                data-widget="treeview" role="menu">
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
                        <i class="nav-icon fas fa-cash-register"></i><p>Point of sale</p>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="<%= ctx %>/inventory?action=list" class="nav-link">
                        <i class="nav-icon fas fa-warehouse"></i><p>Inventory</p>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="<%= ctx %>/sales?action=history" class="nav-link active">
                        <i class="nav-icon fas fa-file-invoice-dollar"></i><p>Sales history</p>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="<%= ctx %>/reports.jsp" class="nav-link">
                        <i class="nav-icon fas fa-chart-bar"></i><p>Reports</p>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="<%= ctx %>/logout" class="nav-link">
                        <i class="nav-icon fas fa-sign-out-alt"></i><p>Sign out</p>
                    </a>
                </li>
            </ul>
        </nav>
    </div>
</aside>

<%-- ══════════ MAIN CONTENT ══════════ --%>
<div class="content-wrapper">
<div class="page-content">

    <%-- Action toolbar --%>
    <div class="action-toolbar">
        <div class="toolbar-left">
            <a href="<%= ctx %>/sales?action=history" class="btn-sec">
                <i class="fas fa-arrow-left" style="font-size:11px"></i> Back
            </a>
            <div class="toolbar-title">
                <h2>
                    <i class="fas fa-receipt"
                       style="font-size:16px;color:#2563eb;margin-right:6px"></i>
                    Receipt - <%= sale.getReceiptNumber() %>
                </h2>
                <p>Sale processed on <%= saleDateTime %></p>
            </div>
        </div>
        <div class="toolbar-right">
            <button onclick="window.print()" class="btn-sec">
                <i class="fas fa-print"></i> Print
            </button>
            <button onclick="shareReceipt()" class="btn-sec">
                <i class="fas fa-share-nodes"></i> Share
            </button>
            <% if (!"VOID".equals(status) && !"REFUNDED".equals(status)) { %>
            <button onclick="confirmVoidRefund()" class="btn-amber">
                <i class="fas fa-rotate-left"></i> Refund / Void
            </button>
            <% } %>
            <a href="<%= ctx %>/sales?action=pos" class="btn-pri">
                <i class="fas fa-plus"></i> New sale
            </a>
        </div>
    </div>

    <%-- Status banner for voided / refunded sales --%>
    <% if ("VOID".equals(status)) { %>
    <div class="status-banner banner-void">
        <div class="banner-icon"><i class="fas fa-ban"></i></div>
        <div>
            This sale was <strong>VOIDED</strong> - it was entered by mistake
            and the customer did not receive any goods.
            <p>Stock has been fully restored to inventory.</p>
        </div>
    </div>
    <% } else if ("REFUNDED".equals(status)) { %>
    <div class="status-banner banner-refunded">
        <div class="banner-icon"><i class="fas fa-rotate-left"></i></div>
        <div>
            This sale was <strong>REFUNDED</strong> - the customer returned
            the goods and payment was reversed.
            <p>Stock has been fully restored to inventory.</p>
        </div>
    </div>
    <% } %>

    <%-- Two-column layout --%>
    <div class="receipt-layout">

        <%-- ════ LEFT: PRINTABLE RECEIPT ════ --%>
        <div class="receipt-card" id="receiptPrintArea">

            <%-- Receipt header --%>
            <div class="receipt-header">

                <%-- Status stamp --%>
                <span class="receipt-stamp stamp-<%= status.toLowerCase() %>">
                    <%= status %>
                </span>

                <%-- Business identity --%>
                <div class="biz-logo">
                    <div class="biz-logo-icon">
                        <i class="fas fa-cubes"></i>
                    </div>
                    <div>
                        <div class="biz-name">Jare Pharmacy Store</div>
                        <div class="biz-tag">SME Inventory Management System</div>
                    </div>
                </div>

                <div class="biz-contact">
                    <div class="biz-contact-item">
                        <i class="fas fa-location-dot"></i>
                        Lagos, Nigeria
                    </div>
                    <div class="biz-contact-item">
                        <i class="fas fa-phone"></i>
                        +234 800 000 0000
                    </div>
                    <div class="biz-contact-item">
                        <i class="fas fa-envelope"></i>
                        store@JarePharmacy.ng
                    </div>
                </div>

                <div class="receipt-number-row">
                    <div>
                        <div style="font-size:10px;color:#94a3b8;
                                    text-transform:uppercase;letter-spacing:.06em;
                                    margin-bottom:4px">Receipt No.</div>
                        <div class="receipt-number">
                            <%= sale.getReceiptNumber() %>
                        </div>
                    </div>
                    <div class="receipt-date-text">
                        <div><%= saleDate %></div>
                        <div style="margin-top:2px">
                            <%= sale.getSaleDate() != null
                                ? sale.getSaleDate().format(
                                    DateTimeFormatter.ofPattern("hh:mm a")) : "" %>
                        </div>
                    </div>
                </div>
            </div>

            <%-- Customer + transaction info --%>
            <div class="receipt-section">
                <div class="section-label">
                    <i class="fas fa-user"></i> Customer & transaction
                </div>
                <div class="info-grid">
                    <div class="info-item">
                        <span class="info-item-label">Customer name</span>
                        <span class="info-item-value"><%= custName %></span>
                    </div>
                    <% if (!custPhone.isEmpty()) { %>
                    <div class="info-item">
                        <span class="info-item-label">Phone</span>
                        <span class="info-item-value"><%= custPhone %></span>
                    </div>
                    <% } %>
                    <div class="info-item">
                        <span class="info-item-label">Served by</span>
                        <span class="info-item-value"><%= servedBy %></span>
                    </div>
                    <div class="info-item">
                        <span class="info-item-label">Date & time</span>
                        <span class="info-item-value" style="font-size:12px">
                            <%= saleDateTime %>
                        </span>
                    </div>
                </div>
            </div>

            <%-- Items --%>
            <div class="receipt-section">
                <div class="section-label">
                    <i class="fas fa-box"></i>
                    Items purchased
                    <span style="font-weight:400;color:#94a3b8;margin-left:4px">
                        (<%= items.size() %> line<%= items.size() != 1 ? "s" : "" %>)
                    </span>
                </div>
                <table class="items-table">
                    <thead>
                        <tr>
                            <th style="width:44%">Product</th>
                            <th style="width:10%;text-align:center">Qty</th>
                            <th style="width:20%;text-align:right">Unit price</th>
                            <th style="width:10%;text-align:right">Disc%</th>
                            <th style="width:16%;text-align:right">Total</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        int lineNum = 1;
                        for (SaleItem item : items) {
                            BigDecimal lineTotal    = item.getLineTotal()    != null ? item.getLineTotal()    : BigDecimal.ZERO;
                            BigDecimal unitPrice    = item.getUnitPrice()    != null ? item.getUnitPrice()    : BigDecimal.ZERO;
                            BigDecimal discountPct  = item.getDiscountPct()  != null ? item.getDiscountPct()  : BigDecimal.ZERO;
                            String sku = item.getProductSku() != null ? item.getProductSku() : "";
                    %>
                        <tr>
                            <td>
                                <div class="item-name">
                                    <%= item.getProductName() %>
                                </div>
                                <% if (!sku.isEmpty()) { %>
                                <div class="item-meta"><%= sku %></div>
                                <% } %>
                            </td>
                            <td class="item-qty"><%= item.getQuantity() %></td>
                            <td class="item-price">
                                &#x20A6;<%= String.format("%,.2f", unitPrice) %>
                            </td>
                            <td style="text-align:right">
                                <% if (discountPct.compareTo(BigDecimal.ZERO) > 0) { %>
                                <span class="item-discount">
                                    -<%= String.format("%.1f", discountPct) %>%
                                </span>
                                <% } else { %>
                                <span style="color:#d1d5db">-</span>
                                <% } %>
                            </td>
                            <td class="item-total">
                                &#x20A6;<%= String.format("%,.2f", lineTotal) %>
                            </td>
                        </tr>
                    <%
                            lineNum++;
                        }
                    %>
                    </tbody>
                </table>
            </div>

            <%-- Totals --%>
            <div class="receipt-section">
                <table class="totals-table">
                    <tr>
                        <td>Subtotal</td>
                        <td>&#x20A6;<%= String.format("%,.2f", subtotal) %></td>
                    </tr>
                    <% if (discount.compareTo(BigDecimal.ZERO) > 0) { %>
                    <tr>
                        <td style="color:#dc2626">Discount</td>
                        <td style="color:#dc2626">
                            -&#x20A6;<%= String.format("%,.2f", discount) %>
                        </td>
                    </tr>
                    <% } %>
                    <% if (tax.compareTo(BigDecimal.ZERO) > 0) { %>
                    <tr>
                        <td>Tax / VAT</td>
                        <td>&#x20A6;<%= String.format("%,.2f", tax) %></td>
                    </tr>
                    <% } %>
                </table>

                <div class="totals-divider"></div>

                <table class="totals-table">
                    <tr class="grand-row">
                        <td><strong>Grand total</strong></td>
                        <td>
                            <strong>&#x20A6;<%= String.format("%,.2f", grandTotal) %></strong>
                        </td>
                    </tr>
                    <tr>
                        <td style="color:#64748b">Amount paid</td>
                        <td>&#x20A6;<%= String.format("%,.2f", amountPaid) %></td>
                    </tr>
                    <% if (changeGiven.compareTo(BigDecimal.ZERO) > 0) { %>
                    <tr class="change-row">
                        <td>Change given</td>
                        <td>&#x20A6;<%= String.format("%,.2f", changeGiven) %></td>
                    </tr>
                    <% } %>
                </table>

                <div class="pay-method-row">
                    <span class="pay-method-label">
                        <i class="fas fa-<%= "CASH".equals(payMethod) ? "money-bill-wave"
                            : "TRANSFER".equals(payMethod) ? "building-columns"
                            : "POS".equals(payMethod) ? "credit-card"
                            : "handshake" %>"></i>
                        Payment method
                    </span>
                    <span class="pay-method-value pay-<%= payMethod.toLowerCase() %>">
                        <%= payMethod %>
                    </span>
                </div>
            </div>

            <%-- Notes (if any) --%>
            <% if (!notes.isEmpty()) { %>
            <div class="receipt-section">
                <div class="section-label">
                    <i class="fas fa-note-sticky"></i> Notes
                </div>
                <p style="font-size:13px;color:#374151;margin:0;line-height:1.6">
                    <%= notes %>
                </p>
            </div>
            <% } %>

            <%-- Receipt footer --%>
            <div class="receipt-footer">
                <div class="receipt-barcode">
                    | | |  <%= sale.getReceiptNumber() %>  | | |
                </div>
                <p>Thank you for shopping with us!</p>
                <p>Please retain this receipt for returns &amp; exchanges.</p>
                <p class="tagline">Powered by Jare Pharmacy - Jare Pharmacy.ng</p>
            </div>

        </div><%-- /receipt-card --%>

        <%-- ════ RIGHT: SIDE PANEL ════ --%>
        <div class="side-panel">

            <%-- Transaction details card --%>
            <div class="info-card">
                <div class="info-card-header">
                    <i class="fas fa-circle-info"></i>
                    <h4>Transaction details</h4>
                </div>
                <div class="info-card-body">
                    <div class="detail-row">
                        <span class="detail-key">Sale ID</span>
                        <span class="detail-val">#<%= sale.getId() %></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-key">Receipt no.</span>
                        <span class="detail-val"
                              style="font-family:monospace;font-size:11.5px">
                            <%= sale.getReceiptNumber() %>
                        </span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-key">Date</span>
                        <span class="detail-val"><%= saleDateTime %></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-key">Served by</span>
                        <span class="detail-val"><%= servedBy %></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-key">Payment</span>
                        <span class="detail-val">
                            <span class="pay-method-value pay-<%= payMethod.toLowerCase() %>"
                                  style="font-size:11px">
                                <%= payMethod %>
                            </span>
                        </span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-key">Status</span>
                        <span class="detail-val">
                            <%
                                String detailBadge = "COMPLETED".equals(status)
                                    ? "background:#f0fdf4;color:#15803d"
                                    : "REFUNDED".equals(status)
                                    ? "background:#fffbeb;color:#b45309"
                                    : "background:#fef2f2;color:#dc2626";
                            %>
                            <span style="font-size:10.5px;font-weight:700;
                                         padding:3px 9px;border-radius:20px;
                                         <%= detailBadge %>">
                                <%= status %>
                            </span>
                        </span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-key">Items sold</span>
                        <span class="detail-val"><%= items.size() %> line(s)</span>
                    </div>
                </div>
            </div>

            <%-- Profit insight card (only for completed sales) --%>
            <% if ("COMPLETED".equals(status) && !items.isEmpty()) {
                BigDecimal totalCost   = BigDecimal.ZERO;
                BigDecimal totalRevRaw = BigDecimal.ZERO;
                for (SaleItem si : items) {
                    BigDecimal cost = si.getCostPrice() != null ? si.getCostPrice() : BigDecimal.ZERO;
                    BigDecimal qty  = BigDecimal.valueOf(si.getQuantity());
                    BigDecimal rev  = si.getLineTotal() != null ? si.getLineTotal() : BigDecimal.ZERO;
                    totalCost   = totalCost.add(cost.multiply(qty));
                    totalRevRaw = totalRevRaw.add(rev);
                }
                BigDecimal grossProfit = totalRevRaw.subtract(totalCost);
                BigDecimal marginPct   = totalRevRaw.compareTo(BigDecimal.ZERO) > 0
                    ? grossProfit.divide(totalRevRaw, 4, java.math.RoundingMode.HALF_UP)
                             .multiply(BigDecimal.valueOf(100))
                    : BigDecimal.ZERO;
            %>
            <div class="profit-card">
                <h4><i class="fas fa-chart-line" style="margin-right:5px"></i>Profit insight</h4>
                <div class="profit-row">
                    <span class="profit-label">Revenue</span>
                    <span class="profit-value">&#x20A6;<%= String.format("%,.2f", totalRevRaw) %></span>
                </div>
                <div class="profit-row">
                    <span class="profit-label">Cost of goods</span>
                    <span class="profit-value"
                          style="color:#dc2626">&#x20A6;<%= String.format("%,.2f", totalCost) %></span>
                </div>
                <div style="border-top:1px solid #bbf7d0;margin:8px 0"></div>
                <div class="profit-row">
                    <span class="profit-label" style="font-weight:700">Gross profit</span>
                    <span class="profit-value" style="font-size:15px">
                        &#x20A6;<%= String.format("%,.2f", grossProfit) %>
                    </span>
                </div>
                <div class="profit-row">
                    <span class="profit-label">Margin</span>
                    <span class="profit-value">
                        <%= String.format("%.1f", marginPct) %>%
                    </span>
                </div>
            </div>
            <% } %>

            <%-- Notes on side panel --%>
            <% if (!notes.isEmpty()) { %>
            <div class="notes-card">
                <h4><i class="fas fa-note-sticky"></i> Notes</h4>
                <p><%= notes %></p>
            </div>
            <% } %>

            <%-- Quick actions card --%>
            <div class="info-card">
                <div class="info-card-header">
                    <i class="fas fa-bolt"></i>
                    <h4>Quick actions</h4>
                </div>
                <div class="info-card-body" style="display:flex;flex-direction:column;gap:8px">
                    <button onclick="window.print()"
                        style="width:100%;height:38px;background:#f1f5f9;color:#374151;
                               border:1px solid #e2e8f0;border-radius:8px;font-size:12.5px;
                               font-weight:600;cursor:pointer;font-family:'Inter',sans-serif;
                               display:flex;align-items:center;justify-content:center;gap:6px;
                               transition:background .12s">
                        <i class="fas fa-print" style="color:#2563eb"></i>
                        Print receipt
                    </button>
                    <button onclick="shareReceipt()"
                        style="width:100%;height:38px;background:#f1f5f9;color:#374151;
                               border:1px solid #e2e8f0;border-radius:8px;font-size:12.5px;
                               font-weight:600;cursor:pointer;font-family:'Inter',sans-serif;
                               display:flex;align-items:center;justify-content:center;gap:6px;
                               transition:background .12s">
                        <i class="fas fa-share-nodes" style="color:#7c3aed"></i>
                        Share / copy link
                    </button>
                    <a href="<%= ctx %>/sales?action=pos"
                        style="width:100%;height:38px;background:#eff6ff;color:#1d4ed8;
                               border:1px solid #bfdbfe;border-radius:8px;font-size:12.5px;
                               font-weight:600;cursor:pointer;font-family:'Inter',sans-serif;
                               display:flex;align-items:center;justify-content:center;gap:6px;
                               text-decoration:none;transition:background .12s">
                        <i class="fas fa-cash-register"></i>
                        New sale
                    </a>
                    <% if (!"VOID".equals(status) && !"REFUNDED".equals(status)) { %>
                    <button onclick="confirmVoidRefund()"
                        style="width:100%;height:38px;background:#fef2f2;color:#dc2626;
                               border:1px solid #fecaca;border-radius:8px;font-size:12.5px;
                               font-weight:600;cursor:pointer;font-family:'Inter',sans-serif;
                               display:flex;align-items:center;justify-content:center;gap:6px;
                               transition:background .12s">
                        <i class="fas fa-rotate-left"></i>
                        Void / refund sale
                    </button>
                    <% } %>
                </div>
            </div>

        </div><%-- /side-panel --%>

    </div><%-- /receipt-layout --%>

</div><%-- /page-content --%>
</div><%-- /content-wrapper --%>

<footer class="main-footer">
    <strong>Jare Pharmacy Inventory System</strong>
    - &copy; 2025 Built for Nigerian SMEs
</footer>
</div><%-- /wrapper --%>

<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.4/jquery.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/4.6.2/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<script>
// ── Void / Refund picker ─────────────────────────────────────
function confirmVoidRefund() {
    Swal.fire({
        title: 'Void or refund this sale?',
        html:
            '<p style="color:#64748b;font-size:13px;margin-bottom:14px">' +
            'Receipt <strong style="color:#0f172a;font-family:monospace">' +
            '<%= sale.getReceiptNumber() %></strong> - ' +
            '<strong>&#x20A6;<%= String.format("%,.2f", grandTotal) %></strong></p>' +
            '<div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">' +

            '<div onclick="doAction(\'void\')" ' +
            'style="border:1.5px solid #fecaca;border-radius:10px;padding:14px;' +
            'cursor:pointer;text-align:left" ' +
            'onmouseover="this.style.background=\'#fef2f2\'" ' +
            'onmouseout="this.style.background=\'transparent\'">' +
            '<div style="font-size:18px;color:#dc2626;margin-bottom:6px">' +
            '<i class="fas fa-ban"></i></div>' +
            '<div style="font-weight:700;color:#0f172a;margin-bottom:4px">Void sale</div>' +
            '<div style="font-size:11.5px;color:#64748b;line-height:1.5">' +
            'Entered by mistake. Customer never received goods.</div>' +
            '</div>' +

            '<div onclick="doAction(\'refund\')" ' +
            'style="border:1.5px solid #fcd34d;border-radius:10px;padding:14px;' +
            'cursor:pointer;text-align:left" ' +
            'onmouseover="this.style.background=\'#fffbeb\'" ' +
            'onmouseout="this.style.background=\'transparent\'">' +
            '<div style="font-size:18px;color:#d97706;margin-bottom:6px">' +
            '<i class="fas fa-rotate-left"></i></div>' +
            '<div style="font-weight:700;color:#0f172a;margin-bottom:4px">Refund sale</div>' +
            '<div style="font-size:11.5px;color:#64748b;line-height:1.5">' +
            'Customer returned goods. Money given back.</div>' +
            '</div>' +

            '</div>' +
            '<p style="color:#94a3b8;font-size:11.5px;margin-top:12px;margin-bottom:0">' +
            '<i class="fas fa-circle-info" style="margin-right:4px"></i>' +
            'Both actions restore stock to inventory and cannot be undone.</p>',
        showConfirmButton: false,
        showCancelButton:  true,
        cancelButtonText:  'Cancel',
        cancelButtonColor: '#f1f5f9'
    });
}

function doAction(action) {
    Swal.close();
    window.location.href =
        '<%= ctx %>/sales?action=' + action + '&id=<%= sale.getId() %>';
}

// ── Copy / share receipt link ────────────────────────────────
function shareReceipt() {
    var url = window.location.href;
    if (navigator.clipboard) {
        navigator.clipboard.writeText(url).then(function () {
            Swal.fire({
                title: 'Link copied!',
                text:  'Receipt URL copied to clipboard.',
                icon:  'success',
                timer: 1800,
                showConfirmButton: false
            });
        });
    } else {
        Swal.fire({
            title: 'Receipt URL',
            input: 'text',
            inputValue: url,
            confirmButtonText: 'Close',
            confirmButtonColor: '#2563eb'
        });
    }
}
</script>
</body>
</html>
