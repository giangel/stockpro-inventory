<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
    com.inventory.model.Product,
    com.inventory.model.SaleItem,
    com.inventory.model.User,
    java.util.List,
    java.math.BigDecimal
"%>
<%--
==========================================================================
  sales.jsp - StockPro Point of Sale (POS) screen
==========================================================================
  Forwarded to by SaleServlet.showPOS() with these request attributes:
    products   List<Product>   all active products (for the grid)
    cart       List<SaleItem>  current session cart
    cartTotal  BigDecimal      running total of cart
    cartError  String          optional error (e.g. insufficient stock)
    errorMessage String        optional checkout validation error

  Actions this page POSTs to (all handled by SaleServlet):
    action=addToCart      -> productId, quantity
    action=removeFromCart -> productId
    action=updateCart     -> productId, quantity
    action=clearCart       (no params)
    action=checkout        -> customerName, customerPhone, paymentMethod,
                              discountAmount, taxAmount, amountPaid, notes
==========================================================================
--%>
<%
    User sessionUser = (User) session.getAttribute("loggedInUser");
    String userInitials = "";
    if (sessionUser != null && sessionUser.getFullName() != null) {
        for (String p : sessionUser.getFullName().split(" "))
            if (!p.isEmpty()) userInitials += p.charAt(0);
        if (userInitials.length() > 2) userInitials = userInitials.substring(0, 2);
    }
    userInitials = userInitials.toUpperCase();

    String ctx = request.getContextPath();

    @SuppressWarnings("unchecked")
    List<Product> products = (List<Product>) request.getAttribute("products");
    if (products == null) products = new java.util.ArrayList<>();

    @SuppressWarnings("unchecked")
    List<SaleItem> cart = (List<SaleItem>) request.getAttribute("cart");
    if (cart == null) cart = new java.util.ArrayList<>();

    BigDecimal cartTotal = (BigDecimal) request.getAttribute("cartTotal");
    if (cartTotal == null) cartTotal = BigDecimal.ZERO;

    String cartError    = request.getParameter("cartError");
    String errorMessage = (String) request.getAttribute("errorMessage");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>StockPro | Point of Sale</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css">
