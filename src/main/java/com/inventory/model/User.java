package com.inventory.model;

import java.time.LocalDateTime;

/**
 * User model - mirrors the "users" table exactly. One instance = one row in the
 * users table.
 */
public class User {

	private int id;
	private String fullName;
	private String username;
	private String password;
	private String role; // "ADMIN" or "CASHIER"
	private boolean isActive;
	private LocalDateTime createdAt;

	public User() {
	}

	public User(int id, String fullName, String username, String role) {
		this.id = id;
		this.fullName = fullName;
		this.username = username;
		this.role = role;
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getFullName() {
		return fullName;
	}

	public void setFullName(String fullName) {
		this.fullName = fullName;
	}

	public String getUsername() {
		return username;
	}

	public void setUsername(String username) {
		this.username = username;
	}

	public String getPassword() {
		return password;
	}

	public void setPassword(String password) {
		this.password = password;
	}

	public String getRole() {
		return role;
	}

	public void setRole(String role) {
		this.role = role;
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

	/** Convenience - returns true if this user has the ADMIN role */
	public boolean isAdmin() {
		return "ADMIN".equalsIgnoreCase(this.role);
	}

	@Override
	public String toString() {
		return "User{id=" + id + ", username='" + username + "', role='" + role + "'}";
	}
}
