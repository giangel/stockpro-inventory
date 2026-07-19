<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page
	import="
    com.inventory.model.Sale,
    com.inventory.model.User,
    java.util.List,
    java.math.BigDecimal
"%>
<%
User sessionUser = (User) session.getAttribute("loggedInUser");
String userInitials = "";
if (sessionUser != null && sessionUser.getFullName() != null) {
	for (String p : sessionUser.getFullName().split(" "))
		if (!p.isEmpty())
	userInitials += p.charAt(0);
	if (userInitials.length() > 2)
		userInitials = userInitials.substring(0, 2);
}
userInitials = userInitials.toUpperCase();

List<Sale> sales = (List<Sale>) request.getAttribute("sales");
if (sales == null)
	sales = new java.util.ArrayList<>();

/* KPI totals computed from the list so we don't need an extra query */
BigDecimal totalRevenue = BigDecimal.ZERO;
int completedCount = 0, refundedCount = 0, voidCount = 0;
for (Sale s : sales) {
	if ("COMPLETED".equals(s.getStatus())) {
		totalRevenue = totalRevenue.add(s.getTotalAmount() != null ? s.getTotalAmount() : BigDecimal.ZERO);
		completedCount++;
	} else if ("REFUNDED".equals(s.getStatus()))
		refundedCount++;
	else if ("VOID".equals(s.getStatus()))
		voidCount++;
}
BigDecimal avgOrderValue = completedCount > 0
		? totalRevenue.divide(BigDecimal.valueOf(completedCount), 2, java.math.RoundingMode.HALF_UP)
		: BigDecimal.ZERO;

/* Filter values echoed back so the form retains selections */
String fFrom = request.getParameter("from") != null ? request.getParameter("from") : "";
String fTo = request.getParameter("to") != null ? request.getParameter("to") : "";
String fStatus = request.getParameter("status") != null ? request.getParameter("status") : "";
String fMethod = request.getParameter("method") != null ? request.getParameter("method") : "";

String successParam = request.getParameter("success");
String errorParam = request.getParameter("error");
String errorAttr = (String) request.getAttribute("errorMessage");

String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>StockPro | Sales History</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link
	href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
	rel="stylesheet">
<link rel="stylesheet"
	href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet"
	href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
<link rel="stylesheet"
	href="https://cdn.datatables.net/1.13.4/css/dataTables.bootstrap4.min.css">
<link rel="stylesheet"
	href="https://cdn.datatables.net/responsive/2.4.1/css/responsive.bootstrap4.min.css">
<link rel="stylesheet"
	href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css">
<style>
/* ── reset & base ───────────────────────────────────────────── */
*, *::before, *::after {
	box-sizing: border-box
}

body, .content-wrapper, .main-sidebar, .main-header, .main-footer {
	font-family: 'Inter', -apple-system, sans-serif !important
}

body {
	background: #f1f5f9 !important;
	color: #0f172a !important;
	font-size: 13px !important
}

/* ── sidebar ────────────────────────────────────────────────── */
.main-sidebar {
	background: #0f172a !important;
	box-shadow: none !important;
	width: 230px !important
}

.brand-link {
	background: #0f172a !important;
	border-bottom: 1px solid rgba(255, 255, 255, .06) !important;
	padding: 16px !important;
	display: flex !important;
	align-items: center !important;
	gap: 10px !important;
	text-decoration: none !important
}

.brand-logo-box {
	width: 32px;
	height: 32px;
	background: #2563eb;
	border-radius: 9px;
	display: flex;
	align-items: center;
	justify-content: center;
	flex-shrink: 0
}

.brand-logo-box i {
	color: #fff;
	font-size: 15px
}

.brand-text-wrap .brand-name {
	font-size: 15px;
	font-weight: 700;
	color: #fff;
	display: block
}

.brand-text-wrap .brand-sub {
	font-size: 10px;
	color: #475569;
	display: block;
	margin-top: 1px
}

.user-panel {
	background: transparent !important;
	border-bottom: 1px solid rgba(255, 255, 255, .06) !important;
	padding: 12px 16px !important;
	display: flex;
	align-items: center;
	gap: 10px
}

.sb-avatar {
	width: 32px;
	height: 32px;
	border-radius: 50%;
	background: #1e3a8a;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 12px;
	font-weight: 700;
	color: #bfdbfe;
	flex-shrink: 0
}

.user-panel .info a {
	color: #cbd5e1 !important;
	font-size: 12.5px !important;
	font-weight: 600 !important;
	text-decoration: none !important;
	display: block
}

.user-panel .info small {
	color: #475569;
	font-size: 10.5px
}

.nav-sidebar .nav-header {
	font-size: 9.5px !important;
	font-weight: 700 !important;
	letter-spacing: .08em !important;
	color: #334155 !important;
	text-transform: uppercase !important;
	padding: 14px 16px 4px !important
}

.nav-sidebar .nav-item .nav-link {
	color: #94a3b8 !important;
	border-radius: 8px !important;
	margin: 1px 8px !important;
	padding: 9px 12px !important;
	font-size: 12.5px !important;
	border-left: 2px solid transparent !important;
	display: flex !important;
	align-items: center !important;
	gap: 9px !important;
	transition: all .12s !important
}

.nav-sidebar .nav-item .nav-link:hover {
	background: rgba(255, 255, 255, .05) !important;
	color: #e2e8f0 !important
}

.nav-sidebar .nav-item .nav-link.active {
	background: rgba(37, 99, 235, .18) !important;
	color: #60a5fa !important;
	border-left-color: #2563eb !important
}

.nav-sidebar .nav-link .nav-icon {
	font-size: 14px !important;
	width: 16px !important;
	flex-shrink: 0
}

.nav-sidebar .nav-link p {
	margin: 0 !important;
	font-size: 12.5px !important;
	line-height: 1 !important
}

.nav-alert-badge {
	margin-left: auto;
	background: #dc2626;
	color: #fff;
	font-size: 9px;
	font-weight: 700;
	padding: 2px 7px;
	border-radius: 20px
}

/* ── topbar ─────────────────────────────────────────────────── */
.main-header.navbar {
	background: #fff !important;
	border-bottom: 1px solid #e2e8f0 !important;
	box-shadow: none !important;
	min-height: 54px !important;
	padding: 0 20px !important
}

.topbar-breadcrumb {
	font-size: 12px;
	color: #64748b;
	display: flex;
	align-items: center;
	gap: 5px;
	margin-left: 8px
}

