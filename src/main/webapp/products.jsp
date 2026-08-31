<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page
	import="com.inventory.model.Product, java.util.List, java.math.BigDecimal"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt"%>
<%
/* Pull session user for navbar */
com.inventory.model.User sessionUser = (com.inventory.model.User) session.getAttribute("loggedInUser");
String userInitials = "";
if (sessionUser != null && sessionUser.getFullName() != null) {
	String[] parts = sessionUser.getFullName().split(" ");
	for (String part : parts)
		if (!part.isEmpty())
	userInitials += part.charAt(0);
	if (userInitials.length() > 2)
		userInitials = userInitials.substring(0, 2);
}
userInitials = userInitials.toUpperCase();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Jare Pharmacy | Products</title>
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
/* ── global ────────────────────────────────────────────────── */
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

.topbar-breadcrumb .crumb-active {
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

/* ── alert banner ──────────────────────────────────────────── */
.alert-banner {
	display: flex;
	align-items: center;
	gap: 12px;
	background: #fffbeb;
	border: 1px solid #fcd34d;
	border-radius: 10px;
	padding: 12px 16px;
	margin-bottom: 16px;
	font-size: 13px;
	color: #92400e
}

.alert-banner i {
	font-size: 16px;
	color: #d97706;
	flex-shrink: 0
}

.alert-banner a {
	color: #2563eb;
	font-weight: 600;
	text-decoration: none;
	margin-left: 4px
}

/* ── success/error flash ───────────────────────────────────── */
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

/* ── main panel ────────────────────────────────────────────── */
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
	color: #94a3b8
}

/* search + filter bar inside panel header */
.table-controls {
	display: flex;
	align-items: center;
	gap: 8px;
	flex-wrap: wrap
}

.tbl-search {
	display: flex;
	align-items: center;
	gap: 0;
	border: 1px solid #e2e8f0;
	border-radius: 8px;
	overflow: hidden;
	background: #f9fafb
}

.tbl-search i {
	padding: 0 10px;
	color: #94a3b8;
	font-size: 13px
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

.filter-select:focus {
	border-color: #93c5fd
}

/* ── data table ────────────────────────────────────────────── */
#productTable {
	width: 100% !important
}

#productTable thead th {
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

#productTable tbody td {
	font-size: 12.5px !important;
	color: #1e293b !important;
	padding: 13px 14px !important;
	border-bottom: 1px solid #f8fafc !important;
	vertical-align: middle !important
}

#productTable tbody tr:hover td {
	background: #fafafa !important
}

#productTable tbody tr:last-child td {
	border-bottom: none !important
}

/* product name cell */
.prod-cell {
	display: flex;
	align-items: center;
	gap: 10px
}

.prod-thumb {
	width: 34px;
	height: 34px;
	background: #eff6ff;
	border-radius: 9px;
	display: flex;
	align-items: center;
	justify-content: center;
	color: #3b82f6;
	font-size: 15px;
	flex-shrink: 0
}

.prod-name {
	font-weight: 600;
	color: #0f172a;
	font-size: 12.5px;
	line-height: 1.25
}

.prod-sub {
	font-size: 10.5px;
	color: #94a3b8;
	margin-top: 1px
}

/* SKU chip */
.sku-chip {
	font-family: 'Courier New', monospace;
	font-size: 11px;
	font-weight: 700;
	color: #2563eb;
	background: #eff6ff;
	padding: 3px 8px;
	border-radius: 6px;
	display: inline-block
}

/* category badge */
.cat-badge {
	display: inline-block;
	font-size: 11px;
	font-weight: 500;
	padding: 3px 9px;
	border-radius: 20px;
	background: #f1f5f9;
	color: #475569;
	border: 1px solid #e2e8f0
}

/* stock count */
.stock-num {
	font-weight: 700;
	font-size: 13px
}

.stock-ok {
	color: #15803d
}

.stock-low {
	color: #b45309
}

.stock-critical {
	color: #dc2626
}

/* status badge */
.status-badge {
	display: inline-block;
	font-size: 10.5px;
	font-weight: 700;
	padding: 4px 10px;
	border-radius: 20px
}

.badge-instock {
	background: #f0fdf4;
	color: #15803d
}

.badge-low {
	background: #fffbeb;
	color: #b45309
}

.badge-critical {
	background: #fef3c7;
	color: #92400e
}

