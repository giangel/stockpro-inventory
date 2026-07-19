
package com.inventory.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Product - mirrors the "products" table. One instance = one product row.
 */
public class Product {

	private int id;
	private String name;
	private String sku;
	private String description;
	private int categoryId;
	private String categoryName; // joined from categories table
	private int supplierId;
	private String supplierName; // joined from suppliers table
	private String unit;
	private BigDecimal costPrice;
	private BigDecimal sellingPrice;
	private int currentStock;
	private int reorderLevel;
	private boolean isActive;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;

	public Product() {
	}

	// ── Getters & Setters ──────────────────────────────────────

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getSku() {
		return sku;
	}

	public void setSku(String sku) {
		this.sku = sku;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String desc) {
		this.description = desc;
	}

	public int getCategoryId() {
		return categoryId;
	}

	public void setCategoryId(int categoryId) {
		this.categoryId = categoryId;
	}

	public String getCategoryName() {
		return categoryName;
	}

	public void setCategoryName(String name) {
		this.categoryName = name;
	}

	public int getSupplierId() {
		return supplierId;
	}

	public void setSupplierId(int supplierId) {
		this.supplierId = supplierId;
	}

	public String getSupplierName() {
		return supplierName;
	}

	public void setSupplierName(String name) {
		this.supplierName = name;
	}

	public String getUnit() {
		return unit;
	}

	public void setUnit(String unit) {
		this.unit = unit;
	}

	public BigDecimal getCostPrice() {
		return costPrice;
	}

	public void setCostPrice(BigDecimal price) {
		this.costPrice = price;
	}

	public BigDecimal getSellingPrice() {
		return sellingPrice;
	}

	public void setSellingPrice(BigDecimal price) {
		this.sellingPrice = price;
	}

	public int getCurrentStock() {
		return currentStock;
	}

	public void setCurrentStock(int stock) {
		this.currentStock = stock;
	}

	public int getReorderLevel() {
		return reorderLevel;
	}

	public void setReorderLevel(int level) {
		this.reorderLevel = level;
	}

	public boolean isActive() {
		return isActive;
	}

	public void setActive(boolean active) {
		this.isActive = active;
	}

	public LocalDateTime getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(LocalDateTime v) {
		this.createdAt = v;
	}

	public LocalDateTime getUpdatedAt() {
		return updatedAt;
	}

	public void setUpdatedAt(LocalDateTime v) {
		this.updatedAt = v;
	}
	public int getQuantity() {
	    return this.currentStock; // Use currentStock, not quantity
	}

	// ── Convenience helpers used in JSP ───────────────────────

	/** Returns "critical", "low", or "ok" - used for CSS class names */
	public String getStockStatus() {
		if (currentStock == 0)
			return "out";
		if (currentStock <= reorderLevel * 0.5)
			return "critical";
		if (currentStock <= reorderLevel)
			return "low";
		return "ok";
	}

	/** Profit margin per unit */
	public BigDecimal getMargin() {
		if (costPrice == null || sellingPrice == null)
			return BigDecimal.ZERO;
		return sellingPrice.subtract(costPrice);
	}
}