.topbar-breadcrumb a {
	color: #64748b;
	text-decoration: none
}

.topbar-breadcrumb a:hover {
	color: #2563eb
}

.crumb-active {
	color: #0f172a;
	font-weight: 600
}

.live-badge {
	display: flex;
	align-items: center;
	gap: 6px;
	font-size: 11px;
	font-weight: 600;
	color: #059669;
	background: #f0fdf4;
	border: 1px solid #bbf7d0;
	border-radius: 20px;
	padding: 4px 11px
}

.live-dot {
	width: 7px;
	height: 7px;
	border-radius: 50%;
	background: #22c55e
}

.topbar-bell {
	position: relative;
	cursor: pointer;
	color: #64748b;
	font-size: 17px;
	padding: 6px
}

.topbar-bell .bell-dot {
	position: absolute;
	top: 4px;
	right: 4px;
	width: 8px;
	height: 8px;
	border-radius: 50%;
	background: #dc2626;
	border: 1.5px solid #fff
}

.topbar-user-wrap {
	display: flex;
	align-items: center;
	gap: 8px;
	cursor: pointer;
	padding: 4px 8px;
	border-radius: 9px;
	transition: background .12s
}

.topbar-user-wrap:hover {
	background: #f1f5f9
}

.topbar-avatar {
	width: 32px;
	height: 32px;
	border-radius: 50%;
	background: #dbeafe;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 12px;
	font-weight: 700;
	color: #1d4ed8;
	flex-shrink: 0
}

.topbar-user-name {
	font-size: 12.5px;
	font-weight: 600;
	color: #0f172a;
	line-height: 1.2
}

.topbar-user-role {
	font-size: 10.5px;
	color: #94a3b8
}

/* ── content ─────────────────────────────────────────────────── */
.content-wrapper {
	background: #f1f5f9 !important;
	padding: 0 !important
}

.page-content {
	padding: 22px 24px
}

.page-heading {
	display: flex;
	align-items: flex-start;
	justify-content: space-between;
	margin-bottom: 20px;
	flex-wrap: wrap;
	gap: 12px
}

.page-heading h2 {
	font-size: 20px;
	font-weight: 700;
	color: #0f172a;
	margin: 0 0 3px;
	letter-spacing: -.01em
}

.page-heading p {
	font-size: 12px;
	color: #64748b;
	margin: 0
}

/* ── buttons ─────────────────────────────────────────────────── */
.btn-pri {
	background: #2563eb !important;
	color: #fff !important;
	border: none !important;
	border-radius: 8px !important;
	padding: 9px 18px !important;
	font-size: 13px !important;
	font-weight: 600 !important;
	display: inline-flex !important;
	align-items: center !important;
	gap: 6px !important;
	text-decoration: none !important;
	cursor: pointer !important;
	transition: background .12s !important
}

.btn-pri:hover {
	background: #1d4ed8 !important;
	color: #fff !important
}

.btn-green {
	background: #059669 !important;
	color: #fff !important;
	border: none !important;
	border-radius: 8px !important;
	padding: 9px 18px !important;
	font-size: 13px !important;
	font-weight: 600 !important;
	display: inline-flex !important;
	align-items: center !important;
	gap: 6px !important;
	text-decoration: none !important;
	cursor: pointer !important;
	transition: background .12s !important
}

.btn-green:hover {
	background: #047857 !important;
	color: #fff !important
}

.btn-sec {
	background: #fff !important;
	color: #374151 !important;
	border: 1px solid #d1d5db !important;
	border-radius: 8px !important;
	padding: 9px 16px !important;
	font-size: 13px !important;
	font-weight: 500 !important;
	display: inline-flex !important;
	align-items: center !important;
	gap: 6px !important;
	text-decoration: none !important;
	cursor: pointer !important
}

.btn-sec:hover {
	background: #f9fafb !important;
	color: #111827 !important
}

/* ── KPI cards ───────────────────────────────────────────────── */
.kpi-row {
	margin-bottom: 18px
}

.kpi-card {
	background: #fff;
	border: 1px solid #e2e8f0;
	border-radius: 12px;
	padding: 18px;
	position: relative;
	overflow: hidden;
	transition: box-shadow .15s, transform .15s;
	height: 100%
}

.kpi-card:hover {
	box-shadow: 0 8px 20px rgba(0, 0, 0, .06);
	transform: translateY(-1px)
}

.kpi-card::after {
	content: '';
	position: absolute;
	bottom: 0;
	left: 0;
	right: 0;
	height: 3px;
	border-radius: 0 0 12px 12px
}

.kpi-card.blue::after {
	background: #2563eb
}

.kpi-card.green::after {
	background: #22c55e
}

.kpi-card.amber::after {
	background: #f59e0b
}

.kpi-card.purple::after {
	background: #7c3aed
}

.kpi-card.red::after {
	background: #dc2626
}

.kpi-top {
	display: flex;
	align-items: center;
	justify-content: space-between;
	margin-bottom: 10px
}

.kpi-label {
	font-size: 10.5px;
	font-weight: 700;
	color: #64748b;
	text-transform: uppercase;
	letter-spacing: .06em
}

.kpi-icon-box {
	width: 38px;
	height: 38px;
	border-radius: 10px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 17px;
	flex-shrink: 0
}

.kpi-value {
	font-size: 24px;
	font-weight: 700;
	color: #0f172a;
	line-height: 1;
	margin-bottom: 6px;
	letter-spacing: -.02em
}

.kpi-value.sm {
	font-size: 18px
}

.kpi-sub {
	font-size: 11.5px;
	color: #64748b;
	display: flex;
	align-items: center;
	gap: 4px
}

/* ── filter panel ────────────────────────────────────────────── */
.filter-panel {
	background: #fff;
	border: 1px solid #e2e8f0;
	border-radius: 12px;
	padding: 16px 18px;
	margin-bottom: 18px
}

.filter-panel-title {
	font-size: 12px;
	font-weight: 700;
	color: #64748b;
	text-transform: uppercase;
	letter-spacing: .06em;
	margin-bottom: 12px;
	display: flex;
	align-items: center;
	gap: 7px
}

.filter-grid {
	display: grid;
	grid-template-columns: repeat(4, 1fr) auto auto;
	gap: 10px;
	align-items: end
}

.fld-label {
	display: block;
	font-size: 11.5px;
	font-weight: 600;
	color: #374151;
	margin-bottom: 5px
}

