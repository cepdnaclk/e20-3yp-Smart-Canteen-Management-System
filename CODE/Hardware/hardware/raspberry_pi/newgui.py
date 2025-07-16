import tkinter as tk
from tkinter import messagebox
import requests
import threading
import time
from mfrc522 import SimpleMFRC522
import RPi.GPIO as GPIO
import json
from datetime import datetime

# --- API URLs ---
PROFILE_URL = "http://192.168.8.183:8081/api/"
MENU_URL = "http://192.168.8.183:8081/api/menu-items"
ORDER_URL = "http://192.168.8.183:8081/api/orders/place"
reader = SimpleMFRC522()

# --- UI Setup ---
root = tk.Tk()
root.title("Smart Canteen")
root.geometry("520x600")
root.configure(bg="#1e1e2f")

customer_data = {}
menu_items = []
selected_items = {}

name_var = tk.StringVar()
balance_var = tk.StringVar()
subtotal_var = tk.StringVar(value="Subtotal: Rs. 0.00")

# --- Frames ---
welcome_frame = tk.Frame(root, bg="#1e1e2f")
info_frame = tk.Frame(root, bg="#1e1e2f")
menu_frame = tk.Frame(root, bg="#1e1e2f")

tk.Label(welcome_frame, text="Welcome to Smart Canteen", font=('Helvetica', 16), fg="#00adb5", bg="#1e1e2f").pack(pady=20)
tk.Label(welcome_frame, text="Tap your RFID card", font=('Helvetica', 12), fg="white", bg="#1e1e2f").pack()
welcome_frame.pack(expand=True)

tk.Label(info_frame, textvariable=name_var, font=('Helvetica', 14), fg="white", bg="#1e1e2f").pack(pady=5)
tk.Label(info_frame, textvariable=balance_var, font=('Helvetica', 12), fg="#00adb5", bg="#1e1e2f").pack(pady=5)

# Scrollable menu
canvas = tk.Canvas(menu_frame, bg="#1e1e2f", highlightthickness=0)
scroll_y = tk.Scrollbar(menu_frame, orient="vertical", command=canvas.yview)
scroll_frame = tk.Frame(canvas, bg="#1e1e2f")
scroll_frame.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
canvas.create_window((0, 0), window=scroll_frame, anchor="nw")
canvas.configure(yscrollcommand=scroll_y.set)
canvas.pack(side="left", fill="both", expand=True)
scroll_y.pack(side="right", fill="y")

subtotal_label = tk.Label(menu_frame, textvariable=subtotal_var, font=('Helvetica', 12), fg="white", bg="#1e1e2f")
subtotal_label.pack(pady=10)

submit_btn = tk.Button(menu_frame, text="Submit Order", command=lambda: submit_order(), bg="#00adb5", fg="white", font=("Helvetica", 12, "bold"))
submit_btn.pack(pady=10)

# --- Logic Functions ---

def authenticate_rfid(rfid_text):
    global jwt_token
    try:
        # Send the stored text on the card as cardID
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
    try:
        # No headers needed now
        res = requests.get(f"{PROFILE_URL}customer/profile/rfid/{rfid}")
        if res.status_code == 200:
            global customer_data
            customer_data = res.json()

            def update_ui():
                name_var.set(f"Name: {customer_data['username']}")
                balance_var.set(f"Balance: Rs. {customer_data['creditBalance']}")
                show_menu()

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
                get_customer_data(rfid_text)  # Directly get customer data without auth
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
    for widget in scroll_frame.winfo_children():
        widget.destroy()
    for item in menu_items:
        item_id = item["id"]
        row = tk.Frame(scroll_frame, bg="#2e2e3f", pady=5, padx=10)
        row.pack(fill="x", pady=3, padx=5)

        tk.Label(row, text=item["name"], width=15, fg="white", bg="#2e2e3f").pack(side="left")
        tk.Label(row, text=f"Rs. {item['price']:.2f}", width=10, fg="white", bg="#2e2e3f").pack(side="left")

        qty_var = tk.IntVar(value=0)

        def increment(qv=qty_var, iid=item_id): qv.set(qv.get()+1); selected_items[iid] = qv.get(); update_subtotal()
        def decrement(qv=qty_var, iid=item_id): 
            if qv.get() > 0: 
                qv.set(qv.get()-1)
                if qv.get() == 0: selected_items.pop(iid, None)
                else: selected_items[iid] = qv.get()
                update_subtotal()

        tk.Button(row, text="-", command=decrement, width=2).pack(side="left")
        tk.Label(row, textvariable=qty_var, width=3, fg="white", bg="#2e2e3f").pack(side="left")
        tk.Button(row, text="+", command=increment, width=2).pack(side="left")

        tk.Button(row, text="Select", bg="#00adb5", fg="white", command=lambda q=qty_var, iid=item_id: select_item(iid, q)).pack(side="right")

