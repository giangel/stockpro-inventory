<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="com.inventory.model.Category, java.util.List, java.time.format.DateTimeFormatter" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core"      prefix="c"  %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions"  prefix="fn" %>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>StockPro | Categories</title>

<!-- Google Font: Inter -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

<!-- Font Awesome 6 -->
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
   DESIGN TOKENS - identical to dashboard.jsp
================================================================ */
:root {
    --blue:        #2563eb;
    --blue-hover:  #1d4ed8;
    --blue-light:  #eff6ff;
    --blue-mid:    #dbeafe;
    --slate-900:   #0f172a;
    --slate-700:   #374151;
    --slate-600:   #475569;
    --slate-500:   #64748b;
    --slate-400:   #94a3b8;
    --slate-300:   #cbd5e1;
    --slate-200:   #e2e8f0;
    --slate-100:   #f1f5f9;
    --slate-50:    #f8fafc;
    --green:       #059669;
    --green-light: #f0fdf4;
    --green-mid:   #bbf7d0;
    --red:         #dc2626;
    --red-light:   #fef2f2;
    --red-mid:     #fecaca;
    --amber:       #d97706;
    --amber-light: #fffbeb;
    --surface:     #ffffff;
    --page-bg:     #f1f5f9;
    --border:      #e2e8f0;
    --border-soft: #f1f5f9;
    --radius-sm:   6px;
    --radius-md:   10px;
    --radius-lg:   12px;
    --radius-xl:   16px;
    --shadow-sm:   0 1px 3px rgba(0,0,0,.06), 0 1px 2px rgba(0,0,0,.04);
    --shadow-md:   0 4px 12px rgba(0,0,0,.08);
    --shadow-lg:   0 8px 24px rgba(0,0,0,.12);
}

/* ================================================================
   GLOBAL RESET
================================================================ */
*, *::before, *::after { box-sizing: border-box; }

body,
.content-wrapper,
.main-sidebar,
.main-header,
.main-footer {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif !important;
}
body {
    background: var(--page-bg) !important;
    color: var(--slate-900) !important;
    font-size: 13px !important;
}