.fld-input {
	width: 100%;
	height: 38px;
	border: 1px solid #d1d5db;
	border-radius: 8px;
	font-size: 12.5px;
	font-family: 'Inter', sans-serif;
	color: #0f172a;
	background: #f9fafb;
	padding: 0 10px;
	outline: none;
	transition: border-color .15s, box-shadow .15s
}

.fld-input:focus {
	border-color: #2563eb;
	background: #fff;
	box-shadow: 0 0 0 3px rgba(37, 99, 235, .1)
}

.btn-filter {
	height: 38px;
	background: #2563eb;
	color: #fff;
	border: none;
	border-radius: 8px;
	font-size: 12.5px;
	font-weight: 600;
	font-family: 'Inter', sans-serif;
	padding: 0 16px;
	cursor: pointer;
	display: flex;
	align-items: center;
	gap: 6px;
	white-space: nowrap;
	transition: background .12s
}

.btn-filter:hover {
	background: #1d4ed8
}

.btn-reset {
	height: 38px;
	background: #f1f5f9;
	color: #64748b;
	border: 1px solid #e2e8f0;
	border-radius: 8px;
	font-size: 12.5px;
	font-weight: 600;
	font-family: 'Inter', sans-serif;
	padding: 0 14px;
	cursor: pointer;
	display: flex;
	align-items: center;
	gap: 6px;
	transition: background .12s
}

.btn-reset:hover {
	background: #e2e8f0;
	color: #374151
}

/* ── panel ───────────────────────────────────────────────────── */
.panel {
	background: #fff;
	border: 1px solid #e2e8f0;
	border-radius: 12px;
	overflow: hidden
}

.panel-header {
	display: flex;
	align-items: center;
	justify-content: space-between;
	padding: 14px 18px;
	border-bottom: 1px solid #f1f5f9;
	flex-wrap: wrap;
	gap: 10px
}

.panel-title {
	font-size: 13.5px;
	font-weight: 600;
	color: #0f172a;
	display: flex;
	align-items: center;
	gap: 8px
}

.panel-title i {
	color: #94a3b8;
	font-size: 15px
}

/* ── search bar ──────────────────────────────────────────────── */
.tbl-search {
	display: flex;
	align-items: center;
	border: 1px solid #e2e8f0;
	border-radius: 8px;
	overflow: hidden;
	background: #f9fafb
}

.tbl-search i {
	padding: 0 10px;
	color: #94a3b8;
	font-size: 13px;
	flex-shrink: 0
}

.tbl-search input {
	border: none;
	background: transparent;
	outline: none;
	font-size: 12.5px;
	color: #0f172a;
	padding: 8px 12px 8px 0;
	width: 200px;
	font-family: 'Inter', sans-serif
}

.tbl-search input::placeholder {
	color: #94a3b8
}

.pill-btn {
	background: #f1f5f9;
	color: #64748b;
	border: none;
	border-radius: 20px;
	padding: 5px 13px;
	font-size: 11px;
	font-weight: 600;
	cursor: pointer;
	font-family: 'Inter', sans-serif;
	transition: background .12s
}

.pill-btn:hover {
	background: #e2e8f0;
	color: #374151
}

/* ── sales table ─────────────────────────────────────────────── */
#salesTable {
	width: 100% !important
}

#salesTable thead th {
	background: #f8fafc !important;
	color: #64748b !important;
	font-size: 10.5px !important;
	font-weight: 700 !important;
	text-transform: uppercase !important;
	letter-spacing: .06em !important;
	border-bottom: 1px solid #e2e8f0 !important;
	border-top: none !important;
	padding: 11px 14px !important;
	white-space: nowrap
}

#salesTable tbody td {
	font-size: 12.5px !important;
	color: #1e293b !important;
	padding: 13px 14px !important;
	border-bottom: 1px solid #f8fafc !important;
	vertical-align: middle !important
}

#salesTable tbody tr:hover td {
	background: #fafafa !important
}

#salesTable tbody tr:last-child td {
	border-bottom: none !important
}

/* receipt number */
.receipt-cell {
	display: flex;
	align-items: center;
	gap: 9px
}

.receipt-icon {
	width: 32px;
	height: 32px;
	border-radius: 8px;
	background: #eff6ff;
	display: flex;
	align-items: center;
	justify-content: center;
	color: #2563eb;
	font-size: 13px;
	flex-shrink: 0
}

.receipt-num {
	font-weight: 700;
	color: #0f172a;
	font-size: 12.5px;
	font-family: 'Courier New', monospace
}

.receipt-date {
	font-size: 10.5px;
	color: #94a3b8;
	margin-top: 2px
}

/* customer cell */
.customer-cell .cust-name {
	font-weight: 500;
	color: #0f172a
}

.customer-cell .cust-phone {
	font-size: 11px;
	color: #94a3b8;
	margin-top: 2px
}

/* payment method badge */
.pay-badge {
	display: inline-flex;
	align-items: center;
	gap: 5px;
	font-size: 11px;
	font-weight: 600;
	padding: 4px 10px;
	border-radius: 20px;
	white-space: nowrap
}

.pay-cash {
	background: #f0fdf4;
	color: #15803d
}

.pay-transfer {
	background: #eff6ff;
	color: #1d4ed8
}

.pay-pos {
	background: #faf5ff;
	color: #7c3aed
}

.pay-credit {
	background: #fffbeb;
	color: #b45309
}

/* status badge */
.status-badge {
	display: inline-block;
	font-size: 10.5px;
	font-weight: 700;
	padding: 4px 10px;
	border-radius: 20px
}

.badge-completed {
	background: #f0fdf4;
	color: #15803d
}

.badge-refunded {
	background: #fffbeb;
	color: #b45309
}

.badge-void {
	background: #fef2f2;
	color: #dc2626
}

/* amount cells */
.amount-cell {
	font-weight: 700;
	color: #0f172a;
	font-size: 13px
}

.items-count {
	font-size: 11px;
	color: #64748b;
	background: #f1f5f9;
	padding: 2px 8px;
	border-radius: 20px
}

/* action buttons */
.act-btn {
	width: 30px;
	height: 30px;
	border-radius: 7px;
	border: none;
	cursor: pointer;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 12.5px;
	transition: background .12s;
	margin-left: 2px;
	text-decoration: none
}

.act-view {
	background: #eff6ff;
	color: #2563eb
}

.act-view:hover {
	background: #dbeafe
}

.act-print {
	background: #f0fdf4;
	color: #059669
}

