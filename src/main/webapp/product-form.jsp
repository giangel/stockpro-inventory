<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core"      prefix="c"  %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
==========================================================================
  product-form.jsp  -  Jare Pharmacy Inventory System
==========================================================================

  PURPOSE:
    This single JSP handles BOTH adding a new product AND editing an
    existing one. The servlet decides which mode we are in by setting
    the "formMode" attribute to either "add" or "edit".

  WHAT THE SERVLET SENDS TO THIS PAGE (request attributes):
    • formMode   (String)        - "add"  or  "edit"
    • product    (Product)       - empty Product for add,
                                   populated Product for edit
    • categories (List<Category>)- for the category <select> dropdown
    • suppliers  (List<Supplier>)- for the supplier <select> dropdown
    • errorMessage (String)      - set only when server-side validation
                                   fails; null otherwise

  FORM SUBMISSION:
    • Add  mode -> POST  /products?action=create
    • Edit mode -> POST  /products?action=update  (+ hidden id field)

  DEPENDENCIES (all loaded from CDN - no local files needed):
    • AdminLTE 3.2   - sidebar / navbar shell
    • Bootstrap 4    - grid, utilities
    • Font Awesome 6 - icons
    • SweetAlert2    - delete-confirm dialog
    • Google Fonts   - Inter typeface

  HOW TO USE:
    1. Drop this file into your WebContent/ (project root) folder.
    2. Make sure your ProductServlet is mapped to /products in web.xml
       (or via @WebServlet annotation - you already have this).
    3. Confirm the JSTL JAR is in WEB-INF/lib/
       (jstl-1.2.jar  or  jakarta.servlet.jsp.jstl-2.x.jar).
    4. Run the project on Tomcat - navigate to:
         /products?action=new         -> Add Product form
         /products?action=edit&id=1   -> Edit Product #1

  COMMON MISTAKES TO AVOID:
    ✗ Don't link to dashboard.jsp directly - always go through the
      servlet (/products?action=list) so data is loaded from the DB.
    ✗ Don't forget the hidden "id" input - without it the UPDATE
      servlet method won't know which row to update.
    ✗ Don't remove the JSTL taglib declarations at the top -
      without them ${expressions} won't work.
    ✗ The form action attribute MUST include the context path so the
      URL is correct regardless of where Tomcat deploys the app.
