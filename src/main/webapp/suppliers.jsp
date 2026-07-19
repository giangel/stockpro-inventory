<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page
	import="com.inventory.model.Supplier, com.inventory.model.User, java.util.List"%>
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

List<Supplier> suppliers = (List<Supplier>) request.getAttribute("suppliers");
if (suppliers == null)
	suppliers = new java.util.ArrayList<>();

int totalCount = suppliers.size();
int activeCount = 0;
for (Supplier s : suppliers)
	if (s.isActive())
		activeCount++;
int inactiveCount = totalCount - activeCount;

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
<title>StockPro | Suppliers</title>
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
/* ── reset & base ─────────────────────────────────────────── */
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

/* ── sidebar ───────────────────────────────────────────────── */
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

/* ── topbar ────────────────────────────────────────────────── */
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

/* ── content ───────────────────────────────────────────────── */
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

/* ── buttons ───────────────────────────────────────────────── */
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

/* ── summary strip ─────────────────────────────────────────── */
.summary-strip {
	display: flex;
	background: #fff;
	border: 1px solid #e2e8f0;
	border-radius: 12px;
	overflow: hidden;
	margin-bottom: 18px
}

.summary-item {
	flex: 1;
	text-align: center;
	padding: 16px;
	border-right: 1px solid #f1f5f9
}

.summary-item:last-child {
	border-right: none
}

.sum-val {
	font-size: 22px;
	font-weight: 700;
	color: #0f172a;
	letter-spacing: -.01em
}

.sum-lbl {
	font-size: 10.5px;
	color: #94a3b8;
	margin-top: 3px;
	text-transform: uppercase;
	letter-spacing: .05em
}

/* ── flash messages ────────────────────────────────────────── */
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

/* ── panel ─────────────────────────────────────────────────── */
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

/* search bar */
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
	width: 220px;
	font-family: 'Inter', sans-serif
}

.tbl-search input::placeholder {
	color: #94a3b8
}

.filter-select {
	border: 1px solid #e2e8f0;
	border-radius: 8px;
	background: #f9fafb;
	font-size: 12px;
	color: #374151;
	padding: 7px 10px;
	font-family: 'Inter', sans-serif;
	outline: none;
	cursor: pointer
}

/* ── supplier table ────────────────────────────────────────── */
#supplierTable {
	width: 100% !important
}

#supplierTable thead th {
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

#supplierTable tbody td {
	font-size: 12.5px !important;
	color: #1e293b !important;
	padding: 14px !important;
	border-bottom: 1px solid #f8fafc !important;
	vertical-align: middle !important
}

#supplierTable tbody tr:hover td {
	background: #fafafa !important
}

#supplierTable tbody tr:last-child td {
	border-bottom: none !important
}

/* supplier identity cell */
.sup-cell {
	display: flex;
	align-items: center;
	gap: 12px
}

.sup-avatar {
	width: 38px;
	height: 38px;
	border-radius: 10px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 13px;
	font-weight: 700;
	flex-shrink: 0;
	color: #fff
}

.sup-name {
	font-weight: 600;
	color: #0f172a;
	font-size: 13px;
	line-height: 1.25
}

.sup-contact {
	font-size: 11px;
	color: #94a3b8;
	margin-top: 2px;
	display: flex;
	align-items: center;
	gap: 4px
}

/* contact info cells */
.contact-cell {
	display: flex;
	flex-direction: column;
	gap: 4px
}

.contact-line {
	display: flex;
	align-items: center;
	gap: 6px;
	font-size: 12px;
	color: #374151
}

.contact-line i {
	color: #94a3b8;
	font-size: 11px;
	width: 13px;
	flex-shrink: 0
}

.contact-line a {
	color: #2563eb;
	text-decoration: none
}

.contact-line a:hover {
	text-decoration: underline
}

.contact-na {
	color: #d1d5db;
	font-size: 12px;
	font-style: italic
}