.act-print:hover {
	background: #dcfce7
}

.act-void {
	background: #fef2f2;
	color: #dc2626
}

.act-void:hover {
	background: #fecaca
}

.act-disabled {
	background: #f1f5f9;
	color: #cbd5e1;
	cursor: not-allowed
}

/* DataTables overrides */
.dataTables_wrapper .dataTables_filter {
	display: none
}

.dataTables_wrapper .dataTables_length select {
	border: 1px solid #e2e8f0 !important;
	border-radius: 7px !important;
	font-size: 12px !important;
	font-family: 'Inter', sans-serif !important;
	padding: 4px 8px !important
}

.dataTables_wrapper .dataTables_info, .dataTables_wrapper .dataTables_paginate
	{
	font-size: 11.5px !important;
	color: #94a3b8 !important;
	padding: 10px 16px !important;
	border-top: 1px solid #f1f5f9 !important
}

.dataTables_wrapper .paginate_button {
	border-radius: 7px !important;
	font-size: 12px !important;
	font-family: 'Inter', sans-serif !important;
	padding: 4px 9px !important;
	border: none !important
}

.dataTables_wrapper .paginate_button.current, .dataTables_wrapper .paginate_button.current:hover
	{
	background: #2563eb !important;
	color: #fff !important;
	border: none !important
}

.dataTables_wrapper .paginate_button:hover {
	background: #f1f5f9 !important;
	color: #374151 !important;
	border: none !important
}

/* flash messages */
.flash {
	display: flex;
	align-items: center;
	gap: 10px;
	border-radius: 10px;
	padding: 12px 16px;
	margin-bottom: 16px;
	font-size: 13px;
	font-weight: 500
}

.flash-success {
	background: #f0fdf4;
	border: 1px solid #bbf7d0;
	color: #065f46
}

.flash-error {
	background: #fef2f2;
	border: 1px solid #fecaca;
	color: #991b1b
}

.flash-warn {
	background: #fffbeb;
	border: 1px solid #fcd34d;
	color: #92400e
}

.flash-close {
	margin-left: auto;
	background: none;
	border: none;
	cursor: pointer;
	color: inherit;
	font-size: 16px;
	line-height: 1;
	padding: 0
}

/* empty state */
.empty-state {
	text-align: center;
	padding: 52px 20px;
	color: #94a3b8
}

.empty-state i {
	font-size: 38px;
	display: block;
	margin-bottom: 12px;
	color: #cbd5e1
}

.empty-state h4 {
	font-size: 15px;
	font-weight: 600;
	color: #64748b;
	margin: 0 0 6px
}

.empty-state p {
	font-size: 13px;
	margin: 0 0 16px
}

/* footer */
.main-footer {
	background: #fff !important;
	border-top: 1px solid #e2e8f0 !important;
	padding: 12px 24px !important;
	font-size: 11.5px !important;
	color: #94a3b8 !important;
	text-align: center !important
}

@media ( max-width :992px) {
	.filter-grid {
		grid-template-columns: 1fr 1fr
	}
}

