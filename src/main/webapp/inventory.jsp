<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core"      prefix="c"   %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"  %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"       prefix="fmt" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Jare Pharmacy | Inventory Transactions</title>

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
    <link rel="stylesheet" href="https://cdn.datatables.net/1.13.4/css/dataTables.bootstrap4.min.css">
    <link rel="stylesheet" href="https://cdn.datatables.net/responsive/2.4.1/css/responsive.bootstrap4.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css">

<style>
/* ================================================================
   GLOBAL - matches dashboard.jsp and product-form.jsp exactly
================================================================ */
*, *::before, *::after { box-sizing: border-box; }
body, .content-wrapper, .main-sidebar, .main-header, .main-footer {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif !important;
}
body { background-color: #f1f5f9 !important; color: #0f172a !important; font-size: 13px !important; }

/* ================================================================
   SIDEBAR
================================================================ */
.main-sidebar { background-color: #0f172a !important; box-shadow: none !important; border-right: none !important; width: 230px !important; }
.brand-link { background-color: #0f172a !important; border-bottom: 1px solid rgba(255,255,255,.06) !important; padding: 16px !important; display: flex !important; align-items: center !important; gap: 10px !important; text-decoration: none !important; }
.brand-logo-box { width: 32px; height: 32px; background: #2563eb; border-radius: 9px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.brand-logo-box i { color: #fff; font-size: 15px; }
.brand-text-wrap .brand-name { font-size: 15px; font-weight: 700; color: #fff; letter-spacing: -0.01em; display: block; }
.brand-text-wrap .brand-sub  { font-size: 10px; color: #475569; font-weight: 400; display: block; margin-top: 1px; }
.user-panel { background: transparent !important; border-bottom: 1px solid rgba(255,255,255,.06) !important; padding: 12px 16px !important; display: flex; align-items: center; gap: 10px; }
.sidebar-user-avatar { width: 32px; height: 32px; border-radius: 50%; background: #1e3a8a; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 700; color: #bfdbfe; flex-shrink: 0; }
.user-panel .info a { color: #cbd5e1 !important; font-size: 12.5px !important; font-weight: 600 !important; text-decoration: none !important; display: block; }
.user-panel .info small { color: #475569; font-size: 10.5px; }
.nav-sidebar .nav-header { font-size: 9.5px !important; font-weight: 700 !important; letter-spacing: .08em !important; color: #334155 !important; text-transform: uppercase !important; padding: 14px 16px 4px !important; }
.nav-sidebar .nav-item .nav-link { color: #94a3b8 !important; border-radius: 8px !important; margin: 1px 8px !important; padding: 9px 12px !important; font-size: 12.5px !important; font-weight: 400 !important; border-left: 2px solid transparent !important; display: flex !important; align-items: center !important; gap: 9px !important; transition: all .12s ease !important; }
.nav-sidebar .nav-item .nav-link:hover { background: rgba(255,255,255,.05) !important; color: #e2e8f0 !important; }
.nav-sidebar .nav-item .nav-link.active { background: rgba(37,99,235,.18) !important; color: #60a5fa !important; border-left-color: #2563eb !important; }
.nav-sidebar .nav-link .nav-icon { font-size: 14px !important; width: 16px !important; text-align: center; flex-shrink: 0; }
.nav-sidebar .nav-link p { margin: 0 !important; font-size: 12.5px !important; line-height: 1 !important; }
.nav-alert-badge { margin-left: auto; background: #dc2626; color: #fff; font-size: 9px; font-weight: 700; padding: 2px 7px; border-radius: 20px; line-height: 1.4; }

/* ================================================================
   NAVBAR
================================================================ */
.main-header.navbar { background: #ffffff !important; border-bottom: 1px solid #e2e8f0 !important; box-shadow: none !important; min-height: 54px !important; padding: 0 20px !important; }
.topbar-breadcrumb { font-size: 12px; color: #64748b; display: flex; align-items: center; gap: 5px; margin-left: 8px; }
.topbar-breadcrumb .crumb-active { color: #0f172a; font-weight: 600; }
.topbar-user-wrap { display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 4px 8px; border-radius: 9px; transition: background .12s; }
.topbar-user-wrap:hover { background: #f1f5f9; }
.topbar-avatar { width: 32px; height: 32px; border-radius: 50%; background: #dbeafe; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 700; color: #1d4ed8; flex-shrink: 0; }
.topbar-user-name { font-size: 12.5px; font-weight: 600; color: #0f172a; line-height: 1.2; }
.topbar-user-role { font-size: 10.5px; color: #94a3b8; }

/* ================================================================
   CONTENT
================================================================ */
.content-wrapper { background: #f1f5f9 !important; padding: 0 !important; }
.page-content { padding: 22px 24px; }
.page-heading { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 20px; flex-wrap: wrap; gap: 12px; }
.page-heading h2 { font-size: 20px; font-weight: 700; color: #0f172a; margin: 0 0 3px 0; letter-spacing: -0.01em; }
.heading-breadcrumb { display: flex; align-items: center; gap: 6px; font-size: 11.5px; color: #94a3b8; margin-top: 4px; }
.heading-breadcrumb a { color: #2563eb; text-decoration: none; font-weight: 500; }
.heading-breadcrumb a:hover { text-decoration: underline; }
.heading-actions { display: flex; gap: 8px; flex-wrap: wrap; }

/* ================================================================
   KPI STAT CARDS
================================================================ */
.stat-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; margin-bottom: 22px; }
@media (max-width: 991px) { .stat-grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 480px)  { .stat-grid { grid-template-columns: 1fr; } }

.stat-card { background: #fff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px 18px; display: flex; align-items: center; gap: 14px; }
.stat-icon { width: 42px; height: 42px; border-radius: 11px; display: flex; align-items: center; justify-content: center; font-size: 17px; flex-shrink: 0; }
.stat-icon.green  { background: #f0fdf4; color: #16a34a; }
.stat-icon.red    { background: #fef2f2; color: #dc2626; }
.stat-icon.blue   { background: #eff6ff; color: #2563eb; }
.stat-icon.amber  { background: #fffbeb; color: #d97706; }
.stat-val  { font-size: 22px; font-weight: 700; color: #0f172a; line-height: 1; }
.stat-lbl  { font-size: 11.5px; color: #64748b; margin-top: 3px; }

/* ================================================================
   ACTION BUTTONS
================================================================ */
.btn-stockin  { background: #2563eb; color: #fff; border: none; border-radius: 8px; padding: 8px 16px; font-size: 12.5px; font-weight: 600; font-family: inherit; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; transition: background .12s; text-decoration: none; }
.btn-stockin:hover  { background: #1d4ed8; color: #fff; }
.btn-stockout { background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; border-radius: 8px; padding: 8px 16px; font-size: 12.5px; font-weight: 600; font-family: inherit; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; transition: background .12s; text-decoration: none; }
.btn-stockout:hover { background: #fee2e2; color: #dc2626; }
.btn-adjust   { background: #f8fafc; color: #374151; border: 1px solid #d1d5db; border-radius: 8px; padding: 8px 16px; font-size: 12.5px; font-weight: 600; font-family: inherit; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; transition: background .12s; text-decoration: none; }
.btn-adjust:hover   { background: #f1f5f9; color: #0f172a; }

/* ================================================================
   MAIN PANEL / TABLE
================================================================ */
.panel { background: #fff; border: 1px solid #e2e8f0; border-radius: 14px; overflow: hidden; }
.panel-header { padding: 16px 20px; border-bottom: 1px solid #f1f5f9; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 10px; }
.panel-title { font-size: 13.5px; font-weight: 700; color: #0f172a; display: flex; align-items: center; gap: 8px; }
.panel-title i { color: #2563eb; font-size: 15px; }
.panel-body-flush { overflow-x: auto; }

/* Table */
#txTable { width: 100% !important; border-collapse: collapse; font-size: 12.5px; }
#txTable thead th { background: #f8fafc; color: #475569; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .05em; padding: 10px 14px; border-bottom: 1px solid #e2e8f0; white-space: nowrap; }
#txTable tbody td { padding: 11px 14px; border-bottom: 1px solid #f8fafc; vertical-align: middle; color: #0f172a; }
#txTable tbody tr:last-child td { border-bottom: none; }
#txTable tbody tr:hover { background: #f8fafc; }

/* Product cell */
.prod-cell { display: flex; align-items: center; gap: 9px; }
.prod-thumb { width: 30px; height: 30px; border-radius: 8px; background: #eff6ff; display: flex; align-items: center; justify-content: center; font-size: 13px; color: #2563eb; flex-shrink: 0; }
.prod-name { font-size: 12.5px; font-weight: 600; color: #0f172a; }
.prod-sku  { font-family: 'Courier New', monospace; font-size: 10px; font-weight: 700; color: #2563eb; background: #eff6ff; padding: 1px 6px; border-radius: 4px; }

/* Transaction type badges */
.type-badge { font-size: 10.5px; font-weight: 700; padding: 3px 10px; border-radius: 20px; white-space: nowrap; }
.type-in     { background: #f0fdf4; color: #15803d; }
.type-out    { background: #fef2f2; color: #dc2626; }
.type-damage { background: #fff7ed; color: #c2410c; }
.type-return { background: #eff6ff; color: #1d4ed8; }
.type-adjust { background: #f8fafc; color: #475569; }

/* Quantity column - show + or - with colour */
.qty-cell { font-weight: 700; font-size: 13px; }
.qty-cell.up   { color: #16a34a; }
.qty-cell.down { color: #dc2626; }
.qty-cell.neutral { color: #64748b; }

/* Stock change pill (before -> after) */
.stock-change { display: flex; align-items: center; gap: 5px; font-size: 11.5px; }
.stock-before { color: #94a3b8; }
.stock-arrow  { color: #94a3b8; font-size: 10px; }
.stock-after  { font-weight: 700; color: #0f172a; }

/* User chip */
.user-chip { display: inline-flex; align-items: center; gap: 5px; font-size: 11.5px; color: #475569; }
.user-chip i { font-size: 11px; color: #94a3b8; }

/* Date */
.date-cell { font-size: 11.5px; color: #64748b; white-space: nowrap; }

/* Empty state */
.empty-state { text-align: center; padding: 60px 24px; }
.empty-icon  { font-size: 42px; color: #cbd5e1; margin-bottom: 14px; }
.empty-title { font-size: 15px; font-weight: 700; color: #475569; margin-bottom: 6px; }
.empty-sub   { font-size: 12.5px; color: #94a3b8; }

/* ================================================================
   LOW-STOCK PANEL (shown when action=lowstock)
================================================================ */
.lowstock-panel { background: #fff; border: 1px solid #e2e8f0; border-radius: 14px; overflow: hidden; margin-bottom: 22px; }
.lowstock-header { padding: 14px 20px; background: linear-gradient(135deg, #fff7ed, #fff); border-bottom: 1px solid #fed7aa; display: flex; align-items: center; gap: 10px; }
.lowstock-header i { color: #ea580c; font-size: 16px; }
.lowstock-header h3 { font-size: 14px; font-weight: 700; color: #0f172a; margin: 0; }

.ls-row { padding: 12px 20px; display: flex; align-items: center; gap: 12px; border-bottom: 1px solid #f8fafc; }
.ls-row:last-child { border-bottom: none; }
.ls-row:hover { background: #fffbeb; }
.ls-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.ls-dot.critical { background: #dc2626; }
.ls-dot.warning  { background: #f59e0b; }
.ls-info { flex: 1; }
.ls-name { font-size: 12.5px; font-weight: 600; color: #0f172a; }
.ls-meta { font-size: 11px; color: #94a3b8; margin-top: 1px; }
.ls-badge { font-size: 11px; font-weight: 700; padding: 3px 10px; border-radius: 20px; white-space: nowrap; flex-shrink: 0; }
.ls-badge.critical { background: #fef2f2; color: #dc2626; }
.ls-badge.warning  { background: #fffbeb; color: #b45309; }
.ls-action { font-size: 11.5px; color: #2563eb; text-decoration: none; font-weight: 600; flex-shrink: 0; }
.ls-action:hover { text-decoration: underline; }

/* ================================================================
   MODAL OVERLAY  (Stock In / Out / Adjust form)
================================================================ */
.modal-overlay {
    display: none;
    position: fixed; inset: 0; z-index: 1050;
    background: rgba(15, 23, 42, 0.55);
    backdrop-filter: blur(2px);
    align-items: center;
    justify-content: center;
    padding: 20px;
}
.modal-overlay.open { display: flex; }

.modal-box {
    background: #fff;
    border-radius: 16px;
    width: 100%;
    max-width: 520px;
    box-shadow: 0 20px 60px rgba(0,0,0,.15);
    overflow: hidden;
    animation: slideUp .2s ease;
}
@keyframes slideUp {
    from { opacity: 0; transform: translateY(16px); }
    to   { opacity: 1; transform: translateY(0); }
}

/* Modal header - colour changes by type */
.modal-header { padding: 18px 22px; display: flex; align-items: center; justify-content: space-between; }
.modal-header.type-STOCK_IN  { background: linear-gradient(135deg, #eff6ff, #fff); border-bottom: 1px solid #bfdbfe; }
.modal-header.type-STOCK_OUT { background: linear-gradient(135deg, #fef2f2, #fff); border-bottom: 1px solid #fecaca; }
.modal-header.type-DAMAGE    { background: linear-gradient(135deg, #fff7ed, #fff); border-bottom: 1px solid #fed7aa; }
.modal-header.type-ADJUSTMENT{ background: linear-gradient(135deg, #f8fafc, #fff); border-bottom: 1px solid #e2e8f0; }
.modal-header.type-RETURN    { background: linear-gradient(135deg, #eff6ff, #fff); border-bottom: 1px solid #bfdbfe; }

.modal-title-wrap { display: flex; align-items: center; gap: 10px; }
.modal-type-icon { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 16px; flex-shrink: 0; }
.icon-STOCK_IN   { background: #2563eb; color: #fff; }
.icon-STOCK_OUT  { background: #dc2626; color: #fff; }
.icon-DAMAGE     { background: #ea580c; color: #fff; }
.icon-ADJUSTMENT { background: #6b7280; color: #fff; }
.icon-RETURN     { background: #7c3aed; color: #fff; }

.modal-title { font-size: 15px; font-weight: 700; color: #0f172a; margin: 0 0 2px 0; }
.modal-subtitle { font-size: 11.5px; color: #64748b; }

.modal-close { background: none; border: none; font-size: 18px; color: #94a3b8; cursor: pointer; padding: 4px; line-height: 1; }
.modal-close:hover { color: #0f172a; }

/* Modal body */
.modal-body { padding: 22px; }

/* Current stock display inside modal */
.current-stock-box {
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 10px;
    padding: 12px 16px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 18px;
}
.current-stock-lbl  { font-size: 11.5px; color: #64748b; }
.current-stock-val  { font-size: 20px; font-weight: 700; color: #0f172a; }
.current-stock-unit { font-size: 11px; color: #94a3b8; }

/* Form fields inside modal */
.mfield { margin-bottom: 14px; }
.mlabel { display: block; font-size: 12px; font-weight: 600; color: #374151; margin-bottom: 5px; }
.mlabel .req { color: #dc2626; margin-left: 2px; }
.minput, .mselect, .mtextarea {
    width: 100%; border: 1px solid #d1d5db; border-radius: 8px;
    padding: 9px 12px; font-size: 12.5px; color: #0f172a;
    font-family: inherit; background: #fff; outline: none;
    transition: border-color .15s, box-shadow .15s;
    appearance: none; -webkit-appearance: none;
}
.minput:focus, .mselect:focus { border-color: #2563eb; box-shadow: 0 0 0 3px rgba(37,99,235,.12); }
.minput::placeholder { color: #94a3b8; }
.mselect { background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='2.5'%3E%3Cpath d='M6 9l6 6 6-6'/%3E%3C/svg%3E"); background-repeat: no-repeat; background-position: right 12px center; padding-right: 34px; cursor: pointer; }
.input-row { display: flex; gap: 10px; }
.input-row .mfield { flex: 1; }

/* Modal footer */
.modal-footer { padding: 14px 22px; background: #f8fafc; border-top: 1px solid #f1f5f9; display: flex; gap: 10px; justify-content: flex-end; }
.btn-confirm { background: #2563eb; color: #fff; border: none; border-radius: 8px; padding: 9px 22px; font-size: 13px; font-weight: 600; font-family: inherit; cursor: pointer; display: flex; align-items: center; gap: 7px; }
.btn-confirm:hover { background: #1d4ed8; }
.btn-confirm.danger { background: #dc2626; }
.btn-confirm.danger:hover { background: #b91c1c; }
.btn-confirm.amber  { background: #d97706; }
.btn-confirm.amber:hover  { background: #b45309; }
.btn-modal-cancel { background: #fff; color: #374151; border: 1px solid #d1d5db; border-radius: 8px; padding: 9px 18px; font-size: 13px; font-weight: 500; font-family: inherit; cursor: pointer; }
.btn-modal-cancel:hover { background: #f9fafb; }

/* ================================================================
   FOOTER
================================================================ */
.main-footer { background: #fff !important; border-top: 1px solid #e2e8f0 !important; padding: 12px 24px !important; font-size: 11.5px !important; color: #94a3b8 !important; text-align: center !important; }

/* DataTables overrides */
.dataTables_wrapper .dataTables_filter input { border: 1px solid #d1d5db; border-radius: 8px; padding: 6px 10px; font-size: 12px; outline: none; }
.dataTables_wrapper .dataTables_filter input:focus { border-color: #2563eb; box-shadow: 0 0 0 3px rgba(37,99,235,.10); }
.dataTables_wrapper .dataTables_length select { border: 1px solid #d1d5db; border-radius: 8px; padding: 4px 8px; font-size: 12px; }
.dataTables_wrapper .dataTables_info, .dataTables_wrapper .dataTables_paginate { font-size: 12px; padding: 10px 20px; }
.dataTables_wrapper .paginate_button { border-radius: 6px !important; padding: 4px 10px !important; font-size: 12px !important; }
.dataTables_wrapper .paginate_button.current { background: #2563eb !important; color: #fff !important; border-color: #2563eb !important; }
</style>
</head>

<body class="hold-transition sidebar-mini layout-fixed layout-navbar-fixed">
<div class="wrapper">

<!-- ================================================================
     NAVBAR
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
                <a href="${pageContext.request.contextPath}/dashboard" style="color:#2563eb;text-decoration:none;font-weight:500">Dashboard</a>
                <span style="color:#cbd5e1">/</span>
                <span class="crumb-active">Inventory</span>
            </div>
        </li>
    </ul>
    <ul class="navbar-nav ml-auto align-items-center">
        <li class="nav-item dropdown">
            <a href="#" class="nav-link p-0" data-toggle="dropdown">
                <div class="topbar-user-wrap">
                    <div class="topbar-avatar">${fn:toUpperCase(fn:substring(sessionScope.userFullName, 0, 2))}</div>
                    <div class="d-none d-sm-block">
                        <div class="topbar-user-name">${sessionScope.userFullName}</div>
                        <div class="topbar-user-role">${sessionScope.userRole}</div>
                    </div>
                </div>
            </a>
            <div class="dropdown-menu dropdown-menu-right" style="border:1px solid #e2e8f0;border-radius:10px;font-size:12.5px;min-width:160px;padding:6px;">
                <a class="dropdown-item" href="${pageContext.request.contextPath}/logout" style="border-radius:7px;padding:8px 12px;color:#dc2626;">
                    <i class="fas fa-sign-out-alt mr-2"></i> Sign Out
                </a>
            </div>
        </li>
    </ul>
</nav>

<!-- ================================================================
     SIDEBAR
================================================================ -->
<aside class="main-sidebar elevation-0">
    <a href="${pageContext.request.contextPath}/dashboard" class="brand-link">
        <div class="brand-logo-box"><i class="fas fa-cubes"></i></div>
        <div class="brand-text-wrap">
            <span class="brand-name">Jare Pharmacy</span>
            <span class="brand-sub">SME Inventory Hub</span>
        </div>
    </a>
    <div class="sidebar">
        <div class="user-panel mt-2 pb-2 mb-1 d-flex">
            <div class="sidebar-user-avatar">${fn:toUpperCase(fn:substring(sessionScope.userFullName, 0, 2))}</div>
            <div class="info">
                <a href="#">${sessionScope.userFullName}</a>
                <small>${sessionScope.userRole}</small>
            </div>
        </div>
        <nav class="mt-2 pb-3">
            <ul class="nav nav-pills nav-sidebar flex-column" data-widget="treeview" role="menu">
                <li class="nav-header">Main Menu</li>
                <li class="nav-item">
                    <a href="${pageContext.request.contextPath}/dashboard" class="nav-link">
                        <i class="nav-icon fas fa-tachometer-alt"></i><p>Dashboard</p>
                    </a>
                </li>
                <li class="nav-header">Inventory</li>
                <li class="nav-item">
                    <a href="${pageContext.request.contextPath}/products?action=list" class="nav-link">
                        <i class="nav-icon fas fa-box"></i><p>Products</p>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="${pageContext.request.contextPath}/categories?action=list" class="nav-link">
                        <i class="nav-icon fas fa-tags"></i><p>Categories</p>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="${pageContext.request.contextPath}/suppliers?action=list" class="nav-link">
                        <i class="nav-icon fas fa-truck"></i><p>Suppliers</p>
                    </a>
                </li>
                <li class="nav-item">
                    <%-- ACTIVE: Stock In / Out --%>
                    <a href="${pageContext.request.contextPath}/inventory?action=list" class="nav-link active">
                        <i class="nav-icon fas fa-exchange-alt"></i>
                        <p>Inventory
                            <c:if test="${lowStockCount > 0}">
                                <span class="nav-alert-badge">${lowStockCount}</span>
                            </c:if>
                        </p>
                    </a>
                </li>
                <li class="nav-header">Sales</li>
                <li class="nav-item">
                    <a href="#" class="nav-link"><i class="nav-icon fas fa-shopping-cart"></i><p>Point of Sale</p></a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link"><i class="nav-icon fas fa-receipt"></i><p>Sales History</p></a>
                </li>
                <li class="nav-header">Reports</li>
                <li class="nav-item">
                    <a href="#" class="nav-link"><i class="nav-icon fas fa-chart-bar"></i><p>Reports</p></a>
                </li>
                <li class="nav-header">Account</li>
                <li class="nav-item">
                    <a href="${pageContext.request.contextPath}/logout" class="nav-link" style="color:#ef4444 !important;">
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

    <%-- ── PAGE HEADING ──────────────────────────────────────── --%>
    <div class="page-heading">
        <div>
            <h2><i class="fas fa-exchange-alt" style="color:#2563eb;margin-right:8px;font-size:18px"></i>
                <c:choose>
                    <c:when test="${viewMode == 'lowstock'}">Low Stock Alert</c:when>
                    <c:otherwise>Inventory Transactions</c:otherwise>
                </c:choose>
            </h2>
            <div class="heading-breadcrumb">
                <a href="${pageContext.request.contextPath}/dashboard"><i class="fas fa-home"></i> Dashboard</a>
                <i class="fas fa-chevron-right" style="font-size:10px"></i>
                <span>Inventory</span>
            </div>
        </div>
        <%-- Quick-action buttons in the top right --%>
        <div class="heading-actions">
            <a href="${pageContext.request.contextPath}/inventory?action=stockin"
               class="btn-stockin">
                <i class="fas fa-arrow-down"></i> Stock In
            </a>
            <a href="${pageContext.request.contextPath}/inventory?action=stockout"
               class="btn-stockout">
                <i class="fas fa-arrow-up"></i> Stock Out
            </a>
            <a href="${pageContext.request.contextPath}/inventory?action=adjust"
               class="btn-adjust">
                <i class="fas fa-sliders-h"></i> Adjust
            </a>
        </div>
    </div>

    <%-- ── KPI STAT CARDS ────────────────────────────────────── --%>
    <div class="stat-grid">
        <div class="stat-card">
            <div class="stat-icon green"><i class="fas fa-arrow-down"></i></div>
            <div>
                <div class="stat-val">${totalIn}</div>
                <div class="stat-lbl">Total Units Received</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon red"><i class="fas fa-arrow-up"></i></div>
            <div>
                <div class="stat-val">${totalOut}</div>
                <div class="stat-lbl">Total Units Issued</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon blue"><i class="fas fa-calendar-day"></i></div>
            <div>
                <div class="stat-val">${todayCount}</div>
                <div class="stat-lbl">Movements Today</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon amber"><i class="fas fa-triangle-exclamation"></i></div>
            <div>
                <div class="stat-val">${lowStockCount}</div>
                <div class="stat-lbl">Low Stock Items</div>
            </div>
        </div>
    </div>

    <%-- ── LOW STOCK PANEL (only shown when action=lowstock) ─── --%>
    <c:if test="${viewMode == 'lowstock'}">
        <div class="lowstock-panel">
            <div class="lowstock-header">
                <i class="fas fa-triangle-exclamation"></i>
                <h3>Products Below Reorder Level</h3>
                <span style="margin-left:auto;font-size:11.5px;color:#64748b">
                    ${fn:length(lowStockProducts)} products need restocking
                </span>
            </div>
            <c:choose>
                <c:when test="${empty lowStockProducts}">
                    <div class="empty-state">
                        <div class="empty-icon"><i class="fas fa-check-circle" style="color:#22c55e"></i></div>
                        <div class="empty-title">All stock levels are healthy!</div>
                        <div class="empty-sub">No products are below their reorder level.</div>
                    </div>
                </c:when>
                <c:otherwise>
                    <c:forEach var="p" items="${lowStockProducts}">
                        <c:set var="isCritical" value="${p.currentStock == 0 || p.currentStock <= (p.reorderLevel * 0.5)}" />
                        <div class="ls-row">
                            <div class="ls-dot ${isCritical ? 'critical' : 'warning'}"></div>
                            <div class="ls-info">
                                <div class="ls-name">${p.name}</div>
                                <div class="ls-meta">SKU: ${p.sku} &bull; Reorder at: ${p.reorderLevel} ${p.unit}</div>
                            </div>
                            <span class="ls-badge ${isCritical ? 'critical' : 'warning'}">
                                ${p.currentStock} ${p.unit} left
                            </span>
                            <a href="${pageContext.request.contextPath}/inventory?action=stockin&productId=${p.id}"
                               class="ls-action">
                                <i class="fas fa-plus"></i> Stock In
                            </a>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </div>
    </c:if>

    <%-- ── TRANSACTION HISTORY TABLE ─────────────────────────── --%>
    <div class="panel">
        <div class="panel-header">
            <div class="panel-title">
                <i class="fas fa-scroll"></i>
                Transaction History
            </div>
            <div style="display:flex;gap:8px;align-items:center">
                <%-- Filter buttons --%>
                <a href="${pageContext.request.contextPath}/inventory?action=list"
                   class="btn-adjust" style="font-size:11px;padding:5px 12px;text-decoration:none">
                    <i class="fas fa-list"></i> All
                </a>
                <a href="${pageContext.request.contextPath}/inventory?action=lowstock"
                   class="btn-stockout" style="font-size:11px;padding:5px 12px;text-decoration:none">
                    <i class="fas fa-triangle-exclamation"></i> Low Stock
                </a>
            </div>
        </div>

        <div class="panel-body-flush">
            <c:choose>
                <c:when test="${empty transactions}">
                    <div class="empty-state">
                        <div class="empty-icon"><i class="fas fa-box-open"></i></div>
                        <div class="empty-title">No transactions yet</div>
                        <div class="empty-sub">
                            Use the Stock In or Stock Out buttons above to record your first movement.
                        </div>
                    </div>
                </c:when>
                <c:otherwise>
                    <table id="txTable" class="table w-100">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Product</th>
                                <th>Type</th>
                                <th class="text-center">Qty</th>
                                <th>Stock Change</th>
                                <th>Reference</th>
                                <th>Performed By</th>
                                <th>Date &amp; Time</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="tx" items="${transactions}" varStatus="loop">
                            <tr>
                                <%-- Row number --%>
                                <td style="color:#94a3b8;font-size:11.5px">${loop.count}</td>

                                <%-- Product cell --%>
                                <td>
                                    <div class="prod-cell">
                                        <div class="prod-thumb"><i class="fas fa-box"></i></div>
                                        <div>
                                            <div class="prod-name">${tx.productName}</div>
                                            <div class="prod-sku">${tx.productSku}</div>
                                        </div>
                                    </div>
                                </td>

                                <%-- Transaction type badge --%>
                                <td>
                                    <span class="type-badge ${tx.typeCssClass}">
                                        ${tx.typeLabel}
                                    </span>
                                </td>

                                <%-- Quantity with sign and colour --%>
                                <td class="text-center">
                                    <span class="qty-cell ${tx.stockIncreasing ? 'up' : tx.stockDecreasing ? 'down' : 'neutral'}">
                                        ${tx.signedQuantity} ${tx.productUnit}
                                    </span>
                                </td>

                                <%--
                                    Stock before -> after.
                                    NOTE: stockBefore and stockAfter are NOT stored in
                                    the DB - they are computed from the product's current
                                    stock and this transaction in a future enhancement.
                                    For now we show the quantity direction only.
                                    Uncomment below when you implement snapshot storage.

                                    <div class="stock-change">
                                        <span class="stock-before">${tx.stockBefore}</span>
                                        <i class="fas fa-arrow-right stock-arrow"></i>
                                        <span class="stock-after">${tx.stockAfter}</span>
                                    </div>
                                --%>
                                <td>
                                    <span style="font-size:11.5px;color:#64748b">
                                        <c:choose>
                                            <c:when test="${tx.unitCost != null}">
                                                ₦<fmt:formatNumber value="${tx.unitCost}" pattern="#,##0.00"/> /unit
                                            </c:when>
                                            <c:otherwise>-</c:otherwise>
                                        </c:choose>
                                    </span>
                                </td>

                                <%-- Reference note --%>
                                <td style="font-size:11.5px;color:#475569">
                                    <c:choose>
                                        <c:when test="${not empty tx.referenceNote}">${tx.referenceNote}</c:when>
                                        <c:otherwise><span style="color:#cbd5e1">-</span></c:otherwise>
                                    </c:choose>
                                </td>

                                <%-- Who performed it --%>
                                <td>
                                    <div class="user-chip">
                                        <i class="fas fa-user-circle"></i>
                                        ${tx.performedByName}
                                    </div>
                                </td>

                                <%-- Date and time --%>
                                <td class="date-cell">${tx.formattedDate}</td>
                            </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </c:otherwise>
            </c:choose>
        </div>
    </div>

</div><%-- /page-content --%>
</div><%-- /content-wrapper --%>

<!-- ================================================================
     FOOTER
================================================================ -->
<footer class="main-footer">
    <strong>Jare Pharmacy</strong> - Inventory Management System
</footer>

</div><%-- /wrapper --%>

<!-- ================================================================
     STOCK IN / OUT / ADJUST MODAL
     This single modal handles ALL transaction types.
     The servlet tells us which type via ${formMode}.
     JavaScript reads formMode to set the modal header colour and title.
================================================================ -->
<div class="modal-overlay" id="txModal">
    <div class="modal-box">

        <%-- Modal header - colour set by JS based on formMode --%>
        <div class="modal-header" id="modalHeader">
            <div class="modal-title-wrap">
                <div class="modal-type-icon" id="modalIcon">
                    <i class="fas fa-arrow-down" id="modalIconI"></i>
                </div>
                <div>
                    <h3 class="modal-title" id="modalTitle">Stock In</h3>
                    <p class="modal-subtitle" id="modalSubtitle">Record goods received from supplier</p>
                </div>
            </div>
            <button class="modal-close" onclick="closeModal()">&times;</button>
        </div>

        <%-- Modal body with form --%>
        <div class="modal-body">

            <%-- Error alert inside modal --%>
            <div id="modalError" style="display:none;background:#fef2f2;border:1px solid #fecaca;border-radius:8px;padding:10px 14px;font-size:12.5px;color:#b91c1c;margin-bottom:14px;display:none">
                <i class="fas fa-circle-exclamation mr-1"></i>
                <span id="modalErrorText"></span>
            </div>

            <%-- The actual form - POSTs to /inventory --%>
            <form id="txForm"
                  action="${pageContext.request.contextPath}/inventory"
                  method="POST">

                <%-- Hidden fields: the servlet reads these --%>
                <input type="hidden" name="action"          value="record">
                <input type="hidden" name="transactionType" id="txTypeInput" value="STOCK_IN">

                <%-- Product dropdown --%>
                <div class="mfield">
                    <label class="mlabel" for="productId">
                        Product <span class="req">*</span>
                    </label>
                    <select id="productId" name="productId"
                            class="mselect" required
                            onchange="updateCurrentStock(this.value)">
                        <option value="">- Select product -</option>
                        <c:forEach var="p" items="${products}">
                            <option value="${p.id}"
                                data-stock="${p.currentStock}"
                                data-unit="${p.unit}"
                                data-reorder="${p.reorderLevel}"
                                <c:if test="${p.id == preSelectedProductId}">selected</c:if>
                            >${p.name} (${p.sku})</option>
                        </c:forEach>
                    </select>
                </div>

                <%-- Current stock display - updates when product is selected --%>
                <div class="current-stock-box" id="stockBox" style="display:none">
                    <div>
                        <div class="current-stock-lbl">Current Stock</div>
                        <div>
                            <span class="current-stock-val" id="currentStockVal">0</span>
                            <span class="current-stock-unit" id="currentStockUnit"></span>
                        </div>
                    </div>
                    <div style="text-align:right">
                        <div class="current-stock-lbl">Reorder Level</div>
                        <div style="font-size:14px;font-weight:600;color:#f59e0b" id="reorderVal">-</div>
                    </div>
                </div>

                <%-- Quantity row - for adjustments, also show +/- selector --%>
                <div class="input-row">
                    <div class="mfield" id="adjustDirectionField" style="display:none;max-width:130px">
                        <label class="mlabel">Direction</label>
                        <select name="adjustDirection" id="adjustDirection" class="mselect">
                            <option value="plus">+ Add</option>
                            <option value="minus">− Remove</option>
                        </select>
                    </div>
                    <div class="mfield">
                        <label class="mlabel" for="quantity">
                            Quantity <span class="req">*</span>
                        </label>
                        <input type="number" id="quantity" name="quantity"
                               class="minput" placeholder="0"
                               min="1" step="1" required>
                    </div>
                </div>

                <%-- Unit cost (shown only for Stock In) --%>
                <div class="mfield" id="unitCostField">
                    <label class="mlabel" for="unitCost">
                        Unit Cost ₦ <span style="font-weight:400;color:#94a3b8">(optional)</span>
                    </label>
                    <input type="number" id="unitCost" name="unitCost"
                           class="minput" placeholder="0.00"
                           min="0" step="0.01">
                </div>

                <%-- Reference note --%>
                <div class="mfield">
                    <label class="mlabel" for="referenceNote">
                        Reference / Note <span style="font-weight:400;color:#94a3b8">(optional)</span>
                    </label>
                    <input type="text" id="referenceNote" name="referenceNote"
                           class="minput"
                           placeholder="e.g. Invoice #INV-2025-001, Returned by customer"
                           maxlength="255">
                </div>
            </form>
        </div>

        <%-- Modal footer with action buttons --%>
        <div class="modal-footer">
            <button type="button" class="btn-modal-cancel" onclick="closeModal()">
                <i class="fas fa-xmark"></i> Cancel
            </button>
            <button type="submit" form="txForm" id="modalSubmitBtn" class="btn-confirm">
                <i class="fas fa-check" id="submitIcon"></i>
                <span id="submitBtnText">Confirm Stock In</span>
            </button>
        </div>
    </div>
</div>

<!-- ================================================================
     SCRIPTS
================================================================ -->
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>
<script src="https://cdn.datatables.net/1.13.4/js/jquery.dataTables.min.js"></script>
<script src="https://cdn.datatables.net/1.13.4/js/dataTables.bootstrap4.min.js"></script>
<script src="https://cdn.datatables.net/responsive/2.4.1/js/dataTables.responsive.min.js"></script>
<script src="https://cdn.datatables.net/responsive/2.4.1/js/responsive.bootstrap4.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<script>
/*
 * ================================================================
 *  JAVASCRIPT - inventory.jsp
 * ================================================================
 *  1. DataTable init
 *  2. Modal open/close with type configuration
 *  3. Product change -> update current stock display
 *  4. Form validation
 *  5. Auto-open modal if servlet forwarded with formMode set
 *  6. SweetAlert2 toast for success / error flash messages
 * ================================================================
 */

// ── 1. DataTable ─────────────────────────────────────────────────
$(document).ready(function () {
    if ($('#txTable').length) {
        $('#txTable').DataTable({
            responsive:  true,
            pageLength:  25,
            order:       [[7, 'desc']], // sort by date column DESC by default
            lengthMenu:  [[10, 25, 50, 100, -1], [10, 25, 50, 100, 'All']],
            language: {
                search:           '',
                searchPlaceholder:'Search transactions...',
                lengthMenu:       'Show _MENU_',
                info:             '_START_–_END_ of _TOTAL_ transactions',
                paginate:         { previous: '‹', next: '›' }
            },
            columnDefs: [
                { orderable: false, targets: [0] } // row number column not sortable
            ]
        });
    }
});

// ── 2. MODAL CONFIGURATION MAP ───────────────────────────────────
/*
 * Each transaction type has its own:
 *   title       - shown in the modal header
 *   subtitle    - shown under the title
 *   icon        - Font Awesome icon class
 *   iconClass   - CSS class for icon box background colour
 *   headerClass - CSS class for modal header gradient
 *   btnClass    - CSS class for the Confirm button
 *   btnText     - text on the Confirm button
 *   showCost    - whether to show the Unit Cost field
 *   showAdjDir  - whether to show the +/- direction dropdown
 */
var typeConfig = {
    'STOCK_IN': {
        title:      'Stock In',
        subtitle:   'Record goods received from supplier or warehouse',
        icon:       'fa-arrow-down',
        iconClass:  'icon-STOCK_IN',
        headerClass:'type-STOCK_IN',
        btnClass:   '',
        btnText:    'Confirm Stock In',
        showCost:   true,
        showAdjDir: false
    },
    'STOCK_OUT': {
        title:      'Stock Out',
        subtitle:   'Record goods leaving inventory (non-sale)',
        icon:       'fa-arrow-up',
        iconClass:  'icon-STOCK_OUT',
        headerClass:'type-STOCK_OUT',
        btnClass:   'danger',
        btnText:    'Confirm Stock Out',
        showCost:   false,
        showAdjDir: false
    },
    'DAMAGE': {
        title:      'Damage / Write-off',
        subtitle:   'Record damaged, expired, or lost goods',
        icon:       'fa-triangle-exclamation',
        iconClass:  'icon-DAMAGE',
        headerClass:'type-DAMAGE',
        btnClass:   'danger',
        btnText:    'Write Off Stock',
        showCost:   false,
        showAdjDir: false
    },
    'ADJUSTMENT': {
        title:      'Stock Adjustment',
        subtitle:   'Manually correct the stock level after a count',
        icon:       'fa-sliders-h',
        iconClass:  'icon-ADJUSTMENT',
        headerClass:'type-ADJUSTMENT',
        btnClass:   'amber',
        btnText:    'Apply Adjustment',
        showCost:   false,
        showAdjDir: true
    },
    'RETURN': {
        title:      'Customer Return',
        subtitle:   'Record goods returned by a customer',
        icon:       'fa-undo',
        iconClass:  'icon-RETURN',
        headerClass:'type-RETURN',
        btnClass:   '',
        btnText:    'Confirm Return',
        showCost:   false,
        showAdjDir: false
    }
};

// ── 3. Open modal with specific type ─────────────────────────────
function openModal(type) {
    var cfg = typeConfig[type] || typeConfig['STOCK_IN'];

    // Set the hidden transaction type input
    document.getElementById('txTypeInput').value = type;

    // Update header
    document.getElementById('modalHeader').className = 'modal-header ' + cfg.headerClass;
    document.getElementById('modalIcon').className   = 'modal-type-icon ' + cfg.iconClass;
    document.getElementById('modalIconI').className  = 'fas ' + cfg.icon;
    document.getElementById('modalTitle').textContent    = cfg.title;
    document.getElementById('modalSubtitle').textContent = cfg.subtitle;

    // Update submit button
    var btn = document.getElementById('modalSubmitBtn');
    btn.className = 'btn-confirm ' + cfg.btnClass;
    document.getElementById('submitIcon').className = 'fas fa-check';
    document.getElementById('submitBtnText').textContent = cfg.btnText;

    // Show/hide optional fields
    document.getElementById('unitCostField').style.display      = cfg.showCost   ? 'block' : 'none';
    document.getElementById('adjustDirectionField').style.display = cfg.showAdjDir ? 'block' : 'none';

    // Reset quantity field
    document.getElementById('quantity').value = '';

    // Open the modal
    document.getElementById('txModal').classList.add('open');

    // Focus the product dropdown after the animation
    setTimeout(function () {
        document.getElementById('productId').focus();
    }, 220);
}

// Close modal
function closeModal() {
    document.getElementById('txModal').classList.remove('open');
    document.getElementById('modalError').style.display = 'none';
}

// Close modal on overlay click (clicking outside the white box)
document.getElementById('txModal').addEventListener('click', function (e) {
    if (e.target === this) closeModal();
});

// ── 4. Update current stock display when product changes ─────────
function updateCurrentStock(productId) {
    var select = document.getElementById('productId');
    var option = select.options[select.selectedIndex];

    if (!productId || productId === '') {
        document.getElementById('stockBox').style.display = 'none';
        return;
    }

    var stock   = option.getAttribute('data-stock')   || '0';
    var unit    = option.getAttribute('data-unit')     || '';
    var reorder = option.getAttribute('data-reorder')  || '-';

    document.getElementById('currentStockVal').textContent  = parseInt(stock).toLocaleString();
    document.getElementById('currentStockUnit').textContent = unit;
    document.getElementById('reorderVal').textContent       = reorder + ' ' + unit;
    document.getElementById('stockBox').style.display       = 'flex';

    // Colour the current stock value based on health
    var valEl = document.getElementById('currentStockVal');
    var s = parseInt(stock);
    var r = parseInt(reorder);
    if (s === 0)       valEl.style.color = '#dc2626';
    else if (s <= r)   valEl.style.color = '#d97706';
    else               valEl.style.color = '#16a34a';
}

// ── 5. Form validation before submit ─────────────────────────────
document.getElementById('txForm').addEventListener('submit', function (e) {
    var productId = document.getElementById('productId').value;
    var quantity  = parseInt(document.getElementById('quantity').value);

    if (!productId) {
        e.preventDefault();
        showModalError('Please select a product.');
        return;
    }
    if (!quantity || quantity <= 0) {
        e.preventDefault();
        showModalError('Please enter a valid quantity (must be greater than 0).');
        return;
    }

    // Disable button to prevent double-submit
    var btn = document.getElementById('modalSubmitBtn');
    btn.disabled  = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processing…';
});

function showModalError(msg) {
    var errBox = document.getElementById('modalError');
    document.getElementById('modalErrorText').textContent = msg;
    errBox.style.display = 'flex';
}

// ── 6. Auto-open modal if servlet forwarded with formMode set ────
// The servlet calls showTransactionForm() which forwards to this JSP
// with ${formMode} set. We check for it and open the modal automatically.
(function () {
    var formMode = '${formMode}';
    if (formMode && formMode !== '') {
        openModal(formMode);

        // Pre-select the product if the URL had ?productId=
        var preId = '${preSelectedProductId}';
        if (preId && preId !== '0' && preId !== '') {
            var select = document.getElementById('productId');
            if (select) {
                select.value = preId;
                updateCurrentStock(preId);
            }
        }
    }
})();

// ── 7. SweetAlert2 flash messages ────────────────────────────────
// After a redirect from InventoryServlet, the URL contains
// ?success=... or ?error=... which the servlet puts in request attrs.
// We read them here and show a toast notification.

(function () {
    var successMsg = decodeURIComponent('${successMessage}');
    var errorMsg   = decodeURIComponent('${errorMessage}');

    if (successMsg && successMsg !== '' && successMsg !== 'null') {
        Swal.fire({
            toast:             true,
            position:          'top-end',
            icon:              'success',
            title:             successMsg,
            showConfirmButton: false,
            timer:             4000,
            timerProgressBar:  true,
            customClass: { popup: 'swal-toast' }
        });
    }

    if (errorMsg && errorMsg !== '' && errorMsg !== 'null') {
        Swal.fire({
            icon:              'error',
            title:             'Transaction Failed',
            text:              errorMsg,
            confirmButtonText: 'OK',
            confirmButtonColor:'#2563eb'
        });
    }
})();
</script>

</body>
</html>