/* product count badge */
.prod-count {
	display: inline-flex;
	align-items: center;
	gap: 5px;
	font-size: 11.5px;
	font-weight: 600;
	padding: 4px 10px;
	border-radius: 20px;
	background: #f1f5f9;
	color: #475569
}

.prod-count.has-products {
	background: #eff6ff;
	color: #1d4ed8
}

/* status badge */
.status-badge {
	display: inline-block;
	font-size: 10.5px;
	font-weight: 700;
	padding: 4px 10px;
	border-radius: 20px
}

.badge-active {
	background: #f0fdf4;
	color: #15803d
}

.badge-inactive {
	background: #f1f5f9;
	color: #64748b
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
	font-size: 13px;
	transition: background .12s;
	margin-left: 2px;
	text-decoration: none
}

.act-edit {
	background: #eff6ff;
	color: #2563eb
}

.act-edit:hover {
	background: #dbeafe
}

.act-delete {
	background: #fef2f2;
	color: #dc2626
}

.act-delete:hover {
	background: #fecaca
}

/* dataTables overrides */
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
	margin-bottom: 6px
}

.empty-state p {
	font-size: 13px;
	margin-bottom: 16px
}

/* pill button */
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

/* footer */
.main-footer {
	background: #fff !important;
	border-top: 1px solid #e2e8f0 !important;
	padding: 12px 24px !important;
	font-size: 11.5px !important;
	color: #94a3b8 !important;
	text-align: center !important
}

@media ( max-width :768px) {
	.summary-strip {
		flex-wrap: wrap
	}
	.summary-item {
		min-width: 50%;
		border-bottom: 1px solid #f1f5f9
	}
	.contact-cell {
		display: none
	}
}
</style>
</head>
<body
	class="hold-transition sidebar-mini layout-fixed layout-navbar-fixed">
	<div class="wrapper">

		<%-- ═══════════════════════════════════════════════════════════
     TOPBAR
═══════════════════════════════════════════════════════════ --%>
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
							style="color: #cbd5e1">/</span> <span class="crumb-active">Suppliers</span>
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
						<i class="fas fa-bell"></i> <span class="bell-dot"></span>
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

		<%-- ═══════════════════════════════════════════════════════════
     SIDEBAR
═══════════════════════════════════════════════════════════ --%>
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
							href="<%=ctx%>/suppliers?action=list" class="nav-link active">
								<i class="nav-icon fas fa-truck"></i>
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
						<li class="nav-item"><a
							href="<%=ctx%>/sales?action=history" class="nav-link"> <i
								class="nav-icon fas fa-file-invoice-dollar"></i>
							<p>Sales history</p>
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

		<%-- ═══════════════════════════════════════════════════════════
     MAIN CONTENT
