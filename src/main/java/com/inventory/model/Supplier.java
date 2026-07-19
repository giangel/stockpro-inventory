package com.inventory.model;

import java.time.LocalDateTime;

/**
 * Supplier model - mirrors the "suppliers" table. One instance = one row in the
 * suppliers table.
 *
 * productCount is a computed field (not a DB column) - it is populated by
 * SupplierDAO.getAllSuppliers() via a COUNT() JOIN and used only for display in
 * the suppliers table.
 */
public class Supplier {

	private int id;
	private String name;
	private String contactName;
	private String phone;
	private String email;
	private String address;
	private boolean isActive;
	private LocalDateTime createdAt;

	// Not a DB column - filled by DAO via JOIN COUNT
	private int productCount;

	public Supplier() {
	}

	public Supplier(int id, String name) {
		this.id = id;
		this.name = name;
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

	public String getContactName() {
		return contactName;
	}

	public void setContactName(String v) {
		this.contactName = v;
	}

	public String getPhone() {
		return phone;
	}

	public void setPhone(String phone) {
		this.phone = phone;
	}

	public String getEmail() {
		return email;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public String getAddress() {
		return address;
	}

	public void setAddress(String address) {
		this.address = address;
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

	public int getProductCount() {
		return productCount;
	}

	public void setProductCount(int count) {
		this.productCount = count;
	}

	/** Returns initials from the contact name - used for avatar display in JSP */
	public String getContactInitials() {
		if (contactName == null || contactName.isBlank()) {
			return name.substring(0, Math.min(2, name.length())).toUpperCase();
		}
		StringBuilder initials = new StringBuilder();
		for (String part : contactName.trim().split("\\s+")) {
			if (!part.isEmpty())
				initials.append(Character.toUpperCase(part.charAt(0)));
			if (initials.length() >= 2)
				break;
		}
		return initials.toString();
	}

	@Override
	public String toString() {
		return "Supplier{id=" + id + ", name='" + name + "'}";
	}
}