@media ( max-width :600px) {
	.filter-grid {
		grid-template-columns: 1fr
	}
}
</style>
</head>
<body
	class="hold-transition sidebar-mini layout-fixed layout-navbar-fixed">
	<div class="wrapper">

		<%-- ══════════════ TOPBAR ══════════════ --%>
		<nav
			class="main-header navbar navbar-expand navbar-white navbar-light">
			<ul class="navbar-nav align-items-center">
				<li class="nav-item"><a class="nav-link px-2"
					data-widget="pushmenu" href="#" role="button"> <i
						class="fas fa-bars" style="color: #64748b; font-size: 16px"></i>
				</a></li>
				<li class="nav-item d-none d-sm-flex align-items-center">
					<div class="topbar-breadcrumb">
						<i class="fas fa-home" style="font-size: 12px; color: #94a3b8"></i>
						<span style="color: #cbd5e1">/</span> <a
							href="<%=ctx%>/dashboard">Dashboard</a> <span
							style="color: #cbd5e1">/</span> <span class="crumb-active">Sales
							history</span>
					</div>
				</li>
			</ul>
			<ul class="navbar-nav ml-auto align-items-center" style="gap: 12px">
				<li class="nav-item d-none d-md-flex">
					<div class="live-badge">
						<div class="live-dot"></div>
						PostgreSQL
					</div>
				</li>
				<li class="nav-item">
					<div class="topbar-bell" title="Alerts">
						<i class="fas fa-bell"></i><span class="bell-dot"></span>
					</div>
				</li>
				<li class="nav-item dropdown"><a href="#" class="nav-link p-0"
					data-toggle="dropdown">
						<div class="topbar-user-wrap">
							<div class="topbar-avatar"><%=userInitials%></div>
							<div class="d-none d-sm-block">
								<div class="topbar-user-name">
									<%=sessionUser != null ? sessionUser.getFullName() : "User"%>
								</div>
								<div class="topbar-user-role">
									<%=sessionUser != null ? sessionUser.getRole() : ""%>
								</div>
							</div>
							<i class="fas fa-chevron-down ml-1"
								style="font-size: 10px; color: #94a3b8"></i>
						</div>
				</a>
					<div class="dropdown-menu dropdown-menu-right border-0"
						style="box-shadow: 0 8px 24px rgba(0, 0, 0, .12); min-width: 180px; margin-top: 6px; border-radius: 12px">
						<div class="dropdown-header py-2 px-3"
							style="font-size: 11px; color: #94a3b8; font-weight: 700; text-transform: uppercase">
							My Account</div>
						<div class="dropdown-divider m-0"></div>
						<a href="<%=ctx%>/logout" class="dropdown-item py-2"
							style="font-size: 13px; color: #dc2626"> <i
							class="fas fa-sign-out-alt mr-2" style="width: 16px"></i>Sign out
						</a>
					</div></li>
			</ul>
		</nav>

		<%-- ══════════════ SIDEBAR ══════════════ --%>
		<aside class="main-sidebar elevation-0">
			<a href="<%=ctx%>/dashboard" class="brand-link">
				<div class="brand-logo-box">
					<i class="fas fa-cubes"></i>
				</div>
				<div class="brand-text-wrap">
					<span class="brand-name">StockPro</span> <span class="brand-sub">SME
						Inventory Hub</span>
				</div>
			</a>
			<div class="sidebar">
				<div class="user-panel mt-2 mb-2">
					<div class="sb-avatar"><%=userInitials%></div>
					<div class="info">
						<a href="#"><%=sessionUser != null ? sessionUser.getFullName() : "User"%></a>
						<small><%=sessionUser != null ? sessionUser.getRole() : ""%></small>
					</div>
				</div>
				<nav class="mt-1">
					<ul class="nav nav-pills nav-sidebar flex-column"
						data-widget="treeview" role="menu">
						<li class="nav-header">Main</li>
						<li class="nav-item"><a href="<%=ctx%>/dashboard"
							class="nav-link"> <i class="nav-icon fas fa-tachometer-alt"></i>
							<p>Dashboard</p>
						</a></li>
						<li class="nav-header">Catalogue</li>
						<li class="nav-item"><a
							href="<%=ctx%>/products?action=list" class="nav-link"> <i
								class="nav-icon fas fa-box-open"></i>
							<p>Products</p>
						</a></li>
						<li class="nav-item"><a
							href="<%=ctx%>/categories?action=list" class="nav-link"> <i
								class="nav-icon fas fa-tags"></i>
							<p>Categories</p>
						</a></li>
						<li class="nav-item"><a
							href="<%=ctx%>/suppliers?action=list" class="nav-link"> <i
								class="nav-icon fas fa-truck"></i>
							<p>Suppliers</p>
						</a></li>
						<li class="nav-header">Operations</li>
						<li class="nav-item"><a href="<%=ctx%>/sales?action=pos"
							class="nav-link"> <i class="nav-icon fas fa-cash-register"></i>
							<p>Point of sale</p>
						</a></li>
						<li class="nav-item"><a
							href="<%=ctx%>/inventory?action=list" class="nav-link"> <i
								class="nav-icon fas fa-warehouse"></i>
							<p>Inventory</p>
						</a></li>
						

						<li class="nav-item"><a href="<%=ctx%>/reports.jsp"
							class="nav-link"> <i class="nav-icon fas fa-chart-bar"></i>
							<p>Reports</p>
						</a></li>
						<li class="nav-item"><a href="<%=ctx%>/logout"
							class="nav-link"> <i class="nav-icon fas fa-sign-out-alt"></i>
							<p>Sign out</p>
						</a></li>
					</ul>
				</nav>
			</div>
		</aside>

		<%-- ══════════════ MAIN CONTENT ══════════════ --%>
		<div class="content-wrapper">
			<div class="page-content">

				<%-- Page heading --%>
				<div class="page-heading">
					<div>
						<h2>
							<i class="fas fa-file-invoice-dollar"
								style="font-size: 18px; color: #2563eb; margin-right: 8px"></i>
							Sales history
						</h2>
						<p>View, search and manage all transactions - filter by
							date, status or payment method</p>
					</div>
					<div style="display: flex; gap: 8px; flex-wrap: wrap">
						<a href="<%=ctx%>/sales?action=history" class="btn-sec"> <i
							class="fas fa-sync-alt" style="font-size: 12px"></i> Refresh
						</a> <a href="<%=ctx%>/sales?action=pos" class="btn-green"> <i
							class="fas fa-plus"></i> New sale
						</a>
					</div>
				</div>

				<%-- Flash messages --%>
				<%
				if ("voided".equals(successParam)) {
				%>
				<div class="flash flash-success">
					<i class="fas fa-circle-check"></i> Sale voided successfully. Stock
					has been restored to inventory.
					<button class="flash-close" onclick="this.parentElement.remove()">&times;</button>
				</div>
				<%
				} else if ("refunded".equals(successParam)) {
				%>
				<div class="flash flash-success">
					<i class="fas fa-circle-check"></i> Sale refunded successfully.
					Stock has been restored to inventory.
					<button class="flash-close" onclick="this.parentElement.remove()">&times;</button>
				</div>
				<%
				} else if ("terminal".equals(errorParam)) {
				%>
				<div class="flash flash-warn">
					<i class="fas fa-triangle-exclamation"></i> This sale has already
					been voided or refunded and cannot be changed again.
					<button class="flash-close" onclick="this.parentElement.remove()">&times;</button>
				</div>
				<%
				}
				%>
				<%
				if (errorAttr != null && !errorAttr.isEmpty()) {
				%>
				<div class="flash flash-error">
					<i class="fas fa-circle-exclamation"></i>
					<%=errorAttr%>
					<button class="flash-close" onclick="this.parentElement.remove()">&times;</button>
				</div>
				<%
				}
				%>

				<%-- KPI cards --%>
				<div class="row kpi-row">
					<div class="col-xl col-sm-6 mb-3">
						<div class="kpi-card blue">
							<div class="kpi-top">
								<span class="kpi-label">Total revenue</span>
								<div class="kpi-icon-box" style="background: #eff6ff">
									<i class="fas fa-naira-sign" style="color: #2563eb"></i>
								</div>
							</div>
							<div class="kpi-value sm">
								&#x20A6;<%=String.format("%,.2f", totalRevenue)%>
							</div>
							<div class="kpi-sub">
								<i class="fas fa-circle-check"
									style="color: #22c55e; font-size: 10px"></i> Completed sales
								only
							</div>
						</div>
					</div>
					<div class="col-xl col-sm-6 mb-3">
						<div class="kpi-card green">
							<div class="kpi-top">
								<span class="kpi-label">Completed</span>
								<div class="kpi-icon-box" style="background: #f0fdf4">
									<i class="fas fa-circle-check" style="color: #059669"></i>
								</div>
							</div>
							<div class="kpi-value"><%=completedCount%></div>
							<div class="kpi-sub">
								<i class="fas fa-receipt" style="font-size: 10px"></i>
								Successful transactions
							</div>
						</div>
					</div>
					<div class="col-xl col-sm-6 mb-3">
						<div class="kpi-card purple">
							<div class="kpi-top">
								<span class="kpi-label">Avg. order value</span>
								<div class="kpi-icon-box" style="background: #faf5ff">
									<i class="fas fa-chart-line" style="color: #7c3aed"></i>
								</div>
							</div>
							<div class="kpi-value sm">
								&#x20A6;<%=String.format("%,.2f", avgOrderValue)%>
							</div>
							<div class="kpi-sub">
								<i class="fas fa-calculator" style="font-size: 10px"></i> Per
								completed sale
							</div>
						</div>
					</div>
					<div class="col-xl col-sm-6 mb-3">
						<div class="kpi-card amber">
							<div class="kpi-top">
								<span class="kpi-label">Refunded</span>
								<div class="kpi-icon-box" style="background: #fffbeb">
									<i class="fas fa-rotate-left" style="color: #d97706"></i>
								</div>
							</div>
							<div class="kpi-value"><%=refundedCount%></div>
							<div class="kpi-sub">
								<i class="fas fa-box-arrow-up" style="font-size: 10px"></i>
								Stock restored
							</div>
						</div>
					</div>
					<div class="col-xl col-sm-6 mb-3">
						<div class="kpi-card red">
							<div class="kpi-top">
								<span class="kpi-label">Voided</span>
								<div class="kpi-icon-box" style="background: #fef2f2">
									<i class="fas fa-ban" style="color: #dc2626"></i>
								</div>
							</div>
							<div class="kpi-value"><%=voidCount%></div>
							<div class="kpi-sub">
								<i class="fas fa-xmark-circle" style="font-size: 10px"></i>
								Cancelled transactions
							</div>
						</div>
					</div>
				</div>

				<%-- Filter panel --%>
				<div class="filter-panel">
					<div class="filter-panel-title">
						<i class="fas fa-filter"></i> Filter transactions
					</div>
					<form method="GET" action="<%=ctx%>/sales" id="filterForm">
						<input type="hidden" name="action" value="history">
						<div class="filter-grid">
							<div>
								<label class="fld-label" for="fromDate">From date</label> <input
									type="date" id="fromDate" name="from" class="fld-input"
									value="<%=fFrom%>">
							</div>
							<div>
								<label class="fld-label" for="toDate">To date</label> <input
									type="date" id="toDate" name="to" class="fld-input"
									value="<%=fTo%>">
							</div>
							<div>
								<label class="fld-label" for="statusFilter">Status</label> <select
									id="statusFilter" name="status" class="fld-input"
									style="cursor: pointer; appearance: none; background-image: url(\"
									data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg'
									width='12' height='12' viewBox='0 0 24 24' fill='none'
									stroke='%239ca3af' stroke-width='2' %3E%3Cpath d='M6 9l6 6 6-6'
									/%3E%3C/svg%3E\");background-repeat:no-repeat;background-position:right 10pxcenter">
									<option value="">All statuses</option>
									<option value="COMPLETED"
										<%="COMPLETED".equals(fStatus) ? "selected" : ""%>>Completed</option>
									<option value="REFUNDED"
										<%="REFUNDED".equals(fStatus) ? "selected" : ""%>>Refunded</option>
									<option value="VOID"
										<%="VOID".equals(fStatus) ? "selected" : ""%>>Void</option>
								</select>
							</div>
							<div>
								<label class="fld-label" for="methodFilter">Payment
									method</label> <select id="methodFilter" name="method"
									class="fld-input"
									style="cursor: pointer; appearance: none; background-image: url(\"
									data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg'
									width='12' height='12' viewBox='0 0 24 24' fill='none'
									stroke='%239ca3af' stroke-width='2' %3E%3Cpath d='M6 9l6 6 6-6'
									/%3E%3C/svg%3E\");background-repeat:no-repeat;background-position:right 10pxcenter">
									<option value="">All methods</option>
									<option value="CASH"
										<%="CASH".equals(fMethod) ? "selected" : ""%>>Cash</option>
									<option value="TRANSFER"
										<%="TRANSFER".equals(fMethod) ? "selected" : ""%>>Transfer</option>
									<option value="POS"
										<%="POS".equals(fMethod) ? "selected" : ""%>>POS</option>
									<option value="CREDIT"
										<%="CREDIT".equals(fMethod) ? "selected" : ""%>>Credit</option>
								</select>
							</div>
							<button type="submit" class="btn-filter">
								<i class="fas fa-magnifying-glass"></i> Apply
							</button>
							<a href="<%=ctx%>/sales?action=history" class="btn-reset"
								style="text-decoration: none"> <i class="fas fa-xmark"></i>
								Clear
							</a>
						</div>
						<%-- Quick date shortcuts --%>
						<div
							style="display: flex; gap: 6px; margin-top: 10px; flex-wrap: wrap">
							<span
								style="font-size: 11px; color: #94a3b8; align-self: center; margin-right: 2px">Quick:</span>
							<button type="button" class="pill-btn"
								onclick="setQuickDate('today')">Today</button>
							<button type="button" class="pill-btn"
								onclick="setQuickDate('yesterday')">Yesterday</button>
							<button type="button" class="pill-btn"
								onclick="setQuickDate('week')">This week</button>
							<button type="button" class="pill-btn"
								onclick="setQuickDate('month')">This month</button>
							<button type="button" class="pill-btn"
								onclick="setQuickDate('last30')">Last 30 days</button>
						</div>
					</form>
				</div>

				<%-- Sales table --%>
				<div class="panel">
					<div class="panel-header">
						<div class="panel-title">
							<i class="fas fa-table"></i> All transactions <span
								style="font-size: 11px; color: #94a3b8; font-weight: 400; margin-left: 4px">
								(<%=sales.size()%> records)
							</span>
							<%
							if (!fFrom.isEmpty() || !fTo.isEmpty() || !fStatus.isEmpty() || !fMethod.isEmpty()) {
							%>
							<span
								style="font-size: 11px; font-weight: 600; color: #2563eb; background: #eff6ff; padding: 2px 9px; border-radius: 20px; margin-left: 4px">
								Filtered </span>
							<%
							}
							%>
						</div>
						<div
							style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap">
							<div class="tbl-search">
								<i class="fas fa-magnifying-glass"></i> <input type="text"
									id="tableSearch" placeholder="Search receipt, customer...">
							</div>
							<button class="pill-btn" onclick="exportTableCSV()">
								<i class="fas fa-download" style="margin-right: 3px"></i>Export
								CSV
							</button>
						</div>
					</div>

					<div style="overflow-x: auto">
						<table id="salesTable" class="table table-hover">
							<thead>
								<tr>
									<th>Receipt</th>
									<th>Customer</th>
									<th>Items</th>
									<th>Payment</th>
									<th class="text-right">Subtotal</th>
									<th class="text-right">Discount</th>
									<th class="text-right">Total Amount</th>
									<th class="text-right">Paid</th>
									<th class="text-center">Status</th>
									<th class="text-center">Served by</th>
									<th class="text-center">Actions</th>
								</tr>
							</thead>
							<tbody>
								<%
								for (Sale sale : sales) {
									String status = sale.getStatus() != null ? sale.getStatus() : "COMPLETED";
									String badgeClass = "COMPLETED".equals(status)
									? "badge-completed"
									: "REFUNDED".equals(status) ? "badge-refunded" : "badge-void";
									String statusLabel = "COMPLETED".equals(status) ? "Completed" : "REFUNDED".equals(status) ? "Refunded" : "Void";

									String payMethod = sale.getPaymentMethod() != null ? sale.getPaymentMethod() : "CASH";
									String payClass = "CASH".equals(payMethod)
									? "pay-cash"
									: "TRANSFER".equals(payMethod) ? "pay-transfer" : "POS".equals(payMethod) ? "pay-pos" : "pay-credit";
									String payIcon = "CASH".equals(payMethod)
									? "fa-money-bill-wave"
									: "TRANSFER".equals(payMethod)
											? "fa-building-columns"
											: "POS".equals(payMethod) ? "fa-credit-card" : "fa-handshake";

									String custName = sale.getCustomerName() != null ? sale.getCustomerName() : "Walk-in customer";
									String custPhone = sale.getCustomerPhone() != null ? sale.getCustomerPhone() : "";
									String servedBy = sale.getServedBy() != null ? sale.getServedBy() : "-";

									String saleDateTime = "";
									if (sale.getSaleDate() != null) {
										saleDateTime = sale.getSaleDate().format(java.time.format.DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm"));
									}

									boolean isTerminal = "VOID".equals(status) || "REFUNDED".equals(status);

									BigDecimal subtotal = sale.getSubtotal() != null ? sale.getSubtotal() : BigDecimal.ZERO;
									BigDecimal discount = sale.getDiscountAmount() != null ? sale.getDiscountAmount() : BigDecimal.ZERO;
									BigDecimal totalAmount = sale.getTotalAmount() != null ? sale.getTotalAmount() : BigDecimal.ZERO;
									BigDecimal amtPaid = sale.getAmountPaid() != null ? sale.getAmountPaid() : BigDecimal.ZERO;
								%>
								<tr>
									<%-- Receipt --%>
									<td>
										<div class="receipt-cell">
											<div class="receipt-icon">
												<i class="fas fa-receipt"></i>
											</div>
											<div>
												<div class="receipt-num">
													<%=sale.getReceiptNumber()%>
												</div>
												<div class="receipt-date"><%=saleDateTime%></div>
											</div>
										</div>
									</td>

									<%-- Customer --%>
									<td>
										<div class="customer-cell">
											<div class="cust-name"><%=custName%></div>
											<%
											if (!custPhone.isEmpty()) {
											%>
											<div class="cust-phone">
												<i class="fas fa-phone"
													style="font-size: 9px; margin-right: 3px"></i>
												<%=custPhone%>
											</div>
											<%
											}
											%>
										</div>
									</td>

									<%-- Items count --%>
									<td class="text-center"><span class="items-count">
											<i class="fas fa-box"
											style="font-size: 10px; margin-right: 3px"></i> <%=sale.getItemCount()%>
											<%=sale.getItemCount() == 1 ? "item" : "items"%>
									</span></td>

									<%-- Payment method --%>
									<td><span class="pay-badge <%=payClass%>"> <i
											class="fas <%=payIcon%>" style="font-size: 10px"></i> <%=payMethod%>
									</span></td>

									<%-- Subtotal --%>
									<td class="text-right"><span
										style="font-size: 12.5px; color: #64748b"> &#x20A6;<%=String.format("%,.2f", subtotal)%>
									</span></td>

									<%-- Discount --%>
									<td class="text-center">
										<%
										if (discount.compareTo(BigDecimal.ZERO) > 0) {
										%> <span
										style="font-size: 12px; color: #dc2626; font-weight: 600">
											-&#x20A6;<%=String.format("%,.2f", discount)%>
									</span> <%
 } else {
 %> <span style="color: #d1d5db">-</span> <%
 }
 %>
									</td>

									<%-- Grand total --%>
									<td class="text-right"><span class="amount-cell">
											&#x20A6;<%=String.format("%,.2f", totalAmount)%>
									</span></td>

									<%-- Amount paid --%>
									<td class="text-right"><span
										style="font-size: 12.5px; color: #059669; font-weight: 600">
											&#x20A6;<%=String.format("%,.2f", amtPaid)%>
									</span></td>

									<%-- Status --%>
									<td class="text-center"><span
										class="status-badge <%=badgeClass%>"> <%=statusLabel%>
									</span></td>

									<%-- Served by --%>
									<td class="text-center" style="font-size: 12px; color: #64748b">
										<%=servedBy%>
									</td>

									<%-- Actions --%>
									<td class="text-center" style="white-space: nowrap">
										<%-- View receipt --%> <a
										href="<%=ctx%>/sales?action=view&id=<%=sale.getId()%>"
										class="act-btn act-view" title="View receipt"> <i
											class="fas fa-eye"></i>
									</a> <%-- Print receipt --%> <a
										href="<%=ctx%>/sales?action=receipt&id=<%=sale.getId()%>"
										class="act-btn act-print" title="Print receipt"
										target="_blank"> <i class="fas fa-print"></i>
									</a> <%-- Void / Refund (only for COMPLETED) --%> <%
 if (!isTerminal) {
 %>
										<button class="act-btn act-void"
											title="Void or refund this sale"
											onclick="confirmVoid(<%=sale.getId()%>,
                                        '<%=sale.getReceiptNumber()%>',
                                        '<%=String.format("%,.2f", totalAmount)%>')">
											<i class="fas fa-ban"></i>
										</button> <%
 } else {
 %> <span class="act-btn act-disabled"
										title="Sale is <%=statusLabel.toLowerCase()%> - no further action">
											<i class="fas fa-ban"></i>
									</span> <%
 }
 %>
									</td>
								</tr>
								<%
								} // end for
					%>
							</tbody>
						</table>
					</div>
				</div>

			</div>
			<%-- /page-content --%>
		</div>
		<%-- /content-wrapper --%>

		<footer class="main-footer">
			<strong>StockPro Inventory System</strong> - &copy; 2025 Built
			for Nigerian SMEs
		</footer>
	</div>
	<%-- /wrapper --%>

	<%-- ══════════════ JAVASCRIPT ══════════════ --%>
	<script
		src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.4/jquery.min.js"></script>
	<script
		src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/4.6.2/js/bootstrap.bundle.min.js"></script>
	<script
		src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>
	<script
		src="https://cdn.datatables.net/1.13.4/js/jquery.dataTables.min.js"></script>
	<script
		src="https://cdn.datatables.net/1.13.4/js/dataTables.bootstrap4.min.js"></script>
	<script
		src="https://cdn.datatables.net/responsive/2.4.1/js/dataTables.responsive.min.js"></script>
	<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

	<script>