═══════════════════════════════════════════════════════════ --%>
		<div class="content-wrapper">
			<div class="page-content">

				<%-- Page heading --%>
				<div class="page-heading">
					<div>
						<h2>
							<i class="fas fa-truck"
								style="font-size: 18px; color: #2563eb; margin-right: 8px"></i>
							Supplier network
						</h2>
						<p>Manage your product suppliers - add, edit and track supply
							relationships</p>
					</div>
					<div style="display: flex; gap: 8px; flex-wrap: wrap">
						<a href="<%=ctx%>/suppliers?action=list" class="btn-sec"> <i
							class="fas fa-sync-alt" style="font-size: 12px"></i> Refresh
						</a> <a href="<%=ctx%>/suppliers?action=new" class="btn-pri"> <i
							class="fas fa-plus"></i> Add new supplier
						</a>
					</div>
				</div>

				<%-- Flash messages --%>
				<%
				if ("created".equals(successParam)) {
				%>
				<div class="flash flash-success">
					<i class="fas fa-circle-check"></i> Supplier added successfully to
					the network.
					<button class="flash-close" onclick="this.parentElement.remove()">&times;</button>
				</div>
				<%
				} else if ("updated".equals(successParam)) {
				%>
				<div class="flash flash-success">
					<i class="fas fa-circle-check"></i> Supplier details updated
					successfully.
					<button class="flash-close" onclick="this.parentElement.remove()">&times;</button>
				</div>
				<%
				} else if ("deleted".equals(successParam)) {
				%>
				<div class="flash flash-success">
					<i class="fas fa-circle-check"></i> Supplier deactivated and
					removed from active network.
					<button class="flash-close" onclick="this.parentElement.remove()">&times;</button>
				</div>
				<%
				} else if ("hasproducts".equals(errorParam)) {
				%>
				<div class="flash flash-warn">
					<i class="fas fa-triangle-exclamation"></i> <strong>Cannot
						delete supplier</strong> - they still have active products linked to them.
					Reassign or deactivate those products first.
					<button class="flash-close" onclick="this.parentElement.remove()">&times;</button>
				</div>
				<%
				} else if ("notfound".equals(errorParam)) {
				%>
				<div class="flash flash-error">
					<i class="fas fa-circle-exclamation"></i> Supplier not found - it
					may have already been deleted.
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

				<%-- Summary strip --%>
				<div class="summary-strip">
					<div class="summary-item">
						<div class="sum-val"><%=totalCount%></div>
						<div class="sum-lbl">Total suppliers</div>
					</div>
					<div class="summary-item">
						<div class="sum-val" style="color: #059669"><%=activeCount%></div>
						<div class="sum-lbl">Active suppliers</div>
					</div>
					<div class="summary-item">
						<div class="sum-val" style="color: #94a3b8"><%=inactiveCount%></div>
						<div class="sum-lbl">Inactive</div>
					</div>
					<div class="summary-item">
						<%
						int totalProducts = 0;
						for (Supplier s : suppliers)
							totalProducts += s.getProductCount();
						%>
						<div class="sum-val" style="color: #2563eb"><%=totalProducts%></div>
						<div class="sum-lbl">Products supplied</div>
					</div>
				</div>

				<%-- Suppliers table panel --%>
				<div class="panel">
					<div class="panel-header">
						<div class="panel-title">
							<i class="fas fa-table"></i> All suppliers <span
								style="font-size: 11px; color: #94a3b8; font-weight: 400; margin-left: 4px">
								(<%=totalCount%> records)
							</span>
						</div>
						<div
							style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap">
							<div class="tbl-search">
								<i class="fas fa-magnifying-glass"></i> <input type="text"
									id="customSearch" placeholder="Search name, contact, email...">
							</div>
							<select class="filter-select" id="statusFilter">
								<option value="">All status</option>
								<option value="Active">Active</option>
								<option value="Inactive">Inactive</option>
							</select>
							<button class="pill-btn" onclick="resetFilters()">
								<i class="fas fa-filter-circle-xmark" style="margin-right: 3px"></i>
								Reset
							</button>
						</div>
					</div>

					<div style="overflow-x: auto">
						<table id="supplierTable" class="table table-hover">
							<thead>
								<tr>
									<th>Supplier</th>
									<th>Contact details</th>
									<th>Address</th>
									<th class="text-center">Products</th>
									<th class="text-center">Status</th>
									<th class="text-center">Added</th>
									<th class="text-center">Actions</th>
								</tr>
							</thead>
							<tbody>
								<%
								/* Avatar background colours - rotated by index */
								String[] avatarColors = {"#2563eb", "#7c3aed", "#059669", "#d97706", "#dc2626", "#0891b2", "#65a30d", "#9333ea"};

								if (suppliers.isEmpty()) {
								%>
								<tr>
									<td colspan="7">
										<div class="empty-state">
											<i class="fas fa-truck"></i>
											<h4>No suppliers yet</h4>
											<p>Add your first supplier to start tracking where your
												products come from.</p>
											<a href="<%=ctx%>/suppliers?action=new" class="btn-pri"
												style="display: inline-flex"> <i class="fas fa-plus"></i>
												Add first supplier
											</a>
										</div>
									</td>
								</tr>
								<%
								} else {
								int colorIdx = 0;
								for (Supplier sup : suppliers) {
									String avatarBg = avatarColors[colorIdx % avatarColors.length];
									String initials = sup.getContactInitials();
									String statusBadge = sup.isActive()
									? "<span class='status-badge badge-active'>Active</span>"
									: "<span class='status-badge badge-inactive'>Inactive</span>";
									String statusText = sup.isActive() ? "Active" : "Inactive";

									String phone = sup.getPhone() != null ? sup.getPhone() : "";
									String email = sup.getEmail() != null ? sup.getEmail() : "";
									String address = sup.getAddress() != null ? sup.getAddress() : "";
									String contact = sup.getContactName() != null ? sup.getContactName() : "";

									String addedDate = "";
									if (sup.getCreatedAt() != null) {
										addedDate = sup.getCreatedAt().toLocalDate().toString();
									}
									colorIdx++;
								%>
								<tr>
									<%-- Supplier name + initials avatar --%>
									<td>
										<div class="sup-cell">
											<div class="sup-avatar" style="background:<%=avatarBg%>">
												<%=initials%>
											</div>
											<div>
												<div class="sup-name"><%=sup.getName()%></div>
												<%
												if (!contact.isEmpty()) {
												%>
												<div class="sup-contact">
													<i class="fas fa-user" style="font-size: 9px"></i>
													<%=contact%>
												</div>
												<%
												}
												%>
											</div>
										</div>
									</td>

									<%-- Phone + email --%>
									<td>
										<div class="contact-cell">
											<%
											if (!phone.isEmpty()) {
											%>
											<div class="contact-line">
												<i class="fas fa-phone"></i> <span><%=phone%></span>
											</div>
											<%
											}
											%>
											<%
											if (!email.isEmpty()) {
											%>
											<div class="contact-line">
												<i class="fas fa-envelope"></i> <a
													href="mailto:<%=email%>"><%=email%></a>
											</div>
											<%
											}
											%>
											<%
											if (phone.isEmpty() && email.isEmpty()) {
											%>
											<span class="contact-na">No contact info</span>
											<%
											}
											%>
										</div>
									</td>

									<%-- Address --%>
									<td>
										<%
										if (!address.isEmpty()) {
										%>
										<div
											style="font-size: 12px; color: #374151; max-width: 180px; line-height: 1.4">
											<i class="fas fa-location-dot"
												style="color: #94a3b8; margin-right: 4px; font-size: 11px"></i>
											<%=address%>
										</div> <%
 } else {
 %> <span class="contact-na">No address</span> <%
 }
 %>
									</td>

									<%-- Product count --%>
									<td class="text-center"><span
										class="prod-count <%=sup.getProductCount() > 0 ? "has-products" : ""%>">
											<i class="fas fa-box" style="font-size: 10px"></i> <%=sup.getProductCount()%>
											<%=sup.getProductCount() == 1 ? "product" : "products"%>
									</span></td>

									<%-- Status --%>
									<td class="text-center"><%=statusBadge%></td>

									<%-- Date added --%>
									<td class="text-center"
										style="font-size: 11.5px; color: #64748b; white-space: nowrap">
										<%=addedDate%>
									</td>

									<%-- Actions --%>
									<td class="text-center" style="white-space: nowrap"><a
										href="<%=ctx%>/suppliers?action=edit&id=<%=sup.getId()%>"
										class="act-btn act-edit" title="Edit supplier"> <i
											class="fas fa-pen"></i>
									</a>
										<button class="act-btn act-delete"
											title="<%=sup.getProductCount() > 0 ? "Cannot delete - has active products" : "Delete supplier"%>"
											onclick="confirmDelete(
                                        <%=sup.getId()%>,
                                        '<%=sup.getName().replace("'", "\\'")%>',
                                        <%=sup.getProductCount()%>)">
											<i class="fas fa-trash"></i>
										</button></td>
								</tr>
								<%
								} // end for
								} // end else
								%>
							</tbody>
						</table>
					</div>
				</div>
				<%-- /panel --%>

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

	<%-- ═══════════════════════════════════════════════════════════
     JAVASCRIPT
