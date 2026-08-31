
# StockPro – Inventory Management System

A Java EE web application for managing product inventory, categories, and sales for small businesses, built with Servlets, JSP, and PostgreSQL.

## Tech Stack
- Java 11
- Jakarta/Java EE Servlets (`javax.servlet-api` 4.0.1) + JSP + JSTL 1.2
- PostgreSQL (JDBC driver 42.7.3)
- Apache Tomcat 9.0
- Maven (packaging: `war`)

## Prerequisites
- [JDK 11](https://adoptium.net/) or later
- [Eclipse IDE for Enterprise Java and Web Developers](https://www.eclipse.org/downloads/packages/) (Eclipse EE)
- [Apache Tomcat 9.0](https://tomcat.apache.org/download-90.cgi)
- [PostgreSQL](https://www.postgresql.org/download/) (local install, or a cloud instance such as [Neon](https://neon.tech))
- Maven (bundled with Eclipse, or install separately)
- Git

## Project Structure
inventory/ └── src/main/java/com/inventory/ ├── dao/ # Database access classes (CategoryDAO, ProductDAO, etc.) ├── model/ # Entity classes ├── servlet/ # Controllers (Inventory, Sales, etc.) └── util/ # DatabaseUtil (DB connection handling)

## 1. Clone the Repository
```bash
git clone https://github.com/giangel/inventory.git
2. Import into Eclipse
1.	Open Eclipse.
2.	Go to File -> Import -> Maven -> Existing Maven Projects.
3.	Browse to the cloned inventory folder and click Finish.
4.	Wait for Eclipse to resolve Maven dependencies (bottom-right progress bar).
3. Set Up PostgreSQL
1.	Install PostgreSQL and make sure the server is running.
2.	Create the database: 
3.	CREATE DATABASE inventory_db;
4.	Run your schema/table creation script against inventory_db (from your project's SQL file, if you have one).
4. Configure Database Credentials
The app reads DB config from environment variables (with local defaults baked in for development). Set these in your system, or in Eclipse under Run/Debug Configurations -> Environment:
Variable	Default	Description
DB_HOST	localhost	PostgreSQL host
DB_PORT	5432	PostgreSQL port
DB_NAME	inventory_db	Database name
DB_USER	postgres	Database username
DB_PASSWORD	(none)	Database password
DB_SSLMODE	prefer	SSL mode (use require for cloud DBs like Neon)
5. Add Tomcat to Eclipse
1.	In Eclipse, go to the Servers tab -> right-click -> New -> Server.
2.	Choose Apache -> Tomcat v9.0 Server, browse to your Tomcat installation folder, click Finish.
6. Deploy and Run
1.	Right-click the inventory project -> Run As -> Run on Server.
2.	Select the Tomcat v9.0 server you configured and click Finish.
3.	Eclipse will build the WAR and deploy it automatically.
7. Access the App
Open your browser to:
http://localhost:8080/inventory/login
Building Manually (without Eclipse's Run)
mvn clean package
The generated inventory.war will be in the target/ folder - drop it into Tomcat's webapps/ directory to deploy manually.
License

This project is a property of the Department of Computer Science, Adeseun Ogundoyin Polytechnic, Eruwa, Oyo State, Nigeria