/* ================================================================
   SIDEBAR  (pixel-perfect match with dashboard.jsp)
================================================================ */
.main-sidebar {
    background: var(--slate-900) !important;
    box-shadow: none !important;
    border-right: none !important;
    width: 230px !important;
}
.brand-link {
    background: var(--slate-900) !important;
    border-bottom: 1px solid rgba(255,255,255,.06) !important;
    padding: 16px !important;
    display: flex !important;
    align-items: center !important;
    gap: 10px !important;
    text-decoration: none !important;
}
.brand-logo-box {
    width: 32px; height: 32px; background: var(--blue);
    border-radius: 9px; display: flex; align-items: center;
    justify-content: center; flex-shrink: 0;
}
.brand-logo-box i { color: #fff; font-size: 15px; }
.brand-text-wrap .brand-name {
    font-size: 15px; font-weight: 700; color: #fff;
    letter-spacing: -.01em; display: block;
}
.brand-text-wrap .brand-sub {
    font-size: 10px; color: var(--slate-600); font-weight: 400;
    display: block; margin-top: 1px;
}
.user-panel {
    background: transparent !important;
    border-bottom: 1px solid rgba(255,255,255,.06) !important;
    padding: 12px 16px !important;
    display: flex; align-items: center; gap: 10px;
}
.sidebar-user-avatar {
    width: 32px; height: 32px; border-radius: 50%;
    background: #1e3a8a; display: flex; align-items: center;
    justify-content: center; font-size: 12px; font-weight: 700;
    color: #bfdbfe; flex-shrink: 0;
}
.user-panel .info a {
    color: var(--slate-300) !important; font-size: 12.5px !important;
    font-weight: 600 !important; text-decoration: none !important; display: block;
}
.user-panel .info small { color: var(--slate-600); font-size: 10.5px; }

.nav-sidebar .nav-header {
    font-size: 9.5px !important; font-weight: 700 !important;
    letter-spacing: .08em !important; color: #334155 !important;
    text-transform: uppercase !important; padding: 14px 16px 4px !important;
}
.nav-sidebar .nav-item .nav-link {
    color: var(--slate-400) !important; border-radius: 8px !important;
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
    color: #60a5fa !important; border-left-color: var(--blue) !important;
}
.nav-sidebar .nav-link .nav-icon {
    font-size: 14px !important; width: 16px !important;
    text-align: center; flex-shrink: 0;
}
.nav-sidebar .nav-link p { margin: 0 !important; font-size: 12.5px !important; line-height: 1 !important; }
.nav-alert-badge {
    margin-left: auto; background: var(--red); color: #fff;
    font-size: 9px; font-weight: 700; padding: 2px 7px;
    border-radius: 20px; line-height: 1.4;
}

/* ================================================================
   TOP NAVBAR
================================================================ */
.main-header.navbar {
    background: var(--surface) !important;
    border-bottom: 1px solid var(--border) !important;
    box-shadow: none !important; min-height: 54px !important; padding: 0 20px !important;
}
.topbar-breadcrumb {
    font-size: 12px; color: var(--slate-500);
    display: flex; align-items: center; gap: 5px; margin-left: 8px;
}
.topbar-breadcrumb .crumb-active { color: var(--slate-900); font-weight: 600; }
.live-badge {
    display: flex; align-items: center; gap: 6px;
    font-size: 11px; font-weight: 600; color: var(--green);
    background: var(--green-light); border: 1px solid var(--green-mid);
    border-radius: 20px; padding: 4px 11px;
}
.live-dot { width: 7px; height: 7px; border-radius: 50%; background: #22c55e; flex-shrink: 0; }
.topbar-bell {
    position: relative; cursor: pointer; color: var(--slate-500);
    font-size: 17px; padding: 6px;
}
.topbar-bell .bell-dot {
    position: absolute; top: 4px; right: 4px; width: 8px; height: 8px;
    border-radius: 50%; background: var(--red); border: 1.5px solid #fff;
}
.topbar-user-wrap {
    display: flex; align-items: center; gap: 8px; cursor: pointer;
    padding: 4px 8px; border-radius: 9px; transition: background .12s;
}
.topbar-user-wrap:hover { background: var(--slate-100); }
.topbar-avatar {
    width: 32px; height: 32px; border-radius: 50%; background: var(--blue-mid);
    display: flex; align-items: center; justify-content: center;
    font-size: 12px; font-weight: 700; color: #1d4ed8; flex-shrink: 0;
}
.topbar-user-name { font-size: 12.5px; font-weight: 600; color: var(--slate-900); line-height: 1.2; }
.topbar-user-role { font-size: 10.5px; color: var(--slate-400); }

/* ================================================================
   CONTENT WRAPPER
================================================================ */
.content-wrapper { background: var(--page-bg) !important; padding: 0 !important; }
.page-content { padding: 22px 24px; }

/* Page heading row */
.page-heading {
    display: flex; align-items: flex-start;
    justify-content: space-between; margin-bottom: 20px;
    flex-wrap: wrap; gap: 12px;
}
.page-heading h2 {
    font-size: 20px; font-weight: 700; color: var(--slate-900);
    margin: 0 0 3px; letter-spacing: -.01em;
}
.page-heading p { font-size: 12px; color: var(--slate-500); margin: 0; }

/* ================================================================
   BUTTONS
================================================================ */
.btn-primary-custom {
    background: var(--blue) !important; color: #fff !important;
    border: none !important; border-radius: 8px !important;
    padding: 9px 16px !important; font-size: 12.5px !important;
    font-weight: 600 !important; cursor: pointer !important;
    display: inline-flex !important; align-items: center !important;
    gap: 6px !important; transition: background .12s !important;
    text-decoration: none !important;
}
.btn-primary-custom:hover { background: var(--blue-hover) !important; color: #fff !important; }

.btn-secondary-custom {
    background: var(--surface) !important; color: var(--slate-700) !important;
    border: 1px solid var(--border) !important; border-radius: 8px !important;
    padding: 9px 16px !important; font-size: 12.5px !important;
    font-weight: 500 !important; cursor: pointer !important;
    display: inline-flex !important; align-items: center !important;
    gap: 6px !important; transition: background .12s !important;
    text-decoration: none !important;
}
.btn-secondary-custom:hover { background: var(--slate-50) !important; color: #111827 !important; }

/* ================================================================
   FLASH ALERT BANNERS
================================================================ */
.flash-bar {
    display: flex; align-items: center; gap: 10px;
    padding: 12px 16px; border-radius: var(--radius-md);
    font-size: 12.5px; margin-bottom: 18px;
    animation: slideDown .25s ease;
}
.flash-bar i { font-size: 15px; flex-shrink: 0; }
.flash-success { background: var(--green-light); border: 1px solid var(--green-mid); color: #15803d; }
.flash-error   { background: var(--red-light);   border: 1px solid var(--red-mid);   color: #b91c1c; }
@keyframes slideDown {
    from { opacity: 0; transform: translateY(-8px); }
    to   { opacity: 1; transform: translateY(0);    }
}

/* ================================================================
   KPI STAT CARDS  (same pattern as dashboard)
================================================================ */
.kpi-row { margin-bottom: 20px; }
.kpi-card {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: var(--radius-lg); padding: 18px;
    position: relative; overflow: hidden;
    transition: box-shadow .15s, transform .15s; height: 100%;
}
.kpi-card:hover { box-shadow: var(--shadow-md); transform: translateY(-1px); }
.kpi-card::after {
    content: ''; position: absolute;
    bottom: 0; left: 0; right: 0; height: 3px;
    border-radius: 0 0 var(--radius-lg) var(--radius-lg);
}
.kpi-card.blue::after   { background: var(--blue); }
.kpi-card.green::after  { background: #22c55e; }
.kpi-card.amber::after  { background: #f59e0b; }
.kpi-card.purple::after { background: #7c3aed; }
.kpi-top {
    display: flex; align-items: center;
    justify-content: space-between; margin-bottom: 12px;
}
.kpi-label {
    font-size: 10.5px; font-weight: 700; color: var(--slate-500);
    text-transform: uppercase; letter-spacing: .06em;
}
.kpi-icon-box {
    width: 38px; height: 38px; border-radius: 10px;
    display: flex; align-items: center; justify-content: center;
    font-size: 17px; flex-shrink: 0;
}
.kpi-value {
    font-size: 28px; font-weight: 700; color: var(--slate-900);
    line-height: 1; margin-bottom: 7px; letter-spacing: -.02em;
}
.kpi-trend {
    display: flex; align-items: center; gap: 4px;
    font-size: 11.5px; font-weight: 500;
}
.trend-up   { color: var(--green); }
.trend-info { color: var(--slate-500); }
.trend-warn { color: var(--amber); }

/* ================================================================
   PANEL  (white card container)
================================================================ */
.panel {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: var(--radius-lg); overflow: hidden; margin-bottom: 16px;
}
.panel-header {
    display: flex; align-items: center;
    justify-content: space-between;
    padding: 14px 18px; border-bottom: 1px solid var(--border-soft);
}
.panel-title {
    font-size: 13.5px; font-weight: 600; color: var(--slate-900);
    display: flex; align-items: center; gap: 8px;
}
.panel-title i { font-size: 15px; color: var(--slate-400); }

/* ================================================================
   CATEGORY COLOUR PALETTE
   Each category gets a colour accent based on its index mod 8.
   This makes the list visually richer and easier to scan.
================================================================ */
.cat-palette-0 { --cat-bg: #eff6ff; --cat-fg: #2563eb; } /* Blue      */
.cat-palette-1 { --cat-bg: #f0fdf4; --cat-fg: #16a34a; } /* Green     */
.cat-palette-2 { --cat-bg: #faf5ff; --cat-fg: #7c3aed; } /* Purple    */
.cat-palette-3 { --cat-bg: #fff7ed; --cat-fg: #ea580c; } /* Orange    */
.cat-palette-4 { --cat-bg: #fef2f2; --cat-fg: #dc2626; } /* Red       */
.cat-palette-5 { --cat-bg: #fffbeb; --cat-fg: #d97706; } /* Amber     */
.cat-palette-6 { --cat-bg: #f0fdfa; --cat-fg: #0d9488; } /* Teal      */
.cat-palette-7 { --cat-bg: #fdf4ff; --cat-fg: #c026d3; } /* Pink      */

.cat-icon-box {
    width: 36px; height: 36px; border-radius: 10px;
    background: var(--cat-bg); color: var(--cat-fg);
    display: flex; align-items: center; justify-content: center;
    font-size: 15px; flex-shrink: 0;
}
.cat-color-dot {
    width: 9px; height: 9px; border-radius: 50%;
    background: var(--cat-fg); flex-shrink: 0;
    display: inline-block;
}

/* ================================================================
   DATA TABLE
================================================================ */
#categoryTable thead th {
    background: var(--slate-50) !important; color: var(--slate-500) !important;
    font-size: 10.5px !important; font-weight: 700 !important;
    text-transform: uppercase !important; letter-spacing: .06em !important;
    border-bottom: 1px solid var(--border) !important; border-top: none !important;
    padding: 11px 14px !important; white-space: nowrap;
}
#categoryTable tbody td {
    font-size: 12.5px !important; color: #1e293b !important;
    padding: 12px 14px !important;
    border-bottom: 1px solid var(--border-soft) !important;
    vertical-align: middle !important;
}
#categoryTable tbody tr:hover td { background: #fafafa !important; }
#categoryTable tbody tr:last-child td { border-bottom: none !important; }

/* Product count pill */
.count-pill {
    display: inline-flex; align-items: center; gap: 5px;
    padding: 3px 10px; border-radius: 20px;
    font-size: 11.5px; font-weight: 600; white-space: nowrap;
}
.count-pill.active { background: var(--blue-light); color: var(--blue); }
.count-pill.empty  { background: var(--slate-100);  color: var(--slate-400); }

/* Table action buttons */
.tbl-btn {
    width: 30px; height: 30px; border-radius: 7px; border: none;
    cursor: pointer; display: inline-flex; align-items: center;
    justify-content: center; font-size: 12.5px;
    transition: background .12s, transform .1s; margin-right: 2px;
}
.tbl-btn:active { transform: scale(.94); }
.tbl-btn-edit   { background: var(--blue-light); color: var(--blue); }
.tbl-btn-delete { background: var(--red-light);  color: var(--red); }
.tbl-btn-edit:hover   { background: var(--blue-mid); }
.tbl-btn-delete:hover { background: var(--red-mid); }

/* Date chip */
.date-chip {
    font-size: 11px; color: var(--slate-400); white-space: nowrap;
    display: flex; align-items: center; gap: 5px;
}
.date-chip i { font-size: 10px; }

/* DataTables UI overrides */
.dataTables_wrapper .dataTables_filter input {
    border: 1px solid var(--border) !important; border-radius: 8px !important;
    font-size: 12px !important; padding: 6px 12px !important;
    color: var(--slate-900) !important; font-family: inherit !important; margin-left: 6px;
}
.dataTables_wrapper .dataTables_filter input:focus {
    outline: none !important; border-color: #93c5fd !important;
}
.dataTables_wrapper .dataTables_length select {
    border: 1px solid var(--border) !important; border-radius: 7px !important;
    font-size: 12px !important; font-family: inherit !important; padding: 4px 8px !important;
}
.dataTables_wrapper .dataTables_info,
.dataTables_wrapper .dataTables_paginate {
    font-size: 11.5px !important; color: var(--slate-400) !important;
    padding: 10px 16px !important; border-top: 1px solid var(--border-soft) !important;
}
.dataTables_wrapper .paginate_button {
    border-radius: 7px !important; font-size: 12px !important;
    font-family: inherit !important; padding: 4px 9px !important; border: none !important;
}
.dataTables_wrapper .paginate_button.current,
.dataTables_wrapper .paginate_button.current:hover {
    background: var(--blue) !important; color: #fff !important; border: none !important;
}
.dataTables_wrapper .paginate_button:hover {
    background: var(--slate-100) !important; color: var(--slate-700) !important; border: none !important;
}
.dataTables_wrapper .dataTables_filter { margin-bottom: 0; }
.dataTables_wrapper .dataTables_length { margin-bottom: 0; }

/* ================================================================
   EMPTY STATE
================================================================ */
.empty-state { text-align: center; padding: 56px 24px; }
.empty-icon-wrap {
    width: 72px; height: 72px; border-radius: 20px;
    background: linear-gradient(135deg, var(--blue-light), var(--blue-mid));
    display: flex; align-items: center; justify-content: center;
    font-size: 30px; color: var(--blue); margin: 0 auto 18px;
}
.empty-title { font-size: 16px; font-weight: 700; color: var(--slate-900); margin-bottom: 6px; }
.empty-sub   { font-size: 12.5px; color: var(--slate-400); margin-bottom: 22px; }

/* ================================================================
   ADD / EDIT INLINE MODAL  (Bootstrap modal, styled to match)
================================================================ */
.cat-modal .modal-dialog {
    max-width: 480px;
}
.cat-modal .modal-content {
    border: none; border-radius: var(--radius-xl); box-shadow: var(--shadow-lg);
    overflow: hidden;
}
.cat-modal .modal-header {
    background: var(--slate-900); border: none;
    padding: 18px 22px;
}
.cat-modal .modal-title {
    font-size: 14px; font-weight: 700; color: #fff;
    display: flex; align-items: center; gap: 9px;
}
.cat-modal .modal-title i { font-size: 15px; color: #60a5fa; }
.cat-modal .close {
    color: var(--slate-400) !important; opacity: 1 !important; font-size: 20px;
    text-shadow: none !important;
}
.cat-modal .close:hover { color: #fff !important; }
.cat-modal .modal-body { padding: 24px 22px 8px; }
.cat-modal .modal-footer {
    padding: 14px 22px 20px; border: none; background: var(--slate-50);
    display: flex; align-items: center; gap: 8px;
}

/* Form field labels & inputs inside modal */
.field-label {
    display: block; font-size: 12px; font-weight: 600;
    color: var(--slate-700); margin-bottom: 6px;
}
.field-required { color: var(--red); margin-left: 2px; }
.field-group { margin-bottom: 16px; }

.field-input,
.field-textarea {
    width: 100%; border: 1px solid var(--border);
    border-radius: 8px; padding: 9px 12px;
    font-size: 13px; color: var(--slate-900);
    font-family: inherit; background: var(--surface);
    transition: border-color .15s, box-shadow .15s; outline: none;
}
.field-input:focus,
.field-textarea:focus {
    border-color: var(--blue);
    box-shadow: 0 0 0 3px rgba(37,99,235,.12);
}
.field-input::placeholder,
.field-textarea::placeholder { color: var(--slate-400); }
.field-textarea { resize: vertical; min-height: 88px; }

/* Char counter */
.char-count { font-size: 10.5px; color: var(--slate-400); text-align: right; margin-top: 4px; }

/* Colour picker for category accent (visual only - cosmetic feature) */
.colour-picker-row {
    display: flex; align-items: center; gap: 8px; flex-wrap: wrap;
    margin-top: 6px;
}
.colour-swatch {
    width: 26px; height: 26px; border-radius: 8px; border: 2px solid transparent;
    cursor: pointer; transition: transform .12s, border-color .12s;
}
.colour-swatch:hover { transform: scale(1.15); }
.colour-swatch.selected { border-color: var(--slate-900); transform: scale(1.1); }

/* Modal save button */
.btn-modal-save {
    background: var(--blue); color: #fff; border: none;
    border-radius: 8px; padding: 9px 22px; font-size: 13px;
    font-weight: 600; font-family: inherit; cursor: pointer;
    display: inline-flex; align-items: center; gap: 7px;
    transition: background .12s, transform .1s;
}
.btn-modal-save:hover   { background: var(--blue-hover); }
.btn-modal-save:active  { transform: scale(0.98); }
.btn-modal-save:disabled { background: #93c5fd; cursor: not-allowed; }

.btn-modal-cancel {
    background: var(--surface); color: var(--slate-700);
    border: 1px solid var(--border); border-radius: 8px;
    padding: 9px 18px; font-size: 13px; font-weight: 500;
    font-family: inherit; cursor: pointer; text-decoration: none;
    display: inline-flex; align-items: center; gap: 7px;
    transition: background .12s;
}
.btn-modal-cancel:hover { background: var(--slate-50); color: #111827; }

/* Validation error state */
.field-input.is-error,
.field-textarea.is-error { border-color: var(--red) !important; }
.field-error-msg {
    font-size: 11px; color: var(--red); margin-top: 5px;
    display: flex; align-items: center; gap: 4px;
}

/* ================================================================
   FOOTER
================================================================ */
.main-footer {
    background: var(--surface) !important; border-top: 1px solid var(--border) !important;
    padding: 12px 24px !important; font-size: 11.5px !important;
    color: var(--slate-400) !important; text-align: center !important;
}

/* ================================================================
   RESPONSIVE
================================================================ */
@media (max-width: 768px) {
    .page-heading  { flex-direction: column; }
    .kpi-row .col-sm-6 { margin-bottom: 12px; }
}
</style>
</head>

<%-- ============================================================
     SCRIPTLET: pull session values for user display
============================================================ --%>
<%
    String sessionFullName = (String) session.getAttribute("userFullName");
    String sessionRole     = (String) session.getAttribute("userRole");
    if (sessionFullName == null) sessionFullName = "Administrator";
    if (sessionRole     == null) sessionRole     = "ADMIN";

    // Derive initials (up to 2 chars) for avatars
    String[] parts = sessionFullName.trim().split("\\s+");
    String initials = parts[0].substring(0,1).toUpperCase();
    if (parts.length > 1) initials += parts[parts.length-1].substring(0,1).toUpperCase();

    // Date formatter for LocalDateTime -> "12 Jan 2025"
    DateTimeFormatter dtFmt = DateTimeFormatter.ofPattern("dd MMM yyyy");

    // Fetch categories list from request attribute
    @SuppressWarnings("unchecked")
    List<Category> categories =
        (List<Category>) request.getAttribute("categories");
    if (categories == null) categories = new java.util.ArrayList<>();

    int totalCount   = categories.size();
    int usedCount    = 0;
    int emptyCount   = 0;
    int totalProducts = 0;
    for (Category cat : categories) {
        if (cat.getProductCount() > 0) usedCount++;
        else emptyCount++;
        totalProducts += cat.getProductCount();
    }

    // Flash messages
    String successMsg = (String) request.getAttribute("successMessage");
    String errorMsg   = (String) request.getAttribute("errorMessage");

    // Colour palette classes (cycles mod 8)
    String[] palettes = {
        "cat-palette-0","cat-palette-1","cat-palette-2","cat-palette-3",
        "cat-palette-4","cat-palette-5","cat-palette-6","cat-palette-7"
    };
%>

<body class="hold-transition sidebar-mini layout-fixed layout-navbar-fixed">
<div class="wrapper">

<!-- ==============================================================
     TOP NAVIGATION BAR
============================================================== -->
<nav class="main-header navbar navbar-expand navbar-white navbar-light">

    <!-- Left: hamburger + breadcrumb -->
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
                <a href="<%= request.getContextPath() %>/dashboard"
                   style="color:#64748b;text-decoration:none">Dashboard</a>
                <span style="color:#cbd5e1">/</span>
                <span class="crumb-active">Categories</span>
            </div>
        </li>
    </ul>

    <!-- Right: live badge, bell, user -->
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
                <%= java.time.LocalDate.now().format(DateTimeFormatter.ofPattern("EEEE, dd MMM yyyy")) %>
            </span>
        </li>
        <li class="nav-item">
            <div class="topbar-bell" title="Alerts">
                <i class="fas fa-bell"></i>
                <span class="bell-dot"></span>
            </div>
        </li>
        <li class="nav-item dropdown">
            <a href="#" class="nav-link p-0" data-toggle="dropdown">
                <div class="topbar-user-wrap">
                    <div class="topbar-avatar"><%= initials %></div>
                    <div class="d-none d-sm-block">
                        <div class="topbar-user-name"><%= sessionFullName %></div>
                        <div class="topbar-user-role"><%= sessionRole %></div>
                    </div>
                    <i class="fas fa-chevron-down ml-1" style="font-size:10px;color:#94a3b8"></i>
                </div>
            </a>
            <div class="dropdown-menu dropdown-menu-right border-0 shadow"
                 style="min-width:180px;margin-top:6px;border-radius:10px">
                <div class="dropdown-header py-2 px-3"
                     style="font-size:11px;color:#94a3b8;font-weight:700;text-transform:uppercase">
                    My Account
                </div>
                <a href="profile.jsp" class="dropdown-item py-2" style="font-size:13px">
                    <i class="fas fa-user-cog mr-2" style="color:#94a3b8;width:16px"></i>Profile settings
                </a>
                <div class="dropdown-divider m-0"></div>
                <a href="<%= request.getContextPath() %>/logout"
                   class="dropdown-item py-2" style="font-size:13px;color:#dc2626">
                    <i class="fas fa-sign-out-alt mr-2" style="width:16px"></i>Sign out
                </a>
            </div>
        </li>
    </ul>
</nav>

<!-- ==============================================================
     SIDEBAR
============================================================== -->
<aside class="main-sidebar elevation-0">
    <a href="<%= request.getContextPath() %>/dashboard" class="brand-link" style="text-decoration:none">
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
                <a href="#"><%= sessionFullName %></a>
                <small><%= sessionRole %></small>
            </div>
        </div>

        <nav class="mt-1">
            <ul class="nav nav-pills nav-sidebar flex-column" data-widget="treeview" role="menu">

                <li class="nav-header">Main</li>
                <li class="nav-item">
                    <a href="<%= request.getContextPath() %>/dashboard" class="nav-link">
                        <i class="nav-icon fas fa-tachometer-alt"></i><p>Dashboard</p>
                    </a>
                </li>

                <li class="nav-header">Catalogue</li>
                <li class="nav-item">
                    <a href="<%= request.getContextPath() %>/products?action=list" class="nav-link">
                        <i class="nav-icon fas fa-box-open"></i><p>Products</p>
                    </a>
                </li>
                <%-- Categories - ACTIVE on this page --%>
                <li class="nav-item">
                    <a href="<%= request.getContextPath() %>/categories?action=list" class="nav-link active">
                        <i class="nav-icon fas fa-tags"></i><p>Categories</p>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="<%= request.getContextPath() %>/suppliers?action=list" class="nav-link">
                        <i class="nav-icon fas fa-truck"></i><p>Suppliers</p>
                    </a>
                </li>

                <li class="nav-header">Operations</li>
                <li class="nav-item">
                    <a href="<%= request.getContextPath() %>/sales?action=pos" class="nav-link">
                        <i class="nav-icon fas fa-cash-register"></i><p>Point of Sale</p>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="<%= request.getContextPath() %>/inventory?action=list" class="nav-link">
                        <i class="nav-icon fas fa-warehouse"></i>
                        <p>Inventory <span class="nav-alert-badge">!</span></p>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="<%= request.getContextPath() %>/sales?action=history" class="nav-link">
                        <i class="nav-icon fas fa-file-invoice-dollar"></i><p>Sales History</p>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="<%= request.getContextPath() %>/reports.jsp" class="nav-link">
                        <i class="nav-icon fas fa-chart-bar"></i><p>Reports</p>
                    </a>
                </li>

            </ul>
        </nav>
    </div><!-- /sidebar -->
</aside>

<!-- ==============================================================
     MAIN CONTENT
============================================================== -->
<div class="content-wrapper">
<div class="page-content">

    <!-- Page heading -->
    <div class="page-heading">
        <div>
            <h2>
                <i class="fas fa-tags"
                   style="font-size:17px;color:#2563eb;margin-right:8px"></i>Category Management
            </h2>
            <p>Organise your product catalogue into clear, searchable categories</p>
        </div>
        <div class="d-flex" style="gap:8px;flex-wrap:wrap;align-items:center">
            <a href="<%= request.getContextPath() %>/products?action=list"
               class="btn-secondary-custom">
                <i class="fas fa-box-open"></i> View Products
            </a>
            <%-- Opens the Add modal --%>
            <button class="btn-primary-custom" id="btnOpenAddModal">
                <i class="fas fa-plus"></i> Add Category
            </button>
        </div>
    </div>

    <!-- ── Flash messages ──────────────────────────────────────── -->
    <% if (successMsg != null && !successMsg.isEmpty()) { %>
        <div class="flash-bar flash-success" id="flashBar">
            <i class="fas fa-check-circle"></i>
            <%= successMsg %>
        </div>
    <% } %>
    <% if (errorMsg != null && !errorMsg.isEmpty()) { %>
        <div class="flash-bar flash-error" id="flashBar">
            <i class="fas fa-exclamation-circle"></i>
            <%= errorMsg %>
        </div>
    <% } %>

    <!-- ==============================================================
         KPI CARDS  (4 stats: total / in-use / empty / total products)
    ============================================================== -->
    <div class="row kpi-row">

        <!-- Total categories -->
        <div class="col-xl-3 col-sm-6 mb-3">
            <div class="kpi-card blue">
                <div class="kpi-top">
                    <span class="kpi-label">Total Categories</span>
                    <div class="kpi-icon-box" style="background:#eff6ff">
                        <i class="fas fa-tags" style="color:#2563eb"></i>
                    </div>
                </div>
                <div class="kpi-value"><%= totalCount %></div>
                <div class="kpi-trend trend-info">
                    <i class="fas fa-folder" style="font-size:10px"></i>
                    Product groupings defined
                </div>
            </div>
        </div>

        <!-- In-use categories -->
        <div class="col-xl-3 col-sm-6 mb-3">
            <div class="kpi-card green">
                <div class="kpi-top">
                    <span class="kpi-label">In Use</span>
                    <div class="kpi-icon-box" style="background:#f0fdf4">
                        <i class="fas fa-circle-check" style="color:#059669"></i>
                    </div>
                </div>
                <div class="kpi-value"><%= usedCount %></div>
                <div class="kpi-trend trend-up">
                    <i class="fas fa-arrow-trend-up" style="font-size:10px"></i>
                    Categories with products
                </div>
            </div>
        </div>

        <!-- Empty categories -->
        <div class="col-xl-3 col-sm-6 mb-3">
            <div class="kpi-card amber">
                <div class="kpi-top">
                    <span class="kpi-label">Empty</span>
                    <div class="kpi-icon-box" style="background:#fffbeb">
                        <i class="fas fa-folder-open" style="color:#d97706"></i>
                    </div>
                </div>
                <div class="kpi-value"><%= emptyCount %></div>
                <div class="kpi-trend trend-warn">
                    <i class="fas fa-circle-info" style="font-size:10px"></i>
                    No products assigned yet
                </div>
            </div>
        </div>

        <!-- Total products across all categories -->
        <div class="col-xl-3 col-sm-6 mb-3">
            <div class="kpi-card purple">
                <div class="kpi-top">
                    <span class="kpi-label">Total Products</span>
                    <div class="kpi-icon-box" style="background:#faf5ff">
                        <i class="fas fa-boxes-stacked" style="color:#7c3aed"></i>
                    </div>
                </div>
                <div class="kpi-value"><%= totalProducts %></div>
                <div class="kpi-trend trend-info">
                    <i class="fas fa-layer-group" style="font-size:10px"></i>
                    Across all categories
                </div>
            </div>
        </div>

    </div><!-- /kpi-row -->

    <!-- ==============================================================
         CATEGORY TABLE PANEL
    ============================================================== -->
    <div class="panel">

        <div class="panel-header">
            <div class="panel-title">
                <i class="fas fa-list-ul"></i>
                All Categories
            </div>
            <span style="font-size:11.5px;color:#94a3b8">
                <%= totalCount %> <%= totalCount == 1 ? "category" : "categories" %>
            </span>
        </div>

        <div class="p-3">

        <% if (categories.isEmpty()) { %>
            <!-- ── EMPTY STATE ─────────────────────────────── -->
            <div class="empty-state">
                <div class="empty-icon-wrap">
                    <i class="fas fa-tags"></i>
                </div>
                <div class="empty-title">No categories yet</div>
                <div class="empty-sub">
                    Create your first category to start organising your product catalogue.
                </div>
                <button class="btn-primary-custom" id="btnEmptyAdd" style="margin:0 auto">
                    <i class="fas fa-plus"></i> Add First Category
                </button>
            </div>

        <% } else { %>
            <!-- ── CATEGORY TABLE ──────────────────────────── -->
            <%-- Table wrapper provides horizontal scroll on small screens --%>
            <div class="table-responsive">
            <table id="categoryTable" class="table table-hover" style="width:100%">
                <thead>
                    <tr>
                        <th style="width:44px">#</th>
                        <th>Category Name</th>
                        <th>Description</th>
                        <th style="width:130px">Products</th>
                        <th style="width:130px">Created</th>
                        <th style="width:90px">Actions</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    int rowIdx = 0;
                    for (Category cat : categories) {
                        String palette = palettes[rowIdx % palettes.length];
                        String createdStr = "-";
                        if (cat.getCreatedAt() != null) {
                            createdStr = cat.getCreatedAt().format(dtFmt);
                        }
                        int pCount = cat.getProductCount();
                        rowIdx++;
                %>
                    <tr>
                        <%-- Row number --%>
                        <td style="color:#94a3b8;font-size:11.5px"><%= rowIdx %></td>

                        <%-- Category name + coloured icon --%>
                        <td>
                            <div style="display:flex;align-items:center;gap:10px">
                                <div class="cat-icon-box <%= palette %>">
                                    <i class="fas fa-tag"></i>
                                </div>
                                <div>
                                    <div style="font-weight:600;color:#0f172a;font-size:13px;line-height:1.2">
                                        <%= cat.getName() %>
                                    </div>
                                    <div style="font-size:10.5px;color:#94a3b8;margin-top:2px">
                                        ID #<%= cat.getId() %>
                                    </div>
                                </div>
                            </div>
                        </td>

                        <%-- Description - truncated if long --%>
                        <td>
                            <% if (cat.getDescription() != null && !cat.getDescription().trim().isEmpty()) {
                                   String desc = cat.getDescription().trim();
                                   String display = desc.length() > 60 ? desc.substring(0, 57) + "…" : desc;
                            %>
                                <span style="color:#475569" title="<%= desc %>"><%= display %></span>
                            <% } else { %>
                                <span style="color:#cbd5e1;font-size:12px">No description</span>
                            <% } %>
                        </td>

                        <%-- Product count --%>
                        <td>
                            <span class="count-pill <%= pCount > 0 ? "active" : "empty" %>">
                                <i class="fas fa-box" style="font-size:10px"></i>
                                <%= pCount %> <%= pCount == 1 ? "product" : "products" %>
                            </span>
                        </td>

                        <%-- Created date --%>
                        <td>
                            <div class="date-chip">
                                <i class="far fa-calendar"></i>
                                <%= createdStr %>
                            </div>
                        </td>

                        <%-- Action buttons --%>
                        <td style="white-space:nowrap">
                            <%-- Edit: opens modal pre-filled --%>
                            <button class="tbl-btn tbl-btn-edit btn-edit-cat"
                                    data-id="<%= cat.getId() %>"
                                    data-name="<%= cat.getName().replace("\"","&quot;") %>"
                                    data-desc="<%= cat.getDescription() != null ? cat.getDescription().replace("\"","&quot;") : "" %>"
                                    title="Edit <%= cat.getName() %>">
                                <i class="fas fa-pen"></i>
                            </button>
                            <%-- Delete: SweetAlert2 confirmation --%>
                            <button class="tbl-btn tbl-btn-delete btn-delete-cat"
                                    data-id="<%= cat.getId() %>"
                                    data-name="<%= cat.getName().replace("\"","&quot;") %>"
                                    data-count="<%= pCount %>"
                                    title="Delete <%= cat.getName() %>">
                                <i class="fas fa-trash"></i>
                            </button>
                        </td>
                    </tr>
                <% } /* end for loop */ %>
                </tbody>
            </table>
            </div><!-- /table-responsive -->
        <% } %>

        </div><!-- /p-3 -->
    </div><!-- /panel -->

</div><!-- /page-content -->
</div><!-- /content-wrapper -->

<footer class="main-footer">
    <strong>&copy; 2025 StockPro</strong> - Built for Nigerian SMEs. All rights reserved.
</footer>

</div><!-- /wrapper -->


<!-- ==============================================================
     ADD CATEGORY MODAL
============================================================== -->
<div class="modal fade cat-modal" id="modalAddCategory" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">
                    <i class="fas fa-tag"></i> Add New Category
                </h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>

            <%-- POST to CategoryServlet with action=create --%>
            <form id="formAddCategory"
                  action="<%= request.getContextPath() %>/categories"
                  method="POST" novalidate>
                <input type="hidden" name="action" value="create">

                <div class="modal-body">

                    <%-- Name field --%>
                    <div class="field-group">
                        <label class="field-label" for="addName">
                            Category Name <span class="field-required">*</span>
                        </label>
                        <input type="text" id="addName" name="name"
                               class="field-input" maxlength="100"
                               placeholder="e.g. Food &amp; Grocery"
                               autocomplete="off">
                        <div class="field-error-msg" id="addNameError" style="display:none">
                            <i class="fas fa-circle-exclamation"></i>
                            <span></span>
                        </div>
                    </div>

                    <%-- Description field --%>
                    <div class="field-group">
                        <label class="field-label" for="addDesc">
                            Description <span style="color:#94a3b8;font-weight:400">(optional)</span>
                        </label>
                        <textarea id="addDesc" name="description"
                                  class="field-textarea" maxlength="300"
                                  placeholder="Brief description of what this category covers…"></textarea>
                        <div class="char-count">
                            <span id="addDescCount">0</span> / 300
                        </div>
                    </div>

                    <%-- Preview strip --%>
                    <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;
                                padding:12px 14px;display:flex;align-items:center;gap:12px;margin-top:4px">
                        <div class="cat-icon-box cat-palette-0" id="addPreviewIcon">
                            <i class="fas fa-tag"></i>
                        </div>
                        <div>
                            <div id="addPreviewName"
                                 style="font-weight:600;font-size:13px;color:#0f172a">
                                Category name will appear here
                            </div>
                            <div style="font-size:10.5px;color:#94a3b8;margin-top:2px">
                                Live preview
                            </div>
                        </div>
                    </div>

                </div><!-- /modal-body -->

                <div class="modal-footer">
                    <button type="submit" class="btn-modal-save" id="btnAddSave">
                        <i class="fas fa-save"></i> Save Category
                    </button>
                    <button type="button" class="btn-modal-cancel" data-dismiss="modal">
                        <i class="fas fa-times"></i> Cancel
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>


<!-- ==============================================================
     EDIT CATEGORY MODAL
============================================================== -->
<div class="modal fade cat-modal" id="modalEditCategory" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">
                    <i class="fas fa-pen-to-square"></i> Edit Category
                </h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>

            <form id="formEditCategory"
                  action="<%= request.getContextPath() %>/categories"
                  method="POST" novalidate>
                <input type="hidden" name="action" value="update">
                <input type="hidden" name="id"     id="editCatId" value="">

                <div class="modal-body">

                    <div class="field-group">
                        <label class="field-label" for="editName">
                            Category Name <span class="field-required">*</span>
                        </label>
                        <input type="text" id="editName" name="name"
                               class="field-input" maxlength="100"
                               placeholder="e.g. Food &amp; Grocery"
                               autocomplete="off">
                        <div class="field-error-msg" id="editNameError" style="display:none">
                            <i class="fas fa-circle-exclamation"></i>
                            <span></span>
                        </div>
                    </div>

                    <div class="field-group">
                        <label class="field-label" for="editDesc">
                            Description
                            <span style="color:#94a3b8;font-weight:400">(optional)</span>
                        </label>
                        <textarea id="editDesc" name="description"
                                  class="field-textarea" maxlength="300"
                                  placeholder="Brief description…"></textarea>
                        <div class="char-count">
                            <span id="editDescCount">0</span> / 300
                        </div>
                    </div>

                    <%-- Preview strip --%>
                    <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;
                                padding:12px 14px;display:flex;align-items:center;gap:12px;margin-top:4px">
                        <div class="cat-icon-box cat-palette-0" id="editPreviewIcon">
                            <i class="fas fa-tag"></i>
                        </div>
                        <div>
                            <div id="editPreviewName"
                                 style="font-weight:600;font-size:13px;color:#0f172a">
                                -
                            </div>
                            <div style="font-size:10.5px;color:#94a3b8;margin-top:2px">
                                Live preview
                            </div>
                        </div>
                    </div>

                </div><!-- /modal-body -->

                <div class="modal-footer">
                    <button type="submit" class="btn-modal-save" id="btnEditSave">
                        <i class="fas fa-save"></i> Update Category
                    </button>
                    <button type="button" class="btn-modal-cancel" data-dismiss="modal">
                        <i class="fas fa-times"></i> Cancel
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>


<!-- ==============================================================
     SCRIPTS
============================================================== -->
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>
<script src="https://cdn.datatables.net/1.13.4/js/jquery.dataTables.min.js"></script>
<script src="https://cdn.datatables.net/1.13.4/js/dataTables.bootstrap4.min.js"></script>
<script src="https://cdn.datatables.net/responsive/2.4.1/js/dataTables.responsive.min.js"></script>
<script src="https://cdn.datatables.net/responsive/2.4.1/js/responsive.bootstrap4.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<script>
$(document).ready(function () {

    /* =============================================================
       1.  DataTable
    ============================================================= */
    if ($('#categoryTable').length) {
        $('#categoryTable').DataTable({
            responsive:  true,
            pageLength:  10,
            order:       [[1, 'asc']],   // default: sort by name A->Z
            columnDefs:  [
                { orderable:  false, targets: [5] },   // Actions col
                { searchable: false, targets: [0, 3, 4, 5] }
            ],
            language: {
                search:      '',
                searchPlaceholder: 'Search categories…',
                lengthMenu:  'Show _MENU_ categories',
                info:        'Showing _START_–_END_ of _TOTAL_',
                emptyTable:  'No categories found.',
                zeroRecords: 'No categories match your search.'
            }
        });
    }

    /* =============================================================
       2.  Auto-dismiss flash banners after 5 s
    ============================================================= */
    setTimeout(function () {
        $('#flashBar').fadeOut(400);
    }, 5000);

    /* =============================================================
       3.  ADD MODAL - open
    ============================================================= */
    $('#btnOpenAddModal, #btnEmptyAdd').on('click', function () {
        // Reset the form
        $('#formAddCategory')[0].reset();
        $('#addNameError').hide();
        $('#addDescCount').text('0');
        $('#addPreviewName').text('Category name will appear here');
        $('#addName').removeClass('is-error');
        $('#modalAddCategory').modal('show');
        setTimeout(function(){ $('#addName').focus(); }, 300);
    });

    /* Live preview + char counter for ADD */
    $('#addName').on('input', function () {
        var v = $(this).val().trim();
        $('#addPreviewName').text(v || 'Category name will appear here');
    });
    $('#addDesc').on('input', function () {
        $('#addDescCount').text($(this).val().length);
    });

    /* ADD form client-side validation before submit */
    $('#formAddCategory').on('submit', function (e) {
        var name = $('#addName').val().trim();
        if (!name) {
            e.preventDefault();
            $('#addName').addClass('is-error').focus();
            $('#addNameError').show().find('span').text('Category name is required.');
            return false;
        }
        if (name.length < 2) {
            e.preventDefault();
            $('#addName').addClass('is-error').focus();
            $('#addNameError').show().find('span').text('Name must be at least 2 characters.');
            return false;
        }
        /* Show loading state */
        $('#btnAddSave').prop('disabled', true)
                        .html('<i class="fas fa-spinner fa-spin"></i> Saving…');
    });

    $('#addName').on('input', function () {
        if ($(this).val().trim()) {
            $(this).removeClass('is-error');
            $('#addNameError').hide();
        }
    });

    /* =============================================================
       4.  EDIT MODAL - open and pre-fill
    ============================================================= */
    $(document).on('click', '.btn-edit-cat', function () {
        var id   = $(this).data('id');
        var name = $(this).data('name');
        var desc = $(this).data('desc');

        /* Reset */
        $('#editCatId').val(id);
        $('#editName').val(name).removeClass('is-error');
        $('#editDesc').val(desc);
        $('#editNameError').hide();
        $('#editDescCount').text(desc ? desc.length : 0);
        $('#editPreviewName').text(name || '-');

        $('#modalEditCategory').modal('show');
        setTimeout(function(){ $('#editName').focus(); }, 300);
    });

    /* Live preview + char counter for EDIT */
    $('#editName').on('input', function () {
        var v = $(this).val().trim();
        $('#editPreviewName').text(v || '-');
    });
    $('#editDesc').on('input', function () {
        $('#editDescCount').text($(this).val().length);
    });

    /* EDIT form client-side validation */
    $('#formEditCategory').on('submit', function (e) {
        var name = $('#editName').val().trim();
        if (!name) {
            e.preventDefault();
            $('#editName').addClass('is-error').focus();
            $('#editNameError').show().find('span').text('Category name is required.');
            return false;
        }
        if (name.length < 2) {
            e.preventDefault();
            $('#editName').addClass('is-error').focus();
            $('#editNameError').show().find('span').text('Name must be at least 2 characters.');
            return false;
        }
        $('#btnEditSave').prop('disabled', true)
                         .html('<i class="fas fa-spinner fa-spin"></i> Updating…');
    });

    $('#editName').on('input', function () {
        if ($(this).val().trim()) {
            $(this).removeClass('is-error');
            $('#editNameError').hide();
        }
    });

    /* =============================================================
       5.  DELETE confirmation (SweetAlert2)
    ============================================================= */
    /*
       WHY SweetAlert2 and not a simple confirm()?
       - confirm() is synchronous and ugly; it blocks the UI thread.
       - SweetAlert2 matches our design, supports HTML, and is non-blocking.
       - We also show a RED warning when the category still has products,
         so the user understands the server will block the deletion.
         (The block happens in CategoryDAO.deleteCategory() -> returns -1).
    */
    $(document).on('click', '.btn-delete-cat', function () {
        var id    = $(this).data('id');
        var name  = $(this).data('name');
        var count = parseInt($(this).data('count')) || 0;

        var bodyHtml = count > 0
            ? 'You are about to delete <strong>"' + name + '"</strong>.'
              + '<br><br>'
              + '<div style="background:#fef2f2;border:1px solid #fecaca;border-radius:8px;'
              + 'padding:10px 14px;font-size:12.5px;color:#b91c1c;text-align:left">'
              + '<i class="fas fa-triangle-exclamation" style="margin-right:6px"></i>'
              + '<strong>' + count + ' product(s)</strong> still belong to this category.'
              + ' The server will <strong>block</strong> deletion until they are removed or reassigned.'
              + '</div>'
            : 'You are about to delete <strong>"' + name + '"</strong>.'
              + '<br>This action <strong>cannot be undone</strong>.';

        Swal.fire({
            title:             'Delete Category?',
            html:              bodyHtml,
            icon:              'warning',
            showCancelButton:  true,
            confirmButtonColor:'#dc2626',
            cancelButtonColor: '#64748b',
            confirmButtonText: '<i class="fas fa-trash"></i>&nbsp; Yes, delete',
            cancelButtonText:  'Cancel',
            reverseButtons:    true,
            buttonsStyling:    true,
            customClass: { popup: 'swal2-border-radius' }
        }).then(function (result) {
            if (result.isConfirmed) {
                window.location.href =
                    '<%= request.getContextPath() %>/categories?action=delete&id=' + id;
            }
        });
    });

    /* =============================================================
       6.  Reset modal loading state when modal is hidden
          (in case the user dismisses the modal after a failed submit)
    ============================================================= */
    $('#modalAddCategory').on('hidden.bs.modal', function () {
        $('#btnAddSave').prop('disabled', false)
                        .html('<i class="fas fa-save"></i> Save Category');
    });
    $('#modalEditCategory').on('hidden.bs.modal', function () {
        $('#btnEditSave').prop('disabled', false)
                         .html('<i class="fas fa-save"></i> Update Category');
    });

});
</script>

<style>
/* SweetAlert2 border radius fix */
.swal2-border-radius { border-radius: 14px !important; }
</style>

</body>
</html>