var table;

$(document).ready(function () {

    // ── DataTable init ───────────────────────────────────────
    table = $('#salesTable').DataTable({
        responsive: true,
        pageLength: 15,
        lengthMenu: [[10, 15, 25, 50, 100], [10, 15, 25, 50, 100]],
        language: {
            lengthMenu: 'Show _MENU_',
            info:       'Showing _START_–_END_ of _TOTAL_ transactions',
            infoEmpty:  'No transactions found',
            emptyTable: "No sales have been recorded yet. Use the Point of Sale to process your first sale.",
            paginate:   { previous: '&lsaquo;', next: '&rsaquo;' }
        },
        columnDefs: [
            { orderable: false, targets: [2, 3, 9, 10] },
            { searchable: false, targets: [2, 4, 5, 6, 7, 8, 9, 10] }
        ],
        order: [[0, 'desc']]  // newest first
    });

    // ── Custom search box -> DataTable ────────────────────────
    $('#tableSearch').on('input', function () {
        table.search(this.value).draw();
    });

    // ── Auto-dismiss flash messages ──────────────────────────
    setTimeout(function () {
        $('.flash').fadeOut(400, function () { $(this).remove(); });
    }, 6000);
});

// ── Quick date range shortcuts ────────────────────────────────
function setQuickDate(range) {
    var now   = new Date();
    var from  = new Date();
    var to    = new Date();

    if (range === 'today') {
        // from = today, to = today (already set)
    } else if (range === 'yesterday') {
        from.setDate(now.getDate() - 1);
        to.setDate(now.getDate() - 1);
    } else if (range === 'week') {
        var day = now.getDay(); // 0=Sun
        from.setDate(now.getDate() - (day === 0 ? 6 : day - 1));
    } else if (range === 'month') {
        from = new Date(now.getFullYear(), now.getMonth(), 1);
    } else if (range === 'last30') {
        from.setDate(now.getDate() - 29);
    }

    document.getElementById('fromDate').value = formatDate(from);
    document.getElementById('toDate').value   = formatDate(to);
    document.getElementById('filterForm').submit();
}