<style>
*,*::before,*::after{box-sizing:border-box}
body,.content-wrapper,.main-sidebar,.main-header,.main-footer{font-family:'Inter',-apple-system,sans-serif!important}
body{background:#f1f5f9!important;color:#0f172a!important;font-size:13px!important}

/* sidebar / topbar reused from rest of app */
.main-sidebar{background:#0f172a!important;box-shadow:none!important;width:230px!important}
.brand-link{background:#0f172a!important;border-bottom:1px solid rgba(255,255,255,.06)!important;padding:16px!important;display:flex!important;align-items:center!important;gap:10px!important;text-decoration:none!important}
.brand-logo-box{width:32px;height:32px;background:#2563eb;border-radius:9px;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.brand-logo-box i{color:#fff;font-size:15px}
.brand-text-wrap .brand-name{font-size:15px;font-weight:700;color:#fff;display:block}
.brand-text-wrap .brand-sub{font-size:10px;color:#475569;display:block;margin-top:1px}
.user-panel{background:transparent!important;border-bottom:1px solid rgba(255,255,255,.06)!important;padding:12px 16px!important;display:flex;align-items:center;gap:10px}
.sb-avatar{width:32px;height:32px;border-radius:50%;background:#1e3a8a;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;color:#bfdbfe;flex-shrink:0}
.user-panel .info a{color:#cbd5e1!important;font-size:12.5px!important;font-weight:600!important;text-decoration:none!important;display:block}
.user-panel .info small{color:#475569;font-size:10.5px}
.nav-sidebar .nav-header{font-size:9.5px!important;font-weight:700!important;letter-spacing:.08em!important;color:#334155!important;text-transform:uppercase!important;padding:14px 16px 4px!important}
.nav-sidebar .nav-item .nav-link{color:#94a3b8!important;border-radius:8px!important;margin:1px 8px!important;padding:9px 12px!important;font-size:12.5px!important;border-left:2px solid transparent!important;display:flex!important;align-items:center!important;gap:9px!important;transition:all .12s!important}
.nav-sidebar .nav-item .nav-link:hover{background:rgba(255,255,255,.05)!important;color:#e2e8f0!important}
.nav-sidebar .nav-item .nav-link.active{background:rgba(37,99,235,.18)!important;color:#60a5fa!important;border-left-color:#2563eb!important}
.nav-sidebar .nav-link .nav-icon{font-size:14px!important;width:16px!important;flex-shrink:0}
.nav-sidebar .nav-link p{margin:0!important;font-size:12.5px!important;line-height:1!important}

.main-header.navbar{background:#fff!important;border-bottom:1px solid #e2e8f0!important;box-shadow:none!important;min-height:54px!important;padding:0 20px!important}
.topbar-breadcrumb{font-size:12px;color:#64748b;display:flex;align-items:center;gap:5px;margin-left:8px}
.topbar-breadcrumb a{color:#64748b;text-decoration:none}
.topbar-breadcrumb a:hover{color:#2563eb}
.crumb-active{color:#0f172a;font-weight:600}
.topbar-user-wrap{display:flex;align-items:center;gap:8px;cursor:pointer;padding:4px 8px;border-radius:9px}
.topbar-avatar{width:32px;height:32px;border-radius:50%;background:#dbeafe;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;color:#1d4ed8;flex-shrink:0}
.topbar-user-name{font-size:12.5px;font-weight:600;color:#0f172a;line-height:1.2}
.topbar-user-role{font-size:10.5px;color:#94a3b8}

.content-wrapper{background:#f1f5f9!important;padding:0!important}
.page-content{padding:22px 24px}
.page-heading{display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:18px;flex-wrap:wrap;gap:12px}
.page-heading h2{font-size:20px;font-weight:700;color:#0f172a;margin:0 0 3px;letter-spacing:-.01em}
.page-heading p{font-size:12px;color:#64748b;margin:0}

.btn-sec{background:#fff!important;color:#374151!important;border:1px solid #d1d5db!important;border-radius:8px!important;padding:9px 16px!important;font-size:13px!important;font-weight:500!important;display:inline-flex!important;align-items:center!important;gap:6px!important;text-decoration:none!important;cursor:pointer!important}
.btn-sec:hover{background:#f9fafb!important;color:#111827!important}

/* flash / errors */
.flash{display:flex;align-items:center;gap:10px;border-radius:10px;padding:12px 16px;margin-bottom:16px;font-size:13px;font-weight:500}
.flash-error{background:#fef2f2;border:1px solid #fecaca;color:#991b1b}
.flash-close{margin-left:auto;background:none;border:none;cursor:pointer;color:inherit;font-size:16px;line-height:1;padding:0}

/* POS layout: product grid (left) + cart panel (right) */
.pos-layout{display:grid;grid-template-columns:1fr 380px;gap:18px;align-items:start}

.pos-search{margin-bottom:14px}
.pos-search input{width:100%;height:42px;border:1px solid #d1d5db;border-radius:10px;padding:0 16px 0 40px;font-size:13.5px;font-family:'Inter',sans-serif;outline:none;background:#fff url('data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%2216%22 height=%2216%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%2394a3b8%22 stroke-width=%222%22%3E%3Ccircle cx=%2211%22 cy=%2211%22 r=%228%22/%3E%3Cline x1=%2221%22 y1=%2221%22 x2=%2216.65%22 y2=%2216.65%22/%3E%3C/svg%3E') no-repeat 14px center;transition:border-color .15s,box-shadow .15s}
.pos-search input:focus{border-color:#2563eb;box-shadow:0 0 0 3px rgba(37,99,235,.12)}

.product-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px}
.product-card{background:#fff;border:1px solid #e2e8f0;border-radius:12px;padding:14px;cursor:pointer;transition:box-shadow .15s,border-color .15s,transform .1s;display:flex;flex-direction:column;gap:8px}
.product-card:hover{box-shadow:0 6px 16px rgba(0,0,0,.08);border-color:#93c5fd;transform:translateY(-1px)}
.product-card.out-of-stock{opacity:.5;cursor:not-allowed}
.product-card.out-of-stock:hover{box-shadow:none;border-color:#e2e8f0;transform:none}
.pc-icon{width:38px;height:38px;border-radius:10px;background:#eff6ff;color:#2563eb;display:flex;align-items:center;justify-content:center;font-size:16px}
.pc-name{font-size:12.5px;font-weight:600;color:#0f172a;line-height:1.3;min-height:32px}
.pc-sku{font-family:monospace;font-size:10px;color:#94a3b8}
.pc-price{font-size:14px;font-weight:700;color:#059669}
.pc-stock{font-size:10.5px;color:#94a3b8}
.pc-stock.low{color:#d97706;font-weight:600}
.pc-stock.out{color:#dc2626;font-weight:600}

.empty-products{text-align:center;padding:60px 20px;color:#94a3b8}
.empty-products i{font-size:36px;display:block;margin-bottom:10px;color:#cbd5e1}

/* cart panel */
.cart-panel{background:#fff;border:1px solid #e2e8f0;border-radius:12px;overflow:hidden;position:sticky;top:20px}
.cart-header{padding:14px 18px;border-bottom:1px solid #f1f5f9;display:flex;align-items:center;justify-content:space-between}
.cart-header h3{font-size:13.5px;font-weight:700;color:#0f172a;margin:0;display:flex;align-items:center;gap:8px}
.cart-header h3 i{color:#2563eb}
.cart-clear{background:none;border:none;color:#dc2626;font-size:11.5px;font-weight:600;cursor:pointer;padding:0}
.cart-clear:hover{text-decoration:underline}

.cart-items{max-height:280px;overflow-y:auto}
.cart-item{display:flex;align-items:center;gap:10px;padding:11px 18px;border-bottom:1px solid #f8fafc}
.cart-item:last-child{border-bottom:none}
.ci-info{flex:1;min-width:0}
.ci-name{font-size:12.5px;font-weight:600;color:#0f172a;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.ci-price{font-size:11px;color:#94a3b8}
.ci-qty-wrap{display:flex;align-items:center;gap:4px;flex-shrink:0}
.ci-qty-btn{width:22px;height:22px;border-radius:6px;border:1px solid #e2e8f0;background:#f8fafc;color:#374151;cursor:pointer;font-size:12px;display:flex;align-items:center;justify-content:center;padding:0}
.ci-qty-btn:hover{background:#f1f5f9}
.ci-qty-val{font-size:12.5px;font-weight:600;width:22px;text-align:center}
.ci-remove{background:none;border:none;color:#dc2626;cursor:pointer;font-size:12px;padding:0 0 0 6px;flex-shrink:0}
.ci-total{font-size:12.5px;font-weight:700;color:#0f172a;width:64px;text-align:right;flex-shrink:0}

.cart-empty{text-align:center;padding:40px 18px;color:#94a3b8;font-size:12px}
.cart-empty i{font-size:28px;display:block;margin-bottom:8px;color:#e2e8f0}

.cart-total-row{display:flex;justify-content:space-between;align-items:center;padding:14px 18px;background:#f8fafc;border-top:1px solid #f1f5f9;border-bottom:1px solid #f1f5f9}
.cart-total-label{font-size:12.5px;color:#64748b;font-weight:600}
.cart-total-val{font-size:18px;font-weight:700;color:#0f172a}

/* checkout form */
.checkout-form{padding:16px 18px}
.field-group{margin-bottom:12px}
.field-label{display:block;font-size:11.5px;font-weight:600;color:#374151;margin-bottom:5px}
.field-input,.field-select,.field-textarea{width:100%;border:1px solid #d1d5db;border-radius:8px;padding:8px 11px;font-size:12.5px;color:#0f172a;font-family:inherit;background:#fff;outline:none;transition:border-color .15s,box-shadow .15s}
.field-input:focus,.field-select:focus,.field-textarea:focus{border-color:#2563eb;box-shadow:0 0 0 3px rgba(37,99,235,.12)}
.field-row{display:flex;gap:8px}
.field-row .field-group{flex:1}
.field-select{appearance:none;background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='2.5'%3E%3Cpath d='M6 9l6 6 6-6'/%3E%3C/svg%3E");background-repeat:no-repeat;background-position:right 10px center;padding-right:30px;cursor:pointer}

.change-display{background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;padding:9px 12px;font-size:12.5px;color:#15803d;font-weight:600;margin-bottom:12px;display:none}
.change-display.short{background:#fef2f2;border-color:#fecaca;color:#991b1b}

.btn-checkout{width:100%;height:46px;background:#2563eb;color:#fff;border:none;border-radius:9px;font-size:13.5px;font-weight:700;font-family:'Inter',sans-serif;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:8px;transition:background .12s}
.btn-checkout:hover{background:#1d4ed8}
.btn-checkout:disabled{background:#93c5fd;cursor:not-allowed}

.main-footer{background:#fff!important;border-top:1px solid #e2e8f0!important;padding:12px 24px!important;font-size:11.5px!important;color:#94a3b8!important;text-align:center!important}

@media(max-width:992px){
  .pos-layout{grid-template-columns:1fr}
  .cart-panel{position:static}
}
</style>
</head>
<body class="hold-transition sidebar-mini layout-fixed layout-navbar-fixed">
<div class="wrapper">

<%-- TOPBAR --%>
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
                <span class="crumb-active">Point of sale</span>
            </div>
        </li>
    </ul>
    <ul class="navbar-nav ml-auto align-items-center" style="gap:12px">
        <li class="nav-item dropdown">
            <a href="#" class="nav-link p-0" data-toggle="dropdown">
                <div class="topbar-user-wrap">
                    <div class="topbar-avatar"><%= userInitials %></div>
                    <div class="d-none d-sm-block">
                        <div class="topbar-user-name"><%= sessionUser != null ? sessionUser.getFullName() : "User" %></div>
                        <div class="topbar-user-role"><%= sessionUser != null ? sessionUser.getRole() : "" %></div>
                    </div>
                </div>
            </a>
            <div class="dropdown-menu dropdown-menu-right border-0" style="box-shadow:0 8px 24px rgba(0,0,0,.12);min-width:180px;margin-top:6px;border-radius:12px">
                <a href="<%= ctx %>/logout" class="dropdown-item py-2" style="font-size:13px;color:#dc2626">
                    <i class="fas fa-sign-out-alt mr-2"></i>Sign out
                </a>
            </div>
        </li>
    </ul>
</nav>

<%-- SIDEBAR --%>
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
            <div class="sb-avatar"><%= userInitials %></div>
            <div class="info">
                <a href="#"><%= sessionUser != null ? sessionUser.getFullName() : "User" %></a>
                <small><%= sessionUser != null ? sessionUser.getRole() : "" %></small>
            </div>
        </div>
        <nav class="mt-1">
            <ul class="nav nav-pills nav-sidebar flex-column" data-widget="treeview" role="menu">
                <li class="nav-header">Main</li>
                <li class="nav-item"><a href="<%= ctx %>/dashboard" class="nav-link"><i class="nav-icon fas fa-tachometer-alt"></i><p>Dashboard</p></a></li>
                <li class="nav-header">Catalogue</li>
                <li class="nav-item"><a href="<%= ctx %>/products?action=list" class="nav-link"><i class="nav-icon fas fa-box-open"></i><p>Products</p></a></li>
                <li class="nav-item"><a href="<%= ctx %>/categories?action=list" class="nav-link"><i class="nav-icon fas fa-tags"></i><p>Categories</p></a></li>
                <li class="nav-item"><a href="<%= ctx %>/suppliers?action=list" class="nav-link"><i class="nav-icon fas fa-truck"></i><p>Suppliers</p></a></li>
                <li class="nav-header">Operations</li>
                <li class="nav-item"><a href="<%= ctx %>/sales?action=pos" class="nav-link active"><i class="nav-icon fas fa-cash-register"></i><p>Point of sale</p></a></li>
                <li class="nav-item"><a href="<%= ctx %>/inventory?action=list" class="nav-link"><i class="nav-icon fas fa-warehouse"></i><p>Inventory</p></a></li>
                <li class="nav-item"><a href="<%= ctx %>/sales?action=history" class="nav-link"><i class="nav-icon fas fa-file-invoice-dollar"></i><p>Sales history</p></a></li>
                <li class="nav-item"><a href="<%= ctx %>/reports.jsp" class="nav-link"><i class="nav-icon fas fa-chart-bar"></i><p>Reports</p></a></li>
                <li class="nav-item"><a href="<%= ctx %>/logout" class="nav-link"><i class="nav-icon fas fa-sign-out-alt"></i><p>Sign out</p></a></li>
            </ul>
        </nav>
    </div>
</aside>

<%-- MAIN CONTENT --%>
<div class="content-wrapper">
<div class="page-content">

    <div class="page-heading">
        <div>
            <h2><i class="fas fa-cash-register" style="font-size:18px;color:#2563eb;margin-right:8px"></i>Point of sale</h2>
            <p>Tap a product to add it to the cart, then check out</p>
        </div>
        <a href="<%= ctx %>/sales?action=history" class="btn-sec">
            <i class="fas fa-file-invoice-dollar" style="font-size:12px"></i> View sales history
        </a>
    </div>

    <% if (cartError != null && !cartError.isEmpty()) { %>
    <div class="flash flash-error">
        <i class="fas fa-circle-exclamation"></i>
        <%= cartError.replace("+", " ") %>
        <button class="flash-close" onclick="this.parentElement.remove()">&times;</button>
    </div>
    <% } %>
    <% if (errorMessage != null && !errorMessage.isEmpty()) { %>
    <div class="flash flash-error">
        <i class="fas fa-circle-exclamation"></i>
        <%= errorMessage %>
        <button class="flash-close" onclick="this.parentElement.remove()">&times;</button>
    </div>
    <% } %>

    <div class="pos-layout">

        <%-- LEFT: PRODUCT GRID --%>
        <div>
            <div class="pos-search">
                <input type="text" id="productSearch" placeholder="Search products by name or SKU...">
            </div>

            <% if (products.isEmpty()) { %>
            <div class="empty-products">
                <i class="fas fa-box-open"></i>
                No active products found.
                <a href="<%= ctx %>/products?action=new" style="color:#2563eb;font-weight:600">Add a product</a> first.
            </div>
            <% } else { %>
            <div class="product-grid" id="productGrid">
                <%
                for (Product p : products) {
                    boolean outOfStock = p.getCurrentStock() <= 0;
                    String stockClass = outOfStock ? "out" : (p.getCurrentStock() <= p.getReorderLevel() ? "low" : "");
                    String stockLabel = outOfStock ? "Out of stock" : p.getCurrentStock() + " " + p.getUnit() + " left";
                %>
                <div class="product-card <%= outOfStock ? "out-of-stock" : "" %>"
                     data-name="<%= p.getName().toLowerCase() %>"
                     data-sku="<%= p.getSku().toLowerCase() %>"
                     <% if (!outOfStock) { %>
                     onclick="addToCart(<%= p.getId() %>, '<%= p.getName().replace("'", "\\'") %>', <%= p.getCurrentStock() %>)"
                     <% } %>>
                    <div class="pc-icon"><i class="fas fa-box"></i></div>
                    <div class="pc-name"><%= p.getName() %></div>
                    <div class="pc-sku"><%= p.getSku() %></div>
                    <div class="pc-price">&#x20A6;<%= String.format("%,.2f", p.getSellingPrice()) %></div>
                    <div class="pc-stock <%= stockClass %>"><%= stockLabel %></div>
                </div>
                <% } %>
            </div>
            <% } %>
        </div>

        <%-- RIGHT: CART + CHECKOUT --%>
        <div class="cart-panel">
            <div class="cart-header">
                <h3><i class="fas fa-shopping-cart"></i> Cart (<%= cart.size() %>)</h3>
                <% if (!cart.isEmpty()) { %>
                <form action="<%= ctx %>/sales" method="POST" style="margin:0" id="clearCartForm">
                    <input type="hidden" name="action" value="clearCart">
                    <button type="submit" class="cart-clear" onclick="return confirm('Clear the whole cart?')">Clear all</button>
                </form>
                <% } %>
            </div>

            <div class="cart-items">
                <% if (cart.isEmpty()) { %>
                <div class="cart-empty">
                    <i class="fas fa-shopping-cart"></i>
                    Cart is empty.<br>Click a product to add it.
                </div>
                <% } else {
                    for (SaleItem item : cart) {
                %>
                <div class="cart-item">
                    <div class="ci-info">
                        <div class="ci-name"><%= item.getProductName() %></div>
                        <div class="ci-price">&#x20A6;<%= String.format("%,.2f", item.getUnitPrice()) %> each</div>
                    </div>
                    <div class="ci-qty-wrap">
                        <button type="button" class="ci-qty-btn" onclick="updateQty(<%= item.getProductId() %>, <%= item.getQuantity() - 1 %>)">−</button>
                        <span class="ci-qty-val"><%= item.getQuantity() %></span>
                        <button type="button" class="ci-qty-btn" onclick="updateQty(<%= item.getProductId() %>, <%= item.getQuantity() + 1 %>)">+</button>
                    </div>
                    <div class="ci-total">&#x20A6;<%= String.format("%,.0f", item.getLineTotal() != null ? item.getLineTotal() : BigDecimal.ZERO) %></div>
                    <button type="button" class="ci-remove" onclick="removeItem(<%= item.getProductId() %>)" title="Remove">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
                <% }
                } %>
            </div>

            <% if (!cart.isEmpty()) { %>
            <div class="cart-total-row">
                <span class="cart-total-label">Subtotal</span>
                <span class="cart-total-val">&#x20A6;<%= String.format("%,.2f", cartTotal) %></span>
            </div>

            <%-- Checkout form - posts straight to SaleServlet action=checkout --%>
            <form action="<%= ctx %>/sales" method="POST" class="checkout-form" id="checkoutForm">
                <input type="hidden" name="action" value="checkout">

                <div class="field-group">
                    <label class="field-label">Customer name <span style="font-weight:400;color:#94a3b8">(optional)</span></label>
                    <input type="text" name="customerName" class="field-input" placeholder="Walk-in customer">
                </div>

                <div class="field-row">
                    <div class="field-group">
                        <label class="field-label">Payment method</label>
                        <select name="paymentMethod" class="field-select" required>
                            <option value="CASH">Cash</option>
                            <option value="TRANSFER">Bank transfer</option>
                            <option value="POS">POS machine</option>
                            <option value="CREDIT">Credit</option>
                        </select>
                    </div>
                    <div class="field-group">
                        <label class="field-label">Discount (&#x20A6;)</label>
                        <input type="number" name="discountAmount" id="discountAmount" class="field-input" placeholder="0" min="0" step="0.01" value="0">
                    </div>
                </div>

                <div class="field-group">
                    <label class="field-label">Amount paid <span class="req" style="color:#dc2626">*</span></label>
                    <input type="number" name="amountPaid" id="amountPaid" class="field-input" placeholder="0.00" min="0" step="0.01" required>
                </div>

                <div class="change-display" id="changeDisplay"></div>

                <div class="field-group">
                    <label class="field-label">Notes <span style="font-weight:400;color:#94a3b8">(optional)</span></label>
                    <input type="text" name="notes" class="field-input" placeholder="e.g. gift wrap requested">
                </div>

                <button type="submit" class="btn-checkout" id="checkoutBtn">
                    <i class="fas fa-check"></i> Complete sale
                </button>
            </form>
            <% } %>
        </div>

    </div>

</div>
</div>

<footer class="main-footer">
    <strong>StockPro Inventory System</strong> - &copy; 2025 Built for Nigerian SMEs
</footer>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.4/jquery.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/4.6.2/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<script>
var ctx = '<%= ctx %>';
var cartLineTotal = <%= cartTotal.toPlainString() %>;

// ── Product search filter ──────────────────────────────────
$('#productSearch').on('input', function () {
    var q = $(this).val().toLowerCase().trim();
    $('.product-card').each(function () {
        var name = $(this).data('name') + '';
        var sku  = $(this).data('sku')  + '';
        $(this).toggle(name.indexOf(q) > -1 || sku.indexOf(q) > -1);
    });
});

// ── Add to cart: submit a hidden form via POST ─────────────
function addToCart(productId, productName, currentStock) {
    var form = document.createElement('form');
    form.method = 'POST';
    form.action = ctx + '/sales';

    var actionInput = document.createElement('input');
    actionInput.type = 'hidden'; actionInput.name = 'action'; actionInput.value = 'addToCart';
    form.appendChild(actionInput);

    var pidInput = document.createElement('input');
    pidInput.type = 'hidden'; pidInput.name = 'productId'; pidInput.value = productId;
    form.appendChild(pidInput);

    var qtyInput = document.createElement('input');
    qtyInput.type = 'hidden'; qtyInput.name = 'quantity'; qtyInput.value = '1';
    form.appendChild(qtyInput);

    document.body.appendChild(form);
    form.submit();
}

// ── Update quantity ─────────────────────────────────────────
function updateQty(productId, newQty) {
    var form = document.createElement('form');
    form.method = 'POST';
    form.action = ctx + '/sales';
    form.innerHTML =
        '<input type="hidden" name="action" value="updateCart">' +
        '<input type="hidden" name="productId" value="' + productId + '">' +
        '<input type="hidden" name="quantity" value="' + newQty + '">';
    document.body.appendChild(form);
    form.submit();
}

// ── Remove item ──────────────────────────────────────────────
function removeItem(productId) {
    var form = document.createElement('form');
    form.method = 'POST';
    form.action = ctx + '/sales';
    form.innerHTML =
        '<input type="hidden" name="action" value="removeFromCart">' +
        '<input type="hidden" name="productId" value="' + productId + '">';
    document.body.appendChild(form);
    form.submit();
}

// ── Live change calculation ─────────────────────────────────
function recalcChange() {
    var paid     = parseFloat($('#amountPaid').val())     || 0;
    var discount = parseFloat($('#discountAmount').val()) || 0;
    var grandTotal = Math.max(cartLineTotal - discount, 0);
    var display = $('#changeDisplay');

    if (paid <= 0) { display.hide(); return; }

    var diff = paid - grandTotal;
    display.show();
    if (diff >= 0) {
        display.removeClass('short');
        display.html('<i class="fas fa-circle-check" style="margin-right:6px"></i>Change to give: &#x20A6;' + diff.toLocaleString(undefined, {minimumFractionDigits:2}));
    } else {
        display.addClass('short');
        display.html('<i class="fas fa-triangle-exclamation" style="margin-right:6px"></i>Short by &#x20A6;' + Math.abs(diff).toLocaleString(undefined, {minimumFractionDigits:2}));
    }
}
$('#amountPaid, #discountAmount').on('input', recalcChange);

// ── Prevent double-submit on checkout ───────────────────────
$('#checkoutForm').on('submit', function () {
    $('#checkoutBtn').prop('disabled', true)
        .html('<i class="fas fa-spinner fa-spin"></i> Processing…');
});
</script>
</body>
</html>