==========================================================================
--%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <%-- Dynamic page title changes based on add vs edit mode --%>
    <title>Jare Pharmacy |
        <c:choose>
            <c:when test="${formMode == 'edit'}">Edit Product</c:when>
            <c:otherwise>Add New Product</c:otherwise>
        </c:choose>
    </title>

    <%-- ── Google Font: Inter (same as dashboard) ─────────────────── --%>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap"
          rel="stylesheet">

    <%-- ── Font Awesome 6 ─────────────────────────────────────────── --%>
    <link rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

    <%-- ── AdminLTE 3.2 ─────────────────────────────────────────────
         IMPORTANT: AdminLTE must load BEFORE your custom styles below
    --%>
    <link rel="stylesheet"
          href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">

    <%-- ── SweetAlert2 ────────────────────────────────────────────── --%>
    <link rel="stylesheet"
          href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css">

    <style>
    /* ==============================================================
       GLOBAL  -  mirrors dashboard.jsp exactly
    ============================================================== */
    *, *::before, *::after { box-sizing: border-box; }

    body,
    .content-wrapper,
    .main-sidebar,
    .main-header,
    .main-footer {
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif !important;
    }

    body {
        background-color: #f1f5f9 !important;
        color: #0f172a !important;
        font-size: 13px !important;
    }

    /* ==============================================================
       SIDEBAR  (identical to dashboard.jsp)
    ============================================================== */
    .main-sidebar {
        background-color: #0f172a !important;
        box-shadow: none !important;
        border-right: none !important;
        width: 230px !important;
    }

    .brand-link {
        background-color: #0f172a !important;
        border-bottom: 1px solid rgba(255,255,255,.06) !important;
        padding: 16px !important;
        display: flex !important;
        align-items: center !important;
        gap: 10px !important;
        text-decoration: none !important;
    }

    .brand-logo-box {
        width: 32px; height: 32px;
        background: #2563eb;
        border-radius: 9px;
        display: flex; align-items: center; justify-content: center;
        flex-shrink: 0;
    }
    .brand-logo-box i { color: #fff; font-size: 15px; }

    .brand-text-wrap .brand-name {
        font-size: 15px; font-weight: 700; color: #fff;
        letter-spacing: -0.01em; display: block;
    }
    .brand-text-wrap .brand-sub {
        font-size: 10px; color: #475569;
        font-weight: 400; display: block; margin-top: 1px;
    }

    .user-panel {
        background: transparent !important;
        border-bottom: 1px solid rgba(255,255,255,.06) !important;
        padding: 12px 16px !important;
        display: flex; align-items: center; gap: 10px;
    }

    .sidebar-user-avatar {
        width: 32px; height: 32px; border-radius: 50%;
        background: #1e3a8a;
        display: flex; align-items: center; justify-content: center;
        font-size: 12px; font-weight: 700; color: #bfdbfe; flex-shrink: 0;
    }
    .user-panel .info a {
        color: #cbd5e1 !important; font-size: 12.5px !important;
        font-weight: 600 !important; text-decoration: none !important; display: block;
    }
    .user-panel .info small { color: #475569; font-size: 10.5px; }

    .nav-sidebar .nav-header {
        font-size: 9.5px !important; font-weight: 700 !important;
        letter-spacing: .08em !important; color: #334155 !important;
        text-transform: uppercase !important; padding: 14px 16px 4px !important;
    }

    .nav-sidebar .nav-item .nav-link {
        color: #94a3b8 !important; border-radius: 8px !important;
        margin: 1px 8px !important; padding: 9px 12px !important;
        font-size: 12.5px !important; font-weight: 400 !important;
        border-left: 2px solid transparent !important;
        display: flex !important; align-items: center !important;
        gap: 9px !important; transition: all .12s ease !important;
    }
    .nav-sidebar .nav-item .nav-link:hover {
        background: rgba(255,255,255,.05) !important; color: #e2e8f0 !important;
    }
    .nav-sidebar .nav-item .nav-link.active {
        background: rgba(37,99,235,.18) !important;
        color: #60a5fa !important;
        border-left-color: #2563eb !important;
    }
    .nav-sidebar .nav-link .nav-icon {
        font-size: 14px !important; width: 16px !important;
        text-align: center; flex-shrink: 0;
    }
    .nav-sidebar .nav-link p { margin: 0 !important; font-size: 12.5px !important; line-height: 1 !important; }

    /* ==============================================================
       TOP NAV BAR
    ============================================================== */
    .main-header.navbar {
        background: #ffffff !important;
        border-bottom: 1px solid #e2e8f0 !important;
        box-shadow: none !important;
        min-height: 54px !important;
        padding: 0 20px !important;
    }

    .topbar-breadcrumb {
        font-size: 12px; color: #64748b;
        display: flex; align-items: center; gap: 5px; margin-left: 8px;
    }
    .topbar-breadcrumb .crumb-active { color: #0f172a; font-weight: 600; }

    .topbar-user-wrap {
        display: flex; align-items: center; gap: 8px;
        cursor: pointer; padding: 4px 8px;
        border-radius: 9px; transition: background .12s;
    }
    .topbar-user-wrap:hover { background: #f1f5f9; }
    .topbar-avatar {
        width: 32px; height: 32px; border-radius: 50%;
        background: #dbeafe;
        display: flex; align-items: center; justify-content: center;
        font-size: 12px; font-weight: 700; color: #1d4ed8; flex-shrink: 0;
    }
    .topbar-user-name { font-size: 12.5px; font-weight: 600; color: #0f172a; line-height: 1.2; }
    .topbar-user-role { font-size: 10.5px; color: #94a3b8; }

    /* ==============================================================
       CONTENT WRAPPER
    ============================================================== */
    .content-wrapper {
        background: #f1f5f9 !important;
        padding: 0 !important;
    }
    .page-content { padding: 22px 24px; }

    /* ==============================================================
       PAGE HEADING
    ============================================================== */
    .page-heading {
        display: flex; align-items: flex-start;
        justify-content: space-between;
        margin-bottom: 20px; flex-wrap: wrap; gap: 12px;
    }
    .page-heading h2 {
        font-size: 20px; font-weight: 700; color: #0f172a;
        margin: 0 0 3px 0; letter-spacing: -0.01em;
    }
    .page-heading p { font-size: 12px; color: #64748b; margin: 0; }

    /* Breadcrumb trail under heading */
    .heading-breadcrumb {
        display: flex; align-items: center; gap: 6px;
        font-size: 11.5px; color: #94a3b8; margin-top: 4px;
    }
    .heading-breadcrumb a {
        color: #2563eb; text-decoration: none; font-weight: 500;
    }
    .heading-breadcrumb a:hover { text-decoration: underline; }
    .heading-breadcrumb i { font-size: 10px; }

    /* ==============================================================
       FORM CARD
    ============================================================== */
    .form-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        overflow: hidden;
        box-shadow: 0 1px 3px rgba(0,0,0,.04);
    }

    /* Coloured top accent strip */
    .form-card-header {
        padding: 18px 24px;
        border-bottom: 1px solid #f1f5f9;
        display: flex; align-items: center; justify-content: space-between;
        position: relative;
        overflow: hidden;
    }
    /* Subtle blue gradient wash behind header */
    .form-card-header::before {
        content: '';
        position: absolute; inset: 0;
        background: linear-gradient(135deg, #eff6ff 0%, #ffffff 60%);
        z-index: 0;
    }
    .form-card-header > * { position: relative; z-index: 1; }

    .form-card-title {
        display: flex; align-items: center; gap: 10px;
    }
    .form-card-icon {
        width: 38px; height: 38px; border-radius: 10px;
        background: #2563eb;
        display: flex; align-items: center; justify-content: center;
        color: #fff; font-size: 16px; flex-shrink: 0;
    }
    .form-card-title h3 {
        font-size: 15px; font-weight: 700; color: #0f172a;
        margin: 0 0 2px 0; letter-spacing: -0.01em;
    }
    .form-card-title p { font-size: 11.5px; color: #64748b; margin: 0; }

    /* Mode badge (ADD / EDIT pill) */
    .mode-badge {
        font-size: 11px; font-weight: 700;
        padding: 4px 12px; border-radius: 20px;
        letter-spacing: .04em; text-transform: uppercase;
    }
    .mode-badge.add  { background: #f0fdf4; color: #15803d; border: 1px solid #bbf7d0; }
    .mode-badge.edit { background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; }

    /* Body */
    .form-card-body { padding: 28px 24px; }

    /* ==============================================================
       SECTION DIVIDERS  (groups related fields visually)
    ============================================================== */
    .form-section {
        margin-bottom: 28px;
    }
    .form-section-title {
        font-size: 11px; font-weight: 700; text-transform: uppercase;
        letter-spacing: .08em; color: #94a3b8;
        display: flex; align-items: center; gap: 8px;
        margin-bottom: 16px;
        padding-bottom: 10px;
        border-bottom: 1px solid #f1f5f9;
    }
    .form-section-title i { font-size: 13px; color: #cbd5e1; }

    /* ==============================================================
       FORM FIELDS
    ============================================================== */
    .field-group { margin-bottom: 16px; }

    .field-label {
        display: block;
        font-size: 12px; font-weight: 600; color: #374151;
        margin-bottom: 6px;
    }
    /* Red asterisk for required fields */
    .field-label .req { color: #dc2626; margin-left: 2px; }

    /* Helper text below a label */
    .field-hint {
        font-size: 10.5px; color: #94a3b8; font-weight: 400; margin-left: 4px;
    }

    /* Base input / select / textarea styling */
    .field-input,
    .field-select,
    .field-textarea {
        width: 100%;
        border: 1px solid #d1d5db;
        border-radius: 8px;
        padding: 9px 12px;
        font-size: 12.5px;
        color: #0f172a;
        font-family: inherit;
        background: #ffffff;
        transition: border-color .15s, box-shadow .15s;
        outline: none;
        appearance: none;
        -webkit-appearance: none;
    }
    .field-input:focus,
    .field-select:focus,
    .field-textarea:focus {
        border-color: #2563eb;
        box-shadow: 0 0 0 3px rgba(37,99,235,.12);
    }
    .field-input::placeholder,
    .field-textarea::placeholder { color: #94a3b8; }

    /* Input with a left icon */
    .input-wrap {
        position: relative;
    }
    .input-wrap .input-icon {
        position: absolute; left: 11px; top: 50%; transform: translateY(-50%);
        color: #94a3b8; font-size: 13px; pointer-events: none;
    }
    .input-wrap .field-input { padding-left: 34px; }

    /* Prefix label (₦ symbol for prices) */
    .input-prefix-wrap {
        display: flex;
    }
    .input-prefix {
        background: #f8fafc; border: 1px solid #d1d5db;
        border-right: none; border-radius: 8px 0 0 8px;
        padding: 9px 12px; font-size: 12.5px; font-weight: 600;
        color: #64748b; white-space: nowrap; flex-shrink: 0;
    }
    .input-prefix-wrap .field-input {
        border-radius: 0 8px 8px 0;
    }

    /* Select arrow */
    .field-select {
        background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='2.5'%3E%3Cpath d='M6 9l6 6 6-6'/%3E%3C/svg%3E");
        background-repeat: no-repeat;
        background-position: right 12px center;
        padding-right: 34px;
        cursor: pointer;
    }

    /* Textarea */
    .field-textarea { resize: vertical; min-height: 80px; }

    /* Validation error state */
    .field-input.is-error,
    .field-select.is-error,
    .field-textarea.is-error {
        border-color: #dc2626 !important;
        box-shadow: 0 0 0 3px rgba(220,38,38,.10) !important;
    }
    .field-error-msg {
        font-size: 11px; color: #dc2626; margin-top: 5px;
        display: flex; align-items: center; gap: 4px;
    }

    /* Character counter (for description field) */
    .char-counter {
        font-size: 10.5px; color: #94a3b8; text-align: right; margin-top: 4px;
    }

    /* ==============================================================
       STOCK LEVEL VISUAL  (colour bar below the stock qty input)
    ============================================================== */
    .stock-indicator {
        margin-top: 8px;
        display: flex; align-items: center; gap: 8px;
    }
    .stock-bar-track {
        flex: 1; height: 4px; background: #f1f5f9;
        border-radius: 99px; overflow: hidden;
    }
    .stock-bar-fill {
        height: 100%; border-radius: 99px;
        background: #22c55e;
        transition: width .3s ease, background .3s ease;
    }
    .stock-level-label {
        font-size: 10.5px; font-weight: 600; color: #64748b; white-space: nowrap;
    }

    /* ==============================================================
       ALERT BOX  (server-side error message banner)
    ============================================================== */
    .alert-error {
        background: #fef2f2; border: 1px solid #fecaca;
        border-radius: 10px; padding: 12px 16px;
        display: flex; align-items: center; gap: 10px;
        font-size: 12.5px; color: #b91c1c;
        margin-bottom: 24px;
    }
    .alert-error i { font-size: 15px; flex-shrink: 0; }

    /* Success banner (shown after redirect via ?success= param) */
    .alert-success {
        background: #f0fdf4; border: 1px solid #bbf7d0;
        border-radius: 10px; padding: 12px 16px;
        display: flex; align-items: center; gap: 10px;
        font-size: 12.5px; color: #15803d;
        margin-bottom: 24px;
    }
    .alert-success i { font-size: 15px; flex-shrink: 0; }

    /* ==============================================================
       FORM ACTION BUTTONS
    ============================================================== */
    .form-actions {
        display: flex; align-items: center; gap: 10px;
        padding: 18px 24px;
        background: #f8fafc;
        border-top: 1px solid #f1f5f9;
        flex-wrap: wrap;
    }

    .btn-save {
        background: #2563eb !important; color: #fff !important;
        border: none !important; border-radius: 8px !important;
        padding: 9px 22px !important; font-size: 13px !important;
        font-weight: 600 !important; font-family: inherit !important;
        cursor: pointer !important;
        display: flex !important; align-items: center !important; gap: 7px !important;
        transition: background .12s, transform .1s !important;
    }
    .btn-save:hover  { background: #1d4ed8 !important; }
    .btn-save:active { transform: scale(0.98) !important; }
    .btn-save:disabled {
        background: #93c5fd !important; cursor: not-allowed !important;
    }

    .btn-cancel {
        background: #fff !important; color: #374151 !important;
        border: 1px solid #d1d5db !important; border-radius: 8px !important;
        padding: 9px 18px !important; font-size: 13px !important;
        font-weight: 500 !important; font-family: inherit !important;
        cursor: pointer !important; text-decoration: none !important;
        display: flex !important; align-items: center !important; gap: 7px !important;
        transition: background .12s !important;
    }
    .btn-cancel:hover { background: #f9fafb !important; color: #111827 !important; }

    .btn-delete {
        background: #fef2f2 !important; color: #dc2626 !important;
        border: 1px solid #fecaca !important; border-radius: 8px !important;
        padding: 9px 18px !important; font-size: 13px !important;
        font-weight: 600 !important; font-family: inherit !important;
        cursor: pointer !important;
        display: flex !important; align-items: center !important; gap: 7px !important;
        transition: background .12s !important;
        margin-left: auto !important; /* pushes Delete to the far right */
    }
    .btn-delete:hover { background: #fee2e2 !important; }

    /* ==============================================================
       PRODUCT PREVIEW CARD  (live preview on the right column)
    ============================================================== */
    .preview-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        overflow: hidden;
        position: sticky;
        top: 76px; /* sticks just below the navbar */
    }
    .preview-card-header {
        padding: 14px 18px;
        border-bottom: 1px solid #f1f5f9;
        font-size: 12px; font-weight: 700; color: #64748b;
        text-transform: uppercase; letter-spacing: .07em;
        display: flex; align-items: center; gap: 8px;
    }
    .preview-card-header i { color: #cbd5e1; font-size: 13px; }

    .preview-body { padding: 20px 18px; }

    .preview-icon-box {
        width: 56px; height: 56px; border-radius: 14px;
        background: linear-gradient(135deg, #eff6ff, #dbeafe);
        display: flex; align-items: center; justify-content: center;
        font-size: 24px; color: #2563eb;
        margin-bottom: 14px;
    }

    .preview-product-name {
        font-size: 16px; font-weight: 700; color: #0f172a;
        margin-bottom: 3px; letter-spacing: -0.01em;
        min-height: 22px;
    }
    .preview-sku {
        font-family: 'Courier New', monospace;
        font-size: 11px; font-weight: 700; color: #2563eb;
        background: #eff6ff; padding: 2px 8px; border-radius: 5px;
        display: inline-block; margin-bottom: 14px;
        min-width: 60px;
    }

    .preview-divider {
        height: 1px; background: #f1f5f9; margin: 14px 0;
    }

    .preview-row {
        display: flex; justify-content: space-between; align-items: center;
        margin-bottom: 10px;
    }
    .preview-row:last-child { margin-bottom: 0; }
    .preview-row-label { font-size: 11px; color: #94a3b8; font-weight: 500; }
    .preview-row-val   { font-size: 12.5px; color: #0f172a; font-weight: 600; }
    .preview-row-val.price { color: #059669; font-size: 14px; }

    .preview-stock-badge {
        font-size: 11px; font-weight: 700;
        padding: 3px 10px; border-radius: 20px;
    }
    .preview-stock-badge.ok       { background: #f0fdf4; color: #15803d; }
    .preview-stock-badge.low      { background: #fffbeb; color: #b45309; }
    .preview-stock-badge.critical { background: #fef2f2; color: #dc2626; }

    /* ==============================================================
       TIPS CARD (below preview)
    ============================================================== */
    .tips-card {
        background: #fffbeb;
        border: 1px solid #fde68a;
        border-radius: 12px;
        padding: 14px 16px;
        margin-top: 14px;
    }
    .tips-card-title {
        font-size: 11.5px; font-weight: 700; color: #92400e;
        margin-bottom: 8px;
        display: flex; align-items: center; gap: 6px;
    }
    .tips-card-title i { font-size: 13px; color: #f59e0b; }
    .tip-item {
        font-size: 11px; color: #78350f;
        display: flex; align-items: flex-start; gap: 6px;
        margin-bottom: 6px; line-height: 1.5;
    }
    .tip-item:last-child { margin-bottom: 0; }
    .tip-dot {
        width: 4px; height: 4px; border-radius: 50%;
        background: #f59e0b; margin-top: 5px; flex-shrink: 0;
    }

    /* ==============================================================
       FOOTER
    ============================================================== */
    .main-footer {
        background: #fff !important; border-top: 1px solid #e2e8f0 !important;
        padding: 12px 24px !important; font-size: 11.5px !important;
        color: #94a3b8 !important; text-align: center !important;
    }

    /* ==============================================================
       RESPONSIVE TWEAKS
    ============================================================== */
    @media (max-width: 991px) {
        .preview-card { position: static; margin-top: 20px; }
    }
    @media (max-width: 768px) {
        .page-heading { flex-direction: column; }
        .form-card-body { padding: 20px 16px; }
        .form-actions { padding: 14px 16px; }
        .btn-delete { margin-left: 0 !important; width: 100%; justify-content: center; }
    }
    </style>
</head>

<%-- ================================================================
     BODY
     AdminLTE requires: class="hold-transition sidebar-mini layout-fixed layout-navbar-fixed"
     This keeps the sidebar collapsible and the navbar stuck to the top.
================================================================ --%>
<body class="hold-transition sidebar-mini layout-fixed layout-navbar-fixed">
<div class="wrapper">

<!-- ================================================================
     TOP NAVIGATION BAR
================================================================ -->
<nav class="main-header navbar navbar-expand navbar-white navbar-light">

    <%-- Hamburger + breadcrumb --%>
    <ul class="navbar-nav align-items-center">
        <li class="nav-item">
            <a class="nav-link px-2" data-widget="pushmenu" href="#" role="button">
                <i class="fas fa-bars" style="color:#64748b;font-size:16px"></i>
            </a>
        </li>
        <li class="nav-item d-none d-sm-flex align-items-center">
            <%-- Dynamic breadcrumb: Products > Add Product  or  Products > Edit Product --%>
            <div class="topbar-breadcrumb">
                <i class="fas fa-home" style="font-size:12px"></i>
                <span style="color:#cbd5e1">/</span>
                <a href="${pageContext.request.contextPath}/products?action=list"
                   style="color:#2563eb;text-decoration:none;font-weight:500">Products</a>
                <span style="color:#cbd5e1">/</span>
                <span class="crumb-active">
                    <c:choose>
                        <c:when test="${formMode == 'edit'}">Edit Product</c:when>
                        <c:otherwise>Add Product</c:otherwise>
                    </c:choose>
                </span>
            </div>
        </li>
    </ul>

    <%-- Right side: user --%>
    <ul class="navbar-nav ml-auto align-items-center">
        <li class="nav-item dropdown">
            <a href="#" class="nav-link p-0" data-toggle="dropdown">
                <div class="topbar-user-wrap">
                    <%-- Show first two letters of username as avatar --%>
                    <div class="topbar-avatar">
                        ${fn:toUpperCase(fn:substring(sessionScope.userFullName, 0, 2))}
                    </div>
                    <div class="d-none d-sm-block">
                        <div class="topbar-user-name">${sessionScope.userFullName}</div>
                        <div class="topbar-user-role">${sessionScope.userRole}</div>
                    </div>
                </div>
            </a>
            <div class="dropdown-menu dropdown-menu-right"
                 style="border:1px solid #e2e8f0;border-radius:10px;box-shadow:0 8px 20px rgba(0,0,0,.08);font-size:12.5px;min-width:160px;padding:6px;">
                <a class="dropdown-item" href="${pageContext.request.contextPath}/logout"
                   style="border-radius:7px;padding:8px 12px;color:#dc2626;">
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
    <%-- Brand / Logo --%>
    <a href="${pageContext.request.contextPath}/dashboard" class="brand-link">
        <div class="brand-logo-box"><i class="fas fa-cubes"></i></div>
        <div class="brand-text-wrap">
            <span class="brand-name">Jare Pharmacy</span>
            <span class="brand-sub">SME Inventory Hub</span>
        </div>
    </a>

    <div class="sidebar">
        <%-- User panel --%>
        <div class="user-panel mt-2 pb-2 mb-1 d-flex">
            <div class="sidebar-user-avatar">
                ${fn:toUpperCase(fn:substring(sessionScope.userFullName, 0, 2))}
            </div>
            <div class="info">
                <a href="#">${sessionScope.userFullName}</a>
                <small>${sessionScope.userRole}</small>
            </div>
        </div>

        <%-- Navigation links --%>
        <nav class="mt-2 pb-3">
            <ul class="nav nav-pills nav-sidebar flex-column" data-widget="treeview" role="menu">

                <li class="nav-header">Main Menu</li>

                <li class="nav-item">
                    <a href="${pageContext.request.contextPath}/dashboard" class="nav-link">
                        <i class="nav-icon fas fa-tachometer-alt"></i>
                        <p>Dashboard</p>
                    </a>
                </li>

                <li class="nav-header">Inventory</li>

                <%-- Products is ACTIVE (we are inside the product section) --%>
                <li class="nav-item">
                    <a href="${pageContext.request.contextPath}/products?action=list"
                       class="nav-link active">
                        <i class="nav-icon fas fa-box"></i>
                        <p>Products</p>
                    </a>
                </li>

                <li class="nav-item">
                    <a href="<%=request.getContextPath()%>/categories?action=list" class="nav-link">
                        <i class="nav-icon fas fa-tags"></i>
                        <p>Categories</p>
                    </a>
                </li>

                <li class="nav-item">
                    <a href="<%=request.getContextPath()%>/suppliers?action=list" class="nav-link">
                        <i class="nav-icon fas fa-truck"></i>
                        <p>Suppliers</p>
                    </a>
                </li>


                <li class="nav-header">Sales</li>

                <li class="nav-item">
                    <a href="<%=request.getContextPath()%>/sales?action=pos" class="nav-link">
                        <i class="nav-icon fas fa-shopping-cart"></i>
                        <p>Point of Sale</p>
                    </a>
                </li>


                <li class="nav-header">Reports</li>

                <li class="nav-item">
                    <a href="#" class="nav-link">
                        <i class="nav-icon fas fa-chart-bar"></i>
                        <p>Reports</p>
                    </a>
                </li>

                <li class="nav-header">Account</li>

                <li class="nav-item">
                    <a href="${pageContext.request.contextPath}/logout" class="nav-link"
                       style="color:#ef4444 !important;">
                        <i class="nav-icon fas fa-sign-out-alt"></i>
                        <p>Sign Out</p>
                    </a>
                </li>

            </ul>
        </nav>
    </div>
</aside>

<!-- ================================================================
     MAIN CONTENT WRAPPER
================================================================ -->
<div class="content-wrapper">
<div class="page-content">

    <%-- Page Heading --%>
    <div class="page-heading">
        <div>
            <h2>
                <c:choose>
                    <c:when test="${formMode == 'edit'}">
                        <i class="fas fa-pen-to-square" style="color:#2563eb;margin-right:8px;font-size:18px"></i>Edit Product
                    </c:when>
                    <c:otherwise>
                        <i class="fas fa-plus-circle" style="color:#2563eb;margin-right:8px;font-size:18px"></i>Add New Product
                    </c:otherwise>
                </c:choose>
            </h2>
            <p>
                <c:choose>
                    <c:when test="${formMode == 'edit'}">Modify details for ${product.name}</c:when>
                    <c:otherwise>Create a new item profile in the inventory database</c:otherwise>
                </c:choose>
            </p>
        </div>
    </div>

    <%-- Server-Side Validation Error Message Banner --%>
    <c:if test="${not empty errorMessage}">
        <div class="alert-error">
            <i class="fas fa-exclamation-circle"></i>
            <span><c:out value="${errorMessage}"/></span>
        </div>
    </c:if>

    <div class="row">
        <div class="col-lg-8">
            <div class="form-card">
                <div class="form-card-header">
                    <div class="form-card-title">
                        <div class="form-card-icon">
                            <i class="fas fa-box-open"></i>
                        </div>
                        <div>
                            <h3>Product Specifications</h3>
                            <p>All fields marked with an asterisk (*) are mandatory</p>
                        </div>
                    </div>
                    <span class="mode-badge ${formMode == 'edit' ? 'edit' : 'add'}">
                        ${formMode == 'edit' ? 'Edit Mode' : 'Add Mode'}
                    </span>
                </div>

                <%-- DYNAMIC ROUTING FORM ACCORDING TO SERVLET ACTION SPECIFICATIONS --%>
                <form action="${pageContext.request.contextPath}/products?action=${formMode == 'edit' ? 'update' : 'create'}" method="POST">
                    
                    <%-- Hidden Database Primary Key ID Required for updates --%>
                    <c:if test="${formMode == 'edit'}">
                        <input type="hidden" name="id" value="${product.id}" />
                    </c:if>

                    <div class="form-card-body">
                        
                        <div class="form-section">
                            <div class="form-section-title">
                                <i class="fas fa-tag"></i> Identity & Classification
                            </div>
                            
                            <div class="row">
                                <div class="col-md-8 field-group">
                                    <label class="field-label">Product Name <span class="req">*</span></label>
                                    <input type="text" id="inputName" name="name" class="field-input" placeholder="e.g. Dangote Sugar 1kg" value="<c:out value='${product.name}'/>" required maxlength="100">
                                </div>
                                <div class="col-md-4 field-group">
                                    <label class="field-label">SKU Code <span class="req">*</span></label>
                                    <input type="text" id="inputSku" name="sku" class="field-input" placeholder="e.g. DG-SG-001" value="<c:out value='${product.sku}'/>" required ${formMode == 'edit' ? 'readonly' : ''}>
                                </div>
                            </div>

                            <div class="row">
                                <div class="col-md-6 field-group">
                                    <label class="field-label">Category <span class="req">*</span></label>
                                    <select name="categoryId" class="field-select" required>
                                        <option value="">-- Select Category --</option>
                                        <c:forEach var="cat" items="${categories}">
                                            <option value="${cat.id}" ${product.categoryId == cat.id ? 'selected' : ''}>
                                                <c:out value="${cat.name}"/>
                                            </option>
                                        </c:forEach>
                                    </select>
                                </div>
                                <div class="col-md-6 field-group">
                                    <label class="field-label">Supplier <span class="req">*</span></label>
                                    <select name="supplierId" class="field-select" required>
                                        <option value="">-- Select Supplier --</option>
                                        <c:forEach var="sup" items="${suppliers}">
                                            <option value="${sup.id}" ${product.supplierId == sup.id ? 'selected' : ''}>
                                                <c:out value="${sup.name}"/>
                                            </option>
                                        </c:forEach>
                                    </select>
                                </div>
                            </div>
                            
                            <div class="row">
                                <div class="col-md-6 field-group">
                                    <label class="field-label">Unit of Measure</label>
                                    <input type="text" name="unit" class="field-input" placeholder="e.g. piece, pack, bottle, kg" value="<c:out value='${product.unit}'/>">
                                </div>
                            </div>
                        </div>

                        <div class="form-section">
                            <div class="form-section-title">
                                <i class="fas fa-money-bill-wave"></i> Financials & Pricing
                            </div>
                            <div class="row">
                                <div class="col-md-6 field-group">
                                    <label class="field-label">Cost Price <span class="req">*</span></label>
                                    <div class="input-prefix-wrap">
                                        <span class="input-prefix">₦</span>
                                        <input type="number" step="0.01" min="0" id="inputCost" name="costPrice" class="field-input" placeholder="0.00" value="${product.costPrice > 0 ? product.costPrice : ''}" required>
                                    </div>
                                </div>
                                <div class="col-md-6 field-group">
                                    <label class="field-label">Selling Price <span class="req">*</span></label>
                                    <div class="input-prefix-wrap">
                                        <span class="input-prefix">₦</span>
                                        <input type="number" step="0.01" min="0" id="inputSelling" name="sellingPrice" class="field-input" placeholder="0.00" value="${product.sellingPrice > 0 ? product.sellingPrice : ''}" required>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="form-section">
                            <div class="form-section-title">
                                <i class="fas fa-boxes-stacked"></i> Stock Control Limits
                            </div>
                            <div class="row">
                                <div class="col-md-6 field-group">
                                    <label class="field-label">Current Stock Quantity <span class="req">*</span></label>
                                    <input type="number" min="0" id="inputStock" name="currentStock" class="field-input" placeholder="0" value="${product.currentStock >= 0 ? product.currentStock : '0'}" required>
                                </div>
                                <div class="col-md-6 field-group">
                                    <label class="field-label">Reorder Level Threshold <span class="req">*</span></label>
                                    <input type="number" min="0" id="inputReorder" name="reorderLevel" class="field-input" placeholder="5" value="${product.reorderLevel >= 0 ? product.reorderLevel : '5'}" required>
                                </div>
                            </div>
                        </div>

                    </div>

                    <div class="form-actions">
                        <button type="submit" class="btn-save">
                            <i class="fas fa-save"></i> Commit Changes
                        </button>
                        <a href="${pageContext.request.contextPath}/products?action=list" class="btn-cancel">
                            Cancel
                        </a>
                        
                        <c:if test="${formMode == 'edit'}">
                            <button type="button" class="btn-delete" onclick="handleFormDelete(${product.id})">
                                <i class="fas fa-trash-can"></i> Delete Product
                            </button>
                        </c:if>
                    </div>
                </form>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="preview-card">
                <div class="preview-card-header">
                    <i class="fas fa-eye"></i> Live Monitor Preview
                </div>
                <div class="preview-body">
                    <div class="preview-icon-box">
                        <i class="fas fa-box"></i>
                    </div>
                    <div class="preview-product-name" id="previewName">---</div>
                    <div class="preview-sku" id="previewSku">---</div>
                    
                    <div class="preview-divider"></div>
                    
                    <div class="preview-row">
                        <span class="preview-row-label">Cost Valuation:</span>
                        <span class="preview-row-val" id="previewCost">₦0.00</span>
                    </div>
                    <div class="preview-row">
                        <span class="preview-row-label">Market Retail Price:</span>
                        <span class="preview-row-val price" id="previewSelling">₦0.00</span>
                    </div>
                    
                    <div class="preview-divider"></div>
                    
                    <div class="preview-row">
                        <span class="preview-row-label">Physical Balance:</span>
                        <span class="preview-row-val" id="previewStockQty">0 Units</span>
                    </div>
                    <div class="preview-row">
                        <span class="preview-row-label">Status Level:</span>
                        <span class="preview-stock-badge ok" id="previewStockStatus">In Stock</span>
                    </div>
                </div>
            </div>
        </div>
    </div>

</div>
</div>

<script src="assets/plugins/jquery/jquery.min.js"></script>
<script src="assets/plugins/bootstrap/js/bootstrap.bundle.min.js"></script>
<script src="assets/js/adminlte.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<script>
$(document).ready(function() {
    function updateLivePreview() {
        var name = $('#inputName').val().trim();
        var sku = $('#inputSku').val().trim();
        var cost = parseFloat($('#inputCost').val()) || 0;
        var selling = parseFloat($('#inputSelling').val()) || 0;
        var stock = parseInt($('#inputStock').val()) || 0;
        var reorder = parseInt($('#inputReorder').val()) || 0;

        $('#previewName').text(name !== "" ? name : "---");
        $('#previewSku').text(sku !== "" ? sku : "---");
        $('#previewCost').text("₦" + cost.toLocaleString('en-US', {minimumFractionDigits: 2}));
        $('#previewSelling').text("₦" + selling.toLocaleString('en-US', {minimumFractionDigits: 2}));
        $('#previewStockQty').text(stock + " Units");

        var badge = $('#previewStockStatus');
        badge.removeClass('ok low critical');
        
        if (stock === 0) {
            badge.addClass('critical').text('Out of Stock');
        } else if (stock <= reorder) {
            badge.addClass('low').text('Low Stock');
        } else {
            badge.addClass('ok').text('Healthy Stock');
        }
    }

    $('#inputName, #inputSku, #inputCost, #inputSelling, #inputStock, #inputReorder').on('input change', updateLivePreview);
    updateLivePreview();
});

function handleFormDelete(productId) {
    Swal.fire({
        title: 'Are you absolutely sure?',
        text: "This action cannot be undone. This product record will be purged from the database.",
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#dc2626',
        cancelButtonColor: '#64748b',
        confirmButtonText: 'Yes, delete it!'
    }).then((result) => {
        if (result.isConfirmed) {
            window.location.href = "${pageContext.request.contextPath}/products?action=delete&id=" + productId;
        }
    });
}
</script>
</body>
</html>