.badge-out {
	background: #fef2f2;
	color: #dc2626
}

/* price cells */
.price-cell {
	font-weight: 600;
	color: #0f172a;
	font-size: 12.5px
}

.margin-cell {
	font-size: 11px;
	color: #059669;
	font-weight: 600
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
	margin-left: 2px
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

.act-view {
	background: #f0fdf4;
	color: #059669
}

.act-view:hover {
	background: #dcfce7
}

/* dataTables overrides */
.dataTables_wrapper .dataTables_filter {
	display: none
} /* we use our own search */
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

/* footer */
.main-footer {
	background: #fff !important;
	border-top: 1px solid #e2e8f0 !important;
	padding: 12px 24px !important;
	font-size: 11.5px !important;
	color: #94a3b8 !important;
	text-align: center !important
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
	font-family: 'Inter', sans-serif
}

.pill-btn:hover {
	background: #e2e8f0;
	color: #374151
}
</style>
</head>
<body
	class="hold-transition sidebar-mini layout-fixed layout-navbar-fixed">
	<div class="wrapper">

		<%-- ════════════════ TOPBAR ════════════════ --%>
		<nav
			class="main-header navbar navbar-expand navbar-white navbar-light">
			<ul class="navbar-nav align-items-center">
				<li class="nav-item"><a class="nav-link px-2"
					data-widget="pushmenu" href="#" role="button"> <i
						class="fas fa-bars" style="color: #64748b; font-size: 16px"></i>
				</a></li>
				<li class="nav-item d-none d-sm-flex align-items-center">
					<div class="topbar-breadcrumb">
						<i class="fas fa-home" style="font-size: 12px"></i> <span
							style="color: #cbd5e1">/</span> <a
							a href="<%=request.getContextPath()%>/dashboard"
							style="color: #64748b; text-decoration: none">Dashboard</a> <span
							style="color: #cbd5e1">/</span> <span class="crumb-active">Products</span>
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
								<div class="topbar-user-name"><%=sessionUser != null ? sessionUser.getFullName() : "User"%></div>
								<div class="topbar-user-role"><%=sessionUser != null ? sessionUser.getRole() : ""%></div>
							</div>
							<i class="fas fa-chevron-down ml-1"
								style="font-size: 10px; color: #94a3b8"></i>
						</div>
				</a>
					<div class="dropdown-menu dropdown-menu-right border-0"
						style="box-shadow: 0 8px 24px rgba(0, 0, 0, .12); min-width: 180px; margin-top: 6px; border-radius: 12px">
						<div class="dropdown-header py-2 px-3"
							style="font-size: 11px; color: #94a3b8; font-weight: 700; text-transform: uppercase">My
							Account</div>
						<div class="dropdown-divider m-0"></div>
						<a href="<%=request.getContextPath()%>/logout"
							class="dropdown-item py-2"
							style="font-size: 13px; color: #dc2626"> <i
							class="fas fa-sign-out-alt mr-2" style="width: 16px"></i>Sign out
						</a>
					</div></li>
			</ul>
		</nav>

		<%-- ════════════════ SIDEBAR ════════════════ --%>
		<aside class="main-sidebar elevation-0">
			<a href="<%=request.getContextPath()%>/dashboard"
			
				class="brand-link" style="text-decoration: none">
				<div class="brand-logo-box">
					<i class="fas fa-cubes"></i>
				</div>
				<div class="brand-text-wrap">
					<span class="brand-name">Jare Pharmacy</span> <span class="brand-sub">SME
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
						<li class="nav-item"><a
							a href="<%=request.getContextPath()%>/dashboard"
							class="nav-link"> <i class="nav-icon fas fa-tachometer-alt"></i>
							<p>Dashboard</p>
						</a></li>
						<li class="nav-header">Catalogue</li>
						<li class="nav-item"><a
							href="<%=request.getContextPath()%>/products?action=list"
							class="nav-link active"> <i class="nav-icon fas fa-box-open"></i>
							<p>Products</p>
						</a></li>
						<li class="nav-item"><a
							href="<%=request.getContextPath()%>/categories?action=list"
							class="nav-link"> <i class="nav-icon fas fa-tags"></i>
							<p>Categories</p>
						</a></li>
						<li class="nav-item"><a
							href="<%=request.getContextPath()%>/suppliers?action=list"
							class="nav-link"> <i class="nav-icon fas fa-truck"></i>
							<p>Suppliers</p>
						</a></li>
						<li class="nav-header">Operations</li>
						<li class="nav-item"><a
							href="<%=request.getContextPath()%>/sales?action=pos"
							class="nav-link"> <i class="nav-icon fas fa-cash-register"></i>
							<p>Point of sale</p>
						</a></li>
						<li class="nav-item"><a
							href="<%=request.getContextPath()%>/inventory?action=list"
							class="nav-link"> <i class="nav-icon fas fa-warehouse"></i>
								<p>
									Inventory <span class="nav-alert-badge">${lowStockCount}</span>
								</p>
						</a></li>
						
						<li class="nav-item"><a
							href="<%=request.getContextPath()%>/reports.jsp"
							class="nav-link"> <i class="nav-icon fas fa-chart-bar"></i>
							<p>Reports</p>
						</a></li>
						<li class="nav-item" style="margin-top: auto"><a
							href="<%=request.getContextPath()%>/logout" class="nav-link">
								<i class="nav-icon fas fa-sign-out-alt"></i>
							<p>Sign out</p>
						</a></li>
					</ul>
				</nav>
			</div>
		</aside>

		<%-- ════════════════ MAIN CONTENT ════════════════ --%>
		<div class="content-wrapper">
			<div class="page-content">

				<%-- Page heading --%>
				<div class="page-heading">
					<div>
						<h2>
							<i class="fas fa-box-open"
								style="font-size: 18px; color: #2563eb; margin-right: 8px"></i>Product
							catalogue
						</h2>
						<p>Manage all products - add, edit, update stock levels and
							pricing</p>
					</div>
					<div style="display: flex; gap: 8px; flex-wrap: wrap">
						<a href="<%=request.getContextPath()%>/products?action=list"
							class="btn-sec"> <i class="fas fa-sync-alt"
							style="font-size: 12px"></i> Refresh
						</a> <a href="<%=request.getContextPath()%>/products?action=new"
							class="btn-pri"> <i class="fas fa-plus"></i> Add new product
						</a>
					</div>
				</div>

				<%-- Flash messages from servlet redirects --%>
				<%
				String success = request.getParameter("success");
				String err = request.getParameter("error");
				String errAttr = (String) request.getAttribute("errorMessage");
				%>
				<%
				if ("created".equals(success)) {
				%>
				<div class="flash flash-success">
					<i class="fas fa-circle-check"></i> Product created successfully
					and added to inventory.
					<button onclick="this.parentElement.remove()"
						style="margin-left: auto; background: none; border: none; cursor: pointer; color: inherit; font-size: 16px">&times;</button>
				</div>
				<%
				} else if ("updated".equals(success)) {
				%>
				<div class="flash flash-success">
					<i class="fas fa-circle-check"></i> Product updated successfully.
					<button onclick="this.parentElement.remove()"
						style="margin-left: auto; background: none; border: none; cursor: pointer; color: inherit; font-size: 16px">&times;</button>
				</div>
				<%
				} else if ("deleted".equals(success)) {
				%>
				<div class="flash flash-success">
					<i class="fas fa-circle-check"></i> Product removed from active
					catalogue.
					<button onclick="this.parentElement.remove()"
						style="margin-left: auto; background: none; border: none; cursor: pointer; color: inherit; font-size: 16px">&times;</button>
				</div>
				<%
				}
				%>
				<%
				if (errAttr != null && !errAttr.isEmpty()) {
				%>
				<div class="flash flash-error">
					<i class="fas fa-circle-exclamation"></i>
					<%=errAttr%>
					<button onclick="this.parentElement.remove()"
						style="margin-left: auto; background: none; border: none; cursor: pointer; color: inherit; font-size: 16px">&times;</button>
				</div>
				<%
				}
				%>

				<%-- Summary strip --%>
				<%
				List<Product> products = (List<Product>) request.getAttribute("products");
				if (products == null)
					products = new java.util.ArrayList<>();
				int totalCount = products.size();
				long lowCount = products.stream().filter(p -> p.getCurrentStock() <= p.getReorderLevel() && p.getCurrentStock() > 0)
						.count();
				long outCount = products.stream().filter(p -> p.getCurrentStock() == 0).count();
				BigDecimal invVal = (BigDecimal) request.getAttribute("inventoryValue");
				if (invVal == null)
					invVal = BigDecimal.ZERO;
				%>
				<div class="summary-strip">
					<div class="summary-item">
						<div class="sum-val"><%=totalCount%></div>
						<div class="sum-lbl">Total products</div>
					</div>
					<div class="summary-item">
						<div class="sum-val" style="font-size: 18px; color: #059669">
							&#x20A6;<%=String.format("%,.0f", invVal)%>
						</div>
						<div class="sum-lbl">Inventory value</div>
					</div>
					<div class="summary-item">
						<div class="sum-val" style="color: #d97706"><%=lowCount%></div>
						<div class="sum-lbl">Low stock items</div>
					</div>
					<div class="summary-item">
						<div class="sum-val" style="color: #dc2626"><%=outCount%></div>
						<div class="sum-lbl">Out of stock</div>
					</div>
				</div>

				<%-- Low stock warning banner --%>
				<%
				if (lowCount > 0 || outCount > 0) {
				%>
				<div class="alert-banner">
					<i class="fas fa-triangle-exclamation"></i> <span> <strong><%=lowCount + outCount%>
						product(s)</strong> need attention 	 <%=outCount%> out of stock, <%=lowCount%>
						below reorder level. <a
						href="<%=request.getContextPath()%>/inventory?action=list">Go
							to inventory &rarr;</a>
					</span>
				</div>
				<%
				}
				%>

				<%-- Products table panel --%>
				<div class="panel">
					<div class="panel-header">
						<div class="panel-title">
							<i class="fas fa-table"></i> All products <span
								style="font-size: 11px; color: #94a3b8; font-weight: 400; margin-left: 4px">(<%=totalCount%>
								records)
							</span>
						</div>
						<div class="table-controls">
							<%-- Custom search box --%>
							<div class="tbl-search">
								<i class="fas fa-magnifying-glass"></i> <input type="text"
									id="customSearch" placeholder="Search name, SKU, category...">
							</div>
							<%-- Filter by status --%>
							<select class="filter-select" id="statusFilter">
								<option value="">All status</option>
								<option value="In stock">In stock</option>
								<option value="Low stock">Low stock</option>
								<option value="Critical">Critical</option>
								<option value="Out of stock">Out of stock</option>
							</select>
							<button class="pill-btn" onclick="resetFilters()">
								<i class="fas fa-filter-circle-xmark" style="margin-right: 3px"></i>Reset
							</button>
						</div>
					</div>

					<div style="overflow-x: auto">
						<table id="productTable" class="table table-hover">
							<thead>
								<tr>
									<th>Product</th>
									<th>SKU</th>
									<th>Category</th>
									<th class="text-right">Cost price</th>
									<th class="text-right">Selling price</th>
									<th class="text-center">Stock</th>
									<th class="text-center">Status</th>
									<th class="text-center">Actions</th>
								</tr>
							</thead>
							<tbody>
								<%
								if (products.isEmpty()) {
								%>
								<tr>
									<td colspan="8" class="text-center"
										style="padding: 40px; color: #94a3b8"><i
										class="fas fa-box-open"
										style="font-size: 32px; display: block; margin-bottom: 10px; color: #cbd5e1"></i>
										No products found. <a
										href="<%=request.getContextPath()%>/products?action=new"
										style="color: #2563eb; font-weight: 600">Add your first
											product</a>.</td>
								</tr>
								<%
								} else {
								for (Product p : products) {
									String stockStatus = p.getStockStatus();
									String stockClass, badgeClass, badgeText;

									if ("out".equals(stockStatus)) {
										stockClass = "stock-critical";
										badgeClass = "badge-out";
										badgeText = "Out of stock";
									} else if ("critical".equals(stockStatus)) {
										stockClass = "stock-critical";
										badgeClass = "badge-critical";
										badgeText = "Critical";
									} else if ("low".equals(stockStatus)) {
										stockClass = "stock-low";
										badgeClass = "badge-low";
										badgeText = "Low stock";
									} else {
										stockClass = "stock-ok";
										badgeClass = "badge-instock";
										badgeText = "In stock";
									}
								%>
								<tr>
									<td>
										<div class="prod-cell">
											<div class="prod-thumb">
												<i class="fas fa-box"></i>
											</div>
											<div>
												<div class="prod-name"><%=p.getName()%></div>
												<div class="prod-sub"><%=p.getSupplierName() != null ? p.getSupplierName() : "No supplier"%></div>
											</div>
										</div>
									</td>
									<td><span class="sku-chip"><%=p.getSku()%></span></td>
									<td><span class="cat-badge"><%=p.getCategoryName()%></span></td>
									<td class="text-right price-cell">&#x20A6;<%=String.format("%,.2f", p.getCostPrice())%>
									</td>
									<td class="text-right price-cell">&#x20A6;<%=String.format("%,.2f", p.getSellingPrice())%>
										<div class="margin-cell">
											+&#x20A6;<%=String.format("%,.2f", p.getMargin())%></div>
									</td>
									<td class="text-center"><span
										class="stock-num <%=stockClass%>"> <%=p.getCurrentStock()%>
											<%=p.getUnit()%>
									</span>
										<div style="font-size: 10px; color: #94a3b8; margin-top: 1px">
											min:
											<%=p.getReorderLevel()%></div></td>
									<td class="text-center"><span
										class="status-badge <%=badgeClass%>"><%=badgeText%></span>
									</td>
									<td class="text-center" style="white-space: nowrap"><a
										href="<%=request.getContextPath()%>/products?action=edit&id=<%=p.getId()%>"
										class="act-btn act-edit" title="Edit product"> <i
											class="fas fa-pen"></i>
									</a>
										<button class="act-btn act-delete" title="Delete product"
											onclick="confirmDelete(<%=p.getId()%>, '<%=p.getName().replace("'", "\\'")%>')">
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
			<strong>Jare Pharmacy Inventory System</strong> - &copy; 2025 Built
			for Nigerian SMEs
		</footer>
	</div>
	<%-- /wrapper --%>

	<%-- ════════════════ JAVASCRIPT ════════════════ --%>
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
    table = $('#productTable').DataTable({
        responsive: true,
        pageLength: 10,
        lengthMenu: [[10, 25, 50, 100], [10, 25, 50, 100]],
        language: {
            lengthMenu: 'Show _MENU_',
            info:       'Showing _START_–_END_ of _TOTAL_ products',
            infoEmpty:  'No products found',
            paginate:   { previous: '&lsaquo;', next: '&rsaquo;' }
        },
        columnDefs: [
            { orderable: false, targets: [7] },    // no sort on Actions
            { searchable: false, targets: [3,4,5,6,7] } // only search name/sku/category
        ],
        order: [[0, 'asc']] // default sort by name
    });

    // ── Custom search box -> DataTable search ───────────────
    $('#customSearch').on('input', function () {
        table.search(this.value).draw();
    });

    // ── Status filter dropdown ──────────────────────────────
    $('#statusFilter').on('change', function () {
        table.column(6).search(this.value).draw();
    });

    // ── Auto-dismiss flash messages after 5 seconds ────────
    setTimeout(function () {
        $('.flash').fadeOut(400, function() { $(this).remove(); });
    }, 5000);
});

// ── Reset all filters ─────────────────────────────────────
function resetFilters() {
    $('#customSearch').val('');
    $('#statusFilter').val('');
    table.search('').columns().search('').draw();
}

// ── Delete confirmation via SweetAlert2 ──────────────────
function confirmDelete(productId, productName) {
    Swal.fire({
        title: 'Delete product?',
        html:  '<p style="color:#64748b;font-size:14px;line-height:1.6">' +
               'You are about to remove <strong style="color:#0f172a">' + productName + '</strong> ' +
               'from the active catalogue.<br>' +
               '<span style="font-size:12px;color:#94a3b8">Past transactions and sales will be preserved.</span>' +
               '</p>',
        icon:  'warning',
        showCancelButton:  true,
        confirmButtonText: '<i class="fas fa-trash mr-1"></i> Yes, delete it',
        cancelButtonText:  'Cancel',
        confirmButtonColor: '#dc2626',
        cancelButtonColor:  '#f1f5f9',
        reverseButtons: true,
        customClass: { cancelButton: 'text-dark' }
    }).then(function (result) {
        if (result.isConfirmed) {
            window.location.href = '<%=request.getContextPath()%>/products?action=delete&id=' + productId;
        }
    });
}
</script>
</body>
</html>