function formatDate(d) {
    var y = d.getFullYear();
    var m = String(d.getMonth() + 1).padStart(2, '0');
    var day = String(d.getDate()).padStart(2, '0');
    return y + '-' + m + '-' + day;
}

// ── Void / Refund confirmation ────────────────────────────────
function confirmVoid(saleId, receiptNum, grandTotal) {
    Swal.fire({
        title: 'Void or refund sale?',
        html:
            '<div style="text-align:left">' +
            '<p style="color:#64748b;font-size:13.5px;line-height:1.6;margin-bottom:14px">' +
            'Receipt <strong style="color:#0f172a;font-family:monospace">' +
            receiptNum + '</strong> - ' +
            '&#x20A6;' + grandTotal + '</p>' +
            '<div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">' +

            '<div onclick="submitAction(' + saleId + ',\'void\')" ' +
            'style="border:1.5px solid #fecaca;border-radius:10px;padding:14px;' +
            'cursor:pointer;transition:background .12s" ' +
            'onmouseover="this.style.background=\'#fef2f2\'" ' +
            'onmouseout="this.style.background=\'transparent\'">' +
            '<div style="font-size:16px;color:#dc2626;margin-bottom:6px">' +
            '<i class="fas fa-ban"></i></div>' +
            '<div style="font-weight:700;color:#0f172a;font-size:13px;margin-bottom:3px">Void</div>' +
            '<div style="font-size:11.5px;color:#64748b">Sale entered by mistake. ' +
            'Customer never received goods. Stock is restored.</div>' +
            '</div>' +

            '<div onclick="submitAction(' + saleId + ',\'refund\')" ' +
            'style="border:1.5px solid #fcd34d;border-radius:10px;padding:14px;' +
            'cursor:pointer;transition:background .12s" ' +
            'onmouseover="this.style.background=\'#fffbeb\'" ' +
            'onmouseout="this.style.background=\'transparent\'">' +
            '<div style="font-size:16px;color:#d97706;margin-bottom:6px">' +
            '<i class="fas fa-rotate-left"></i></div>' +
            '<div style="font-weight:700;color:#0f172a;font-size:13px;margin-bottom:3px">Refund</div>' +
            '<div style="font-size:11.5px;color:#64748b">Customer returned goods. ' +
            'Money given back. Stock is restored.</div>' +
            '</div>' +

            '</div></div>',
        showConfirmButton: false,
        showCancelButton:  true,
        cancelButtonText:  'Cancel',
        cancelButtonColor: '#f1f5f9',
        customClass: { popup: 'swal-wide' }
    });
}