═══════════════════════════════════════════════════════════ --%>
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

    // ── DataTable init ──────────────────────────────────────
    table = $('#supplierTable').DataTable({
        responsive: true,
        pageLength: 10,
        lengthMenu: [[10, 25, 50], [10, 25, 50]],
        language: {
            lengthMenu: 'Show _MENU_',
            info:       'Showing _START_–_END_ of _TOTAL_ suppliers',
            infoEmpty:  'No suppliers found',
            paginate:   { previous: '&lsaquo;', next: '&rsaquo;' }
        },
        columnDefs: [
            { orderable: false, targets: [1, 2, 6] },  // no sort on contact/address/actions
            { searchable: false, targets: [3, 4, 5, 6] }
        ],
        order: [[0, 'asc']]
    });

    // ── Custom search -> DataTable ───────────────────────────
    $('#customSearch').on('input', function () {
        table.search(this.value).draw();
    });

    // ── Status filter ───────────────────────────────────────
    $('#statusFilter').on('change', function () {
        table.column(4).search(this.value).draw();
    });

    // ── Auto-dismiss flash messages after 6 seconds ────────
    setTimeout(function () {
        $('.flash').fadeOut(400, function () { $(this).remove(); });
    }, 6000);
});

// ── Reset all filters ─────────────────────────────────────
function resetFilters() {
    $('#customSearch').val('');
    $('#statusFilter').val('');
    table.search('').columns().search('').draw();
}

