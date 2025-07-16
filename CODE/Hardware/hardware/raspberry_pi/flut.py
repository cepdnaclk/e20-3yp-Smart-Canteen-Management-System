import tkinter as tk
from tkinter import messagebox, ttk
import requests
import threading
import time
from mfrc522 import SimpleMFRC522
import RPi.GPIO as GPIO
import json
import os

os.system("fuser -k 5000/tcp")

# --- API URLs ---
PROFILE_URL = "http://192.168.8.183:8081/api/"
MENU_URL = "http://192.168.8.183:8081/api/menu-items"
ORDER_URL = "http://192.168.8.183:8081/api/orders/place"
reader = SimpleMFRC522()

# --- Global Variables ---
jwt_token = None  # Initialize jwt_token globally
customer_data = {}
menu_items = []
selected_items = {}

# --- UI Setup ---
root = tk.Tk()
root.title("Smart Canteen")
root.geometry("800x600")
root.configure(bg="#f5f5f5")

# Initialize Tkinter variables AFTER creating root window
cart_items_count = tk.IntVar(value=0)

# Style configuration
style = ttk.Style()
style.configure("TFrame", background="#f5f5f5")
style.configure("TButton", 
                background="#00adb5", 
                foreground="white", 
                font=("Helvetica", 12, "bold"),
                borderwidth=0)
style.map("TButton", background=[("active", "#0097a7")])
style.configure("Card.TFrame", background="white", borderwidth=1, relief="solid")
style.configure("Header.TLabel", 
                background="#00adb5", 
                foreground="white", 
                font=("Helvetica", 16, "bold"),
                padding=10)
style.configure("Title.TLabel", 
                font=("Helvetica", 18, "bold"), 
                foreground="#333333", 
                background="#f5f5f5")
style.configure("Item.TLabel", 
                font=("Helvetica", 12), 
                foreground="#333333", 
                background="white")
style.configure("Price.TLabel", 
                font=("Helvetica", 12, "bold"), 
                foreground="#00adb5", 
                background="white")
style.configure("Badge.TLabel", 
                background="red", 
                foreground="white", 
                font=("Helvetica", 8, "bold"))

# --- Frames ---
welcome_frame = ttk.Frame(root)
main_frame = ttk.Frame(root)
cart_frame = None

# Welcome Frame
ttk.Label(welcome_frame, 
          text="Welcome to Smart Canteen", 
          font=('Helvetica', 24, 'bold'),
          foreground="#00adb5",
          background="#f5f5f5").pack(pady=40)
ttk.Label(welcome_frame, 
          text="Tap your RFID card to begin", 
          font=('Helvetica', 14),
          foreground="#666666",
          background="#f5f5f5").pack(pady=10)
welcome_frame.pack(expand=True, fill="both")

# Main App Frame (hidden initially)
header_frame = ttk.Frame(main_frame, style="Header.TFrame")
header_frame.pack(fill="x")

user_label = ttk.Label(header_frame, 
                      text="Hi, Guest", 
                      style="Header.TLabel")
user_label.pack(side="left", padx=20)

cart_btn = ttk.Button(header_frame, 
                     text="??", 
                     style="TButton",
                     width=3,
                     command=lambda: show_cart())
cart_btn.pack(side="right", padx=20, pady=5)

# Cart badge
cart_badge = ttk.Label(header_frame, 
                      textvariable=cart_items_count, 
                      style="Badge.TLabel")
cart_badge.place(relx=0.97, rely=0.1, anchor="ne")

# Search Frame
search_frame = ttk.Frame(main_frame, padding=10)
search_frame.pack(fill="x")

search_var = tk.StringVar()
search_entry = ttk.Entry(search_frame, 
                        textvariable=search_var, 
                        font=("Helvetica", 12),
                        width=30)
search_entry.pack(side="left", padx=5, fill="x", expand=True)
search_entry.insert(0, "Search menu items...")

# Menu Frame
menu_container = ttk.Frame(main_frame)
menu_container.pack(fill="both", expand=True, padx=10, pady=10)

menu_canvas = tk.Canvas(menu_container, bg="#f5f5f5", highlightthickness=0)
scroll_y = ttk.Scrollbar(menu_container, orient="vertical", command=menu_canvas.yview)
menu_frame = ttk.Frame(menu_canvas)

menu_frame.bind("<Configure>", lambda e: menu_canvas.configure(scrollregion=menu_canvas.bbox("all")))
menu_canvas.create_window((0, 0), window=menu_frame, anchor="nw")
menu_canvas.configure(yscrollcommand=scroll_y.set)

menu_canvas.pack(side="left", fill="both", expand=True)
scroll_y.pack(side="right", fill="y")

# --- Logic Functions ---
def authenticate_rfid(rfid_text):
    global jwt_token
    try:
        res = requests.post(f"{PROFILE_URL}auth/login/rfid", json={"cardID": rfid_text})
        if res.status_code == 200:
            jwt_token = res.json().get("token")
            if jwt_token:
                print("Token received.")
                get_customer_data(rfid_text)
            else:
                messagebox.showerror("Error", "Token not received.")
        else:
            messagebox.showerror("Authentication Failed", res.json().get("message", "Invalid RFID"))
    except Exception as e:
        messagebox.showerror("Network Error", str(e))