function submitAction(saleId, action) {
    Swal.close();
    window.location.href =
        '<%=ctx%>/sales?action=' + action + '&id=' + saleId;
}

// ── Export table to CSV ───────────────────────────────────────
function exportTableCSV() {
    var rows  = [['Receipt','Customer','Items','Payment','Subtotal','Discount','Grand Total','Paid','Status','Served By']];
    var nodes = table.rows({ search: 'applied' }).nodes();

    $(nodes).each(function () {
        var cells = $(this).find('td');
        rows.push([
            $(cells[0]).find('.receipt-num').text().trim(),
            $(cells[1]).find('.cust-name').text().trim(),
            $(cells[2]).text().trim(),
            $(cells[3]).text().trim(),
            $(cells[4]).text().trim(),
            $(cells[5]).text().trim(),
            $(cells[6]).text().trim(),
            $(cells[7]).text().trim(),
            $(cells[8]).text().trim(),
            $(cells[9]).text().trim()
        ]);
    });

    var csv = rows.map(function (r) {
        return r.map(function (c) {
            return '"' + c.replace(/"/g, '""') + '"';
        }).join(',');
    }).join('\n');

    var blob = new Blob([csv], { type: 'text/csv' });
    var url  = URL.createObjectURL(blob);
    var a    = document.createElement('a');
    a.href     = url;
    a.download = 'sales-history-' + new Date().toISOString().slice(0, 10) + '.csv';
    a.click();
    URL.revokeObjectURL(url);
}
</script>
</body>
</html>