// ── Delete confirmation ───────────────────────────────────
function confirmDelete(supplierId, supplierName, productCount) {

    // Block deletion if supplier has active products
    if (productCount > 0) {
        Swal.fire({
            title: 'Cannot delete supplier',
            html:  '<p style="color:#64748b;font-size:14px;line-height:1.6">' +
                   '<strong style="color:#0f172a">' + supplierName + '</strong> ' +
                   'currently supplies <strong style="color:#dc2626">' +
                   productCount + ' active product' +
                   (productCount > 1 ? 's' : '') + '</strong>.<br><br>' +
                   'Reassign or deactivate those products before removing this supplier.' +
                   '</p>',
            icon:  'warning',
            confirmButtonText: 'Go to products',
            confirmButtonColor: '#2563eb',
            showCancelButton: true,
            cancelButtonText: 'Close'
        }).then(function (result) {
            if (result.isConfirmed) {
                window.location.href = '<%=ctx%>/products?action=list';
            }
        });
        return;
    }

    // Safe to delete - show confirmation
    Swal.fire({
        title: 'Deactivate supplier?',
        html:  '<p style="color:#64748b;font-size:14px;line-height:1.6">' +
               '<strong style="color:#0f172a">' + supplierName + '</strong> ' +
               'will be removed from your active supplier network.<br>' +
               '<span style="font-size:12px;color:#94a3b8">' +
               'This is a soft delete - historical data is preserved.</span>' +
               '</p>',
        icon:  'warning',
        showCancelButton:  true,
        confirmButtonText: '<i class="fas fa-trash mr-1"></i> Yes, deactivate',
        cancelButtonText:  'Cancel',
        confirmButtonColor: '#dc2626',
        reverseButtons: true
    }).then(function (result) {
        if (result.isConfirmed) {
            window.location.href =
                '<%=ctx%>/suppliers?action=delete&id=' + supplierId;
        }
    });
}
</script>
</body>
</html>