def get_customer_data(rfid):
    global jwt_token
    try:
        res = requests.get(f"{PROFILE_URL}customer/profile/rfid/{rfid}")
        if res.status_code == 200:
            global customer_data
            customer_data = res.json()
            
            def update_ui():
                user_label.config(text=f"Hi, {customer_data['username']}")
                show_main()
                
            root.after(0, update_ui)
        else:
            root.after(0, lambda: messagebox.showerror("Error", "User not found."))
    except Exception as e:
        root.after(0, lambda: messagebox.showerror("Network Error", str(e)))

def rfid_loop():
    while True:
        try:
            id, text = reader.read()
            rfid_text = text.strip()
            if rfid_text:
                print(f"Read RFID card text: {rfid_text}")
                authenticate_rfid(rfid_text)  # Call authentication first
            time.sleep(2)
        except Exception as e:
            print("RFID error:", e)
            time.sleep(1)

def fetch_menu():
    try:
        res = requests.get(MENU_URL)
        if res.status_code == 200:
            global menu_items
            menu_items = res.json()
            build_menu()
        else:
            messagebox.showerror("Error", "Failed to load menu")
    except Exception as e:
        messagebox.showerror("Network Error", str(e))

def build_menu():
    for widget in menu_frame.winfo_children():
        widget.destroy()
    
    # Create category sections
    categories = {}
    for item in menu_items:
        if item.get("category") not in categories:
            categories[item.get("category")] = []
        categories[item.get("category")].append(item)
    
    row_idx = 0
    for category, items in categories.items():
        # Category header
        ttk.Label(menu_frame, 
                 text=category, 
                 style="Title.TLabel").grid(row=row_idx, column=0, sticky="w", pady=(20, 10), padx=10)
        row_idx += 1
        
        # Items in horizontal scroll
        cat_frame = ttk.Frame(menu_frame)
        cat_frame.grid(row=row_idx, column=0, sticky="ew", padx=10, pady=5)
        row_idx += 1
        
        canvas = tk.Canvas(cat_frame, bg="#f5f5f5", height=180, highlightthickness=0)
        scroll_x = ttk.Scrollbar(cat_frame, orient="horizontal", command=canvas.xview)
        item_frame = ttk.Frame(canvas)
        
        item_frame.bind("<Configure>", lambda e, canvas=canvas: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((0, 0), window=item_frame, anchor="nw")
        canvas.configure(xscrollcommand=scroll_x.set)
        
        canvas.pack(side="top", fill="x")
        scroll_x.pack(side="bottom", fill="x")
        
        for idx, item in enumerate(items):
            card = ttk.Frame(item_frame, style="Card.TFrame", padding=10)
            card.grid(row=0, column=idx, padx=10, pady=5, sticky="nsew")
            
            # Item details
            ttk.Label(card, 
                     text=item["name"], 
                     style="Item.TLabel",
                     wraplength=120).pack(pady=5)
            
            ttk.Label(card, 
                     text=f"Rs. {item['price']:.2f}", 
                     style="Price.TLabel").pack()
            
            # Quantity controls
            qty_frame = ttk.Frame(card)
            qty_frame.pack(pady=10)
            
            qty_var = tk.IntVar(value=0)
            
            def decrement(qv=qty_var, item_id=item["id"]):
                if qv.get() > 0:
                    qv.set(qv.get() - 1)
                    update_cart(item_id, qv.get())
            
            def increment(qv=qty_var, item_id=item["id"]):
                qv.set(qv.get() + 1)
                update_cart(item_id, qv.get())
            
            ttk.Button(qty_frame, text="-", width=2, command=decrement).pack(side="left")
            ttk.Label(qty_frame, textvariable=qty_var, width=3).pack(side="left", padx=5)
            ttk.Button(qty_frame, text="+", width=2, command=increment).pack(side="left")

def update_cart(item_id, quantity):
    if quantity > 0:
        selected_items[item_id] = quantity
    elif item_id in selected_items:
        del selected_items[item_id]
    
    # Update cart badge
    cart_items_count.set(len(selected_items))
    update_cart_badge()

def update_cart_badge():
    count = cart_items_count.get()
    if count > 0:
        cart_badge.configure(text=str(count))
        cart_badge.place(relx=0.97, rely=0.1, anchor="ne")
    else:
        cart_badge.place_forget()

def show_cart():
    global cart_frame
    
    if cart_frame:
        cart_frame.destroy()
    
    cart_frame = tk.Toplevel(root)
    cart_frame.title("Your Cart")
    cart_frame.geometry("400x500")
    cart_frame.configure(bg="#f5f5f5")
    cart_frame.grab_set()
    
    # Header
    ttk.Label(cart_frame, 
             text="Your Cart", 
             style="Header.TLabel").pack(fill="x")
    
    # Cart items
    cart_container = ttk.Frame(cart_frame)
    cart_container.pack(fill="both", expand=True, padx=20, pady=10)
    
    if not selected_items:
        ttk.Label(cart_container, 
                 text="Your cart is empty!", 
                 font=("Helvetica", 14),
                 foreground="#666666").pack(expand=True)
    else:
        canvas = tk.Canvas(cart_container, bg="#f5f5f5", highlightthickness=0)
        scroll_y = ttk.Scrollbar(cart_container, orient="vertical", command=canvas.yview)
        items_frame = ttk.Frame(canvas)
        
        items_frame.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((0, 0), window=items_frame, anchor="nw")
        canvas.configure(yscrollcommand=scroll_y.set)
        
        canvas.pack(side="left", fill="both", expand=True)
        scroll_y.pack(side="right", fill="y")
        
        total = 0.0
        for item_id, quantity in selected_items.items():
            item = next((i for i in menu_items if i["id"] == item_id), None)
            if not item:
                continue
                
            total += item["price"] * quantity
            
            card = ttk.Frame(items_frame, style="Card.TFrame", padding=10)
            card.pack(fill="x", pady=5)
            
            # Item details
            ttk.Label(card, 
                     text=item["name"], 
                     style="Item.TLabel").grid(row=0, column=0, sticky="w")
            
            ttk.Label(card, 
                     text=f"Rs. {item['price']:.2f} x {quantity} = Rs. {item['price'] * quantity:.2f}", 
                     style="Price.TLabel").grid(row=1, column=0, sticky="w", pady=5)
            
            # Remove button
            ttk.Button(card, 
                      text="Remove", 
                      command=lambda id=item_id: remove_from_cart(id)).grid(row=0, column=1, rowspan=2, padx=10)
    
        # Footer
        footer = ttk.Frame(cart_frame, padding=20)
        footer.pack(fill="x", side="bottom")
        
        ttk.Label(footer, 
                 text=f"Total: Rs. {total:.2f}", 
                 font=("Helvetica", 14, "bold")).pack(side="left")
        
        ttk.Button(footer, 
                  text="Place Order", 
                  style="TButton",
                  command=lambda: submit_order(cart_frame)).pack(side="right")
        
        ttk.Button(footer, 
                  text="Clear All", 
                  command=clear_cart).pack(side="right", padx=10)

def remove_from_cart(item_id):
    if item_id in selected_items:
        del selected_items[item_id]
    cart_items_count.set(len(selected_items))
    update_cart_badge()
    show_cart()

def clear_cart():
    selected_items.clear()
    cart_items_count.set(0)
    update_cart_badge()
    show_cart()

def submit_order(cart_window):
    global jwt_token
    if not jwt_token:
        messagebox.showerror("Unauthorized", "Please authenticate first.")
        return
        
    if not selected_items:
        messagebox.showinfo("Empty Order", "Please select at least one item.")
        return

    email = customer_data.get("email")
    if not email:
        messagebox.showerror("Error", "Customer email not found.")
        return

    payload = {
        "email": email,
        "items": {str(k): v for k, v in selected_items.items()},
        "scheduledTime": None
    }

    headers = {"Authorization": f"Bearer {jwt_token}"}
    try:
        res = requests.post(ORDER_URL, json=payload, headers=headers)
        print(f"Response [{res.status_code}]: {res.text}")
        if res.status_code == 200:
            response_data = res.json()
            order_id = response_data.get("id")
            if order_id:
                trigger_biometric_auth(email, order_id, jwt_token)
            messagebox.showinfo("Success", f"Order #{order_id} submitted!")
            clear_cart()
            cart_window.destroy()
        elif res.status_code == 400:
            error_msg = res.json().get("message", "Bad Request")
            messagebox.showerror("Error", error_msg)
        elif res.status_code == 401:
            messagebox.showerror("Unauthorized", "Authentication required or token expired.")
        else:
            messagebox.showerror("Error", f"Order failed: {res.status_code}")
    except Exception as e:
        messagebox.showerror("Network Error", str(e))

def trigger_biometric_auth(email, order_id, token):
    biometric_url = f"{PROFILE_URL}biometric/initiate"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    payload = {
        "email": email,
        "orderId": order_id
    }
    try:
        res = requests.post(biometric_url, json=payload, headers=headers)
        print(f"[Biometric] Response [{res.status_code}]: {res.text}")
    except Exception as e:
        print("Biometric call failed:", e)

def show_main():
    welcome_frame.pack_forget()
    main_frame.pack(fill="both", expand=True)
    fetch_menu()

def reset_ui():
    global jwt_token
    jwt_token = None
    selected_items.clear()
    cart_items_count.set(0)
    update_cart_badge()
    main_frame.pack_forget()
    welcome_frame.pack(expand=True)
    user_label.config(text="Hi, Guest")

# Start the RFID reading loop in a background thread
threading.Thread(target=rfid_loop, daemon=True).start()

try:
    root.mainloop()
finally:
    GPIO.cleanup()
