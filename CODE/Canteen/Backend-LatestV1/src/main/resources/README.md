# Smart Canteen Backend

This is the backend server for the Smart Canteen application, a comprehensive system for managing customers, merchants, and orders in a digital canteen environment. It is built with Java and the Spring Boot framework.

## Features

### 1. Multi-Role Authentication
-   **Three User Roles:** Customer, Merchant, and Admin.
-   **JWT-based Security:** Secure authentication using JSON Web Tokens.
-   **Registration:** Separate registration flows for each user role with email verification.
-   **Login:** Standard email/password login and RFID card login.
-   **Forgot Password:** Secure password reset functionality via email link.

### 2. Customer Features
-   **Profile Management:** Full CRUD operations on user profiles, including profile picture uploads.
-   **Account Top-Up:** Customers can request to top up their account balance, which merchants can approve.
-   **Shopping Cart:** Full CRUD operations on the cart with real-time stock validation.
-   **Checkout:** Place orders from the cart, with automated balance deduction.
-   **Email Receipts:** Automatically receive a detailed HTML receipt via email upon order completion.
-   **Messaging:** Real-time messaging system to communicate directly with merchants.
-   **Order History:** View a complete history of all past orders.

### 3. Merchant Features
-   **Dashboard:** A central dashboard for managing canteen operations.
-   **Food Management:** Full CRUD operations for food categories and food items within those categories.
-   **Image Uploads:** Merchants can upload photos for their food items.
-   **Low Stock Alerts:** Automated notification system alerts merchants when an item's stock falls below a defined threshold.
-   **Top-Up Approval:** View and approve/reject credit top-up requests from customers.
-   **Sales Reporting:**
    -   Generate **daily** sales reports with breakdowns of sales, costs, and profits.
    -   Generate **monthly** sales reports for a high-level performance overview.

### 4. Admin Features
-   **User Management:** Admins can view, deactivate, and reactivate all customers and merchants in the system.
-   **Platform Analytics:**
    -   View platform-wide sales reports for any date range.
    -   Get key statistics like the total number of customers, merchants, and admins.

## API Endpoint Structure

-   `/api/auth/**` - Authentication (login, register, reset password)
-   `/api/customer/**` - Customer-specific actions
-   `/api/merchant/**` - Merchant-specific actions
-   `/api/admin/**` - Admin-specific actions
-   `/api/messages/**` - Messaging system
-   `/uploads/{fileName}` - Accessing uploaded images

---