def select_item(item_id, qty_var):
    qty = qty_var.get()
    if qty > 0:
        selected_items[item_id] = qty
        update_subtotal()
    else:
        messagebox.showinfo("Info", "Please increase quantity before selecting.")

def update_subtotal():
    total = 0.0
    for item in menu_items:
        item_id = item["id"]
        if item_id in selected_items:
            qty = selected_items[item_id]
            total += item["price"] * qty
    subtotal_var.set(f"Subtotal: Rs. {total:.2f}")

def submit_order():
    global jwt_token
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

    if not jwt_token:
        messagebox.showerror("Unauthorized", "Please authenticate first.")
        return

    headers = {"Authorization": f"Bearer {jwt_token}"}
    try:
        res = requests.post(ORDER_URL, json=payload, headers=headers)
        log("Sending Order Request", f"POST {ORDER_URL}\nPayload: {payload}")
        res = requests.post(ORDER_URL, json=payload, headers=headers)
        log("Order Response", f"Status: {res.status_code}\nResponse: {res.text}")

        if res.status_code == 200:
            response = res.json()
            fingerprint_id = response.get("fingerprintID")
            order_id = response.get("id")
            if not fingerprint_id or not order_id:
                messagebox.showerror("Error", "Missing fingerprint ID or order ID.")
                return

            if send_fingerprint_to_esp32(fingerprint_id):
                complete_order_directly(order_id)
            else:
                messagebox.showerror("Mismatch", "Fingerprint does not match.")
        else:
            messagebox.showerror("Order Failed", f"Status: {res.status_code} - {res.text}")
    except Exception as e:
        log("Order Request Error", str(e))
        messagebox.showerror("Network Error", str(e))

def send_fingerprint_to_esp32(fingerprint_id):
    try:
        match_url = "http://192.168.8.X:5000/match"
        payload = {"expectedFingerprintID": fingerprint_id}
        log("Sending Fingerprint to ESP32", f"POST {match_url}\nPayload: {payload}")
        res = requests.post(match_url, json=payload, timeout=15)
        log("ESP32 Response", f"Status: {res.status_code}\nResponse: {res.text}")
        return res.status_code == 200 and res.json().get("match", False)
    except Exception as e:
        log("ESP32 Request Error", str(e))
        messagebox.showerror("ESP32 Error", str(e))
        return False

def complete_order_directly(order_id):
    try:
        url = f"{PROFILE_URL}order/{order_id}/completeDirectly"
        log("Completing Order", f"POST {url}")
        res = requests.post(url)
        log("Complete Order Response", f"Status: {res.status_code}\nResponse: {res.text}")
        if res.status_code == 200:
            messagebox.showinfo("Success", "Order completed!")
            reset_ui()
        else:
            messagebox.showerror("Error", f"Completion failed: {res.status_code}")
    except Exception as e:
        log("Complete Order Error", str(e))
        messagebox.showerror("Network Error", str(e))

def log(title, content):
    print(f"\n[{datetime.now()}] === {title} ===")
    print(content)
def reset_ui():
    selected_items.clear()
    name_var.set("")
    balance_var.set("")
    subtotal_var.set("Subtotal: Rs. 0.00")
    info_frame.pack_forget()
    menu_frame.pack_forget()
    welcome_frame.pack(expand=True)

def show_menu():
    welcome_frame.pack_forget()
    info_frame.pack()
    menu_frame.pack(fill="both", expand=True)
    fetch_menu()

def rfid_loop():
    while True:
        try:
            id, text = reader.read()
            rfid_text = text.strip()
            if rfid_text:
                print(f"RFID Read: {rfid_text}")
                authenticate_rfid(rfid_text)
            time.sleep(2)
        except Exception as e:
            print("RFID error:", e)
            time.sleep(1)

# --- Main ---
try:
    threading.Thread(target=rfid_loop, daemon=True).start()
    root.mainloop()
finally:
    GPIO.cleanup()
