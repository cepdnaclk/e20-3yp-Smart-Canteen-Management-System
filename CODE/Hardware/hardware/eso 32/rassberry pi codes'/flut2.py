import tkinter as tk
from tkinter import messagebox, ttk
import requests
import threading
import time
from mfrc522 import SimpleMFRC522
import RPi.GPIO as GPIO
import json
import os
from PIL import Image, ImageTk # Import Pillow for image handling
import io

# Ensure the fuser command runs if you are troubleshooting port issues
# os.system("fuser -k 5000/tcp") 

# --- API URLs ---
# Make sure your IP matches the backend server.
# For images, you might need a separate base URL if the backend doesn't prepend it.
PROFILE_URL = "http://192.168.8.183:8081/api/"
MENU_URL = "http://192.168.8.183:8081/api/menu-items" # This fetches all menu items, adjust if you have a "today's menu" endpoint
ORDER_URL = "http://192.168.8.183:8081/api/orders/place"
UPLOAD_BASE_URL = "http://192.168.8.183:8081/uploads/" # Base URL for fetching images

# Initialize RFID reader
try:
    reader = SimpleMFRC522()
except Exception as e:
    print(f"Error initializing MFRC522: {e}. Running without RFID functionality.")
    # Create a mock reader if actual hardware is not available for testing
    class MockRFIDReader:
        def read(self):
            print("Mock RFID: Simulating card read...")
            return 123456789, "test_rfid_card_123" # Simulate an RFID read
    reader = MockRFIDReader()

# --- Global Variables ---
jwt_token = None
customer_data = {}
menu_items = []
selected_items = {} # {item_id: quantity}
all_menu_items = [] # To store all fetched menu items for filtering
filtered_menu_items = [] # To store currently displayed menu items after filtering

# --- UI Setup ---
root = tk.Tk()
root.title("Smart Canteen")
root.geometry("800x600")
root.configure(bg="#F5F5F5") # Light grey background

# Initialize Tkinter variables
cart_items_count = tk.IntVar(value=0)
is_menu_visible = tk.BooleanVar(value=False)
selected_menu_item = tk.StringVar(value="Home") # For side menu selection

# Style configuration - Matching Flutter's colors and general look
style = ttk.Style()
style.theme_use('clam') # 'clam' often provides a cleaner base for custom styling

# Base colors from Flutter example
COLOR_PRIMARY = "#00adb5"  # From original button and header
COLOR_ACCENT = "#0097a7"   # Active button state
COLOR_BACKGROUND = "#F5F5F5" # Light grey background
COLOR_TEXT_DARK = "#333333"
COLOR_TEXT_LIGHT = "white"
COLOR_CARD_BACKGROUND = "white"
COLOR_BADGE = "red"
COLOR_SELECTED_MENU = "#673AB7" # deepPurple from Flutter code
COLOR_NORMAL_MENU = "black"

root.option_add('*TCombobox*Listbox.background', 'white')
root.option_add('*TCombobox*Listbox.foreground', COLOR_TEXT_DARK)
root.option_add('*TCombobox*Listbox.font', ("Helvetica", 11))

style.configure("TFrame", background=COLOR_BACKGROUND)
style.configure("TButton",
                background=COLOR_PRIMARY,
                foreground=COLOR_TEXT_LIGHT,
                font=("Helvetica", 12, "bold"),
                borderwidth=0,
                focusthickness=0)
style.map("TButton",
          background=[("active", COLOR_ACCENT)],
          foreground=[("active", COLOR_TEXT_LIGHT)])

style.configure("Card.TFrame", background=COLOR_CARD_BACKGROUND, borderwidth=1, relief="solid",
                lightcolor=COLOR_CARD_BACKGROUND, darkcolor=COLOR_CARD_BACKGROUND) # Attempt to remove border color

# Custom style for menu item cards to mimic Flutter's rounded corners and slight shadow
style.configure("MenuItem.TFrame",
                background=COLOR_CARD_BACKGROUND,
                relief="flat",
                borderwidth=0) # Flat border to allow custom drawing for rounded corners/shadows
style.map("MenuItem.TFrame",
          background=[('selected', '#e0f7fa')]) # Light green background for selected items

style.configure("Header.TLabel",
                background=COLOR_PRIMARY,
                foreground=COLOR_TEXT_LIGHT,
                font=("Helvetica", 16, "bold"),
                padding=10)
style.configure("Title.TLabel",
                font=("Helvetica", 18, "bold"),
                foreground=COLOR_TEXT_DARK,
                background=COLOR_BACKGROUND)
style.configure("Item.TLabel",
                font=("Helvetica", 12),
                foreground=COLOR_TEXT_DARK,
                background=COLOR_CARD_BACKGROUND)
style.configure("Price.TLabel",
                font=("Helvetica", 12, "bold"),
                foreground=COLOR_PRIMARY,
                background=COLOR_CARD_BACKGROUND)
style.configure("Badge.TLabel",
                background=COLOR_BADGE,
                foreground="white",
                font=("Helvetica", 8, "bold"),
                relief="flat",
                padding=(4, 2)) # Adjusted padding for badge
style.configure("Menu.TButton", # For the menu (hamburger) button
                background=COLOR_BACKGROUND,
                foreground=COLOR_TEXT_DARK,
                font=("Helvetica", 12),
                borderwidth=0)
style.map("Menu.TButton",
          background=[("active", "#e0e0e0")]) # Slight hover effect

# Entry widget style for search bar
style.configure("TEntry",
                fieldbackground="white",
                foreground=COLOR_TEXT_DARK,
                font=("Helvetica", 12),
                borderwidth=1,
                relief="solid",
                focusthickness=1,
                focuscolor=COLOR_PRIMARY)


# --- Frames ---
welcome_frame = ttk.Frame(root, style="TFrame")
main_frame = ttk.Frame(root, style="TFrame")
side_menu_frame = ttk.Frame(root, style="TFrame") # For the sliding side menu
cart_frame = None

# Welcome Frame
ttk.Label(welcome_frame,
          text="Welcome to Smart Canteen",
          font=('Helvetica', 24, 'bold'),
          foreground=COLOR_PRIMARY,
          background=COLOR_BACKGROUND).pack(pady=40)
ttk.Label(welcome_frame,
          text="Tap your RFID card to begin",
          font=('Helvetica', 14),
          foreground="#666666",
          background=COLOR_BACKGROUND).pack(pady=10)
welcome_frame.pack(expand=True, fill="both")

# Main App Frame (hidden initially)
header_frame = ttk.Frame(main_frame, style="TFrame") # Using default TFrame for header
header_frame.pack(fill="x", pady=10, padx=10) # Add padding to header

# Left side: Menu button
menu_button = ttk.Button(header_frame,
                         text="", # Text will be icon
                         style="Menu.TButton",
                         command=lambda: toggle_side_menu())
menu_button.pack(side="left", padx=5)
# Using a label for the actual icon to allow better sizing/coloring than default button text
menu_icon_label = tk.Label(menu_button, text="\u2630", font=("Helvetica", 28), fg=COLOR_NORMAL_MENU, bg=COLOR_BACKGROUND)
menu_icon_label.pack(fill="both", expand=True)

# Right side: Cart button and badge
cart_btn = ttk.Button(header_frame,
                      text="", # Text will be icon
                      style="Menu.TButton", # Use menu button style for icon buttons
                      command=lambda: show_cart())
cart_btn.pack(side="right", padx=5)
cart_icon_label = tk.Label(cart_btn, text="\U0001F6CD", font=("Helvetica", 28), fg=COLOR_NORMAL_MENU, bg=COLOR_BACKGROUND) # Shopping cart icon
cart_icon_label.pack(fill="both", expand=True)


# Cart badge - positioned relative to the root or header frame for overlay
cart_badge = ttk.Label(header_frame,
                       textvariable=cart_items_count,
                       style="Badge.TLabel")
# Place badge initially, update_cart_badge will hide/show
cart_badge.place(relx=0.0, rely=0.0, anchor="nw") # Placeholder, will be adjusted dynamically

# Search Frame
search_frame = ttk.Frame(main_frame, padding=(10, 0, 10, 10)) # Padding adjusted
search_frame.pack(fill="x")

search_var = tk.StringVar()
search_entry = ttk.Entry(search_frame,
                         textvariable=search_var,
                         font=("Helvetica", 12),
                         width=30,
                         style="TEntry")
search_entry.pack(side="left", fill="x", expand=True)
search_entry.insert(0, "Search menu items...")
search_entry.bind("<FocusIn>", lambda e: search_entry.delete(0, 'end') if search_entry.get() == "Search menu items..." else None)
search_entry.bind("<FocusOut>", lambda e: search_entry.insert(0, "Search menu items...") if not search_entry.get() else None)
search_var.trace_add("write", lambda name, index, mode: on_search_changed())


# Menu Frame - Now uses a grid layout within the canvas
menu_container = ttk.Frame(main_frame, style="TFrame")
menu_container.pack(fill="both", expand=True, padx=10, pady=10)

menu_canvas = tk.Canvas(menu_container, bg=COLOR_BACKGROUND, highlightthickness=0)
scroll_y = ttk.Scrollbar(menu_container, orient="vertical", command=menu_canvas.yview)
menu_items_grid_frame = ttk.Frame(menu_canvas, style="TFrame") # This frame will hold the grid of items

menu_items_grid_frame.bind("<Configure>", lambda e: menu_canvas.configure(scrollregion=menu_canvas.bbox("all")))
menu_canvas.create_window((0, 0), window=menu_items_grid_frame, anchor="nw")
menu_canvas.configure(yscrollcommand=scroll_y.set)

menu_canvas.pack(side="left", fill="both", expand=True)
scroll_y.pack(side="right", fill="y")

# --- Side Menu UI ---
side_menu_width = 250
side_menu_frame.place(x=-side_menu_width, y=0, relheight=1, width=side_menu_width)

# Menu Header
tk.Label(side_menu_frame,
         text="Menu",
         bg="black",
         fg="white",
         font=("Helvetica", 24, "bold"),
         height=5).pack(fill="x", pady=(0, 10)) # Adjusted height

menu_items_list = [
    {"icon": "wallet", "title": "Budget"},
    {"icon": "person", "title": "Profile"},
    {"icon": "settings", "title": "Settings"},
    {"icon": "bell", "title": "Notifications"},
    {"icon": "logout", "title": "Logout"},
]

# Mapping common icon names to unicode characters or icon fonts (if using)
icon_map = {
    "wallet": "\U0001F4B0", # Money Bag
    "person": "\U0001F464", # Bust in Silhouette
    "settings": "\u2699\uFE0F", # Gear
    "bell": "\U0001F514", # Bell
    "logout": "\u23FB" # Power Symbol
}

def create_side_menu_item(parent, icon_name, title_text):
    frame = ttk.Frame(parent, style="TFrame")
    frame.pack(fill="x", pady=2)

    icon_char = icon_map.get(icon_name, "")
    
    # Using a Label for icon and text to control colors easily
    icon_label = tk.Label(frame, text=icon_char, font=("Helvetica", 18), bg=COLOR_CARD_BACKGROUND, fg=COLOR_NORMAL_MENU)
    icon_label.pack(side="left", padx=10, pady=5)
    
    title_label = tk.Label(frame, text=title_text, font=("Helvetica", 14), bg=COLOR_CARD_BACKGROUND, fg=COLOR_NORMAL_MENU, anchor="w")
    title_label.pack(side="left", fill="x", expand=True, padx=5)

    def on_click(event=None):
        selected_menu_item.set(title_text)
        # Handle navigation/action based on title_text
        if title_text == "Logout":
            reset_ui()
            toggle_side_menu() # Hide the menu after logout
        else:
            messagebox.showinfo("Menu Item", f"You clicked {title_text}")
        toggle_side_menu() # Close menu after selection

    frame.bind("<Button-1>", on_click)
    icon_label.bind("<Button-1>", on_click)
    title_label.bind("<Button-1>", on_click)
    
    def on_enter(event):
        frame.configure(style="Card.TFrame") # Highlight on hover
        icon_label.config(bg=style.lookup("Card.TFrame", "background"))
        title_label.config(bg=style.lookup("Card.TFrame", "background"))

    def on_leave(event):
        frame.configure(style="TFrame") # Reset on leave
        icon_label.config(bg=COLOR_CARD_BACKGROUND)
        title_label.config(bg=COLOR_CARD_BACKGROUND)

    frame.bind("<Enter>", on_enter)
    frame.bind("<Leave>", on_leave)
    icon_label.bind("<Enter>", on_enter)
    icon_label.bind("<Leave>", on_leave)
    title_label.bind("<Enter>", on_enter)
    title_label.bind("<Leave>", on_leave)

    # Update background when selected_menu_item changes
    def update_selection_style(*args):
        if selected_menu_item.get() == title_text:
            frame.configure(style="Card.TFrame") # Use card style for selected
            icon_label.config(fg=COLOR_SELECTED_MENU, bg=style.lookup("Card.TFrame", "background"))
            title_label.config(fg=COLOR_SELECTED_MENU, bg=style.lookup("Card.TFrame", "background"), font=("Helvetica", 14, "bold"))
        else:
            frame.configure(style="TFrame") # Default style
            icon_label.config(fg=COLOR_NORMAL_MENU, bg=COLOR_BACKGROUND)
            title_label.config(fg=COLOR_NORMAL_MENU, bg=COLOR_BACKGROUND, font=("Helvetica", 14, "normal"))

    selected_menu_item.trace_add("write", update_selection_style)
    update_selection_style() # Initial call

for item in menu_items_list:
    create_side_menu_item(side_menu_frame, item["icon"], item["title"])

# Overlay for when side menu is open
overlay = tk.Frame(root, bg="black", alpha=0.3) # Tkinter doesn't support alpha directly, manage with color
overlay.place_forget() # Hidden initially

def toggle_side_menu():
    if is_menu_visible.get():
        animate_side_menu_out()
    else:
        animate_side_menu_in()

def animate_side_menu_in():
    is_menu_visible.set(True)
    current_x = side_menu_frame.winfo_x()
    target_x = 0
    step = 20 # Animation speed
    
    # Show overlay
    overlay.place(x=side_menu_width, y=0, relwidth=1, relheight=1)
    overlay.lift() # Ensure it's above main_frame but below side_menu_frame
    side_menu_frame.lift() # Ensure side menu is on top

    def animate():
        nonlocal current_x
        if current_x < target_x:
            current_x = min(current_x + step, target_x)
            side_menu_frame.place(x=current_x)
            root.after(10, animate)
        else:
            side_menu_frame.place(x=target_x) # Ensure it snaps to final position

    animate()

def animate_side_menu_out():
    is_menu_visible.set(False)
    current_x = side_menu_frame.winfo_x()
    target_x = -side_menu_width
    step = 20

    def animate():
        nonlocal current_x
        if current_x > target_x:
            current_x = max(current_x - step, target_x)
            side_menu_frame.place(x=current_x)
            root.after(10, animate)
        else:
            side_menu_frame.place_forget() # Hide the menu frame
            overlay.place_forget() # Hide overlay

    animate()

# Bind overlay click to close side menu
overlay.bind("<Button-1>", lambda e: toggle_side_menu())

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
                root.after(0, lambda: messagebox.showerror("Error", "Token not received."))
        else:
            root.after(0, lambda: messagebox.showerror("Authentication Failed", res.json().get("message", "Invalid RFID")))
    except requests.exceptions.ConnectionError:
        root.after(0, lambda: messagebox.showerror("Network Error", "Could not connect to the API server. Please check the network connection and server status."))
    except Exception as e:
        root.after(0, lambda: messagebox.showerror("Error", f"An unexpected error occurred during authentication: {str(e)}"))

def get_customer_data(rfid):
    global customer_data, jwt_token
    # Use the /customer/profile/rfid/{id} endpoint
    headers = {"Authorization": f"Bearer {jwt_token}"} if jwt_token else {}
    try:
        res = requests.get(f"{PROFILE_URL}customer/profile/rfid/{rfid}", headers=headers)
        if res.status_code == 200:
            customer_data = res.json()
            def update_ui():
                user_label.config(text=f"Hi, {customer_data['username']}")
                show_main()
            root.after(0, update_ui)
        elif res.status_code == 401:
            root.after(0, lambda: messagebox.showerror("Unauthorized", "Your session has expired or you are not authorized. Please re-authenticate."))
            reset_ui() # Reset UI on unauthorized
        else:
            root.after(0, lambda: messagebox.showerror("Error", f"Failed to fetch user data: {res.json().get('message', 'Unknown error')}"))
    except requests.exceptions.ConnectionError:
        root.after(0, lambda: messagebox.showerror("Network Error", "Could not connect to the API server. Please check the network connection and server status."))
    except Exception as e:
        root.after(0, lambda: messagebox.showerror("Error", f"An unexpected error occurred while fetching customer data: {str(e)}"))

def rfid_loop():
    while True:
        try:
            # Check if main_frame is visible. If so, user is already logged in, no need to read RFID.
            if main_frame.winfo_ismapped():
                time.sleep(2) # Sleep longer if already logged in to avoid constant reads
                continue

            id, text = reader.read()
            rfid_text = str(id).strip() # Using the ID as cardID, assuming it's unique
            if rfid_text:
                print(f"Read RFID card ID: {rfid_text}")
                authenticate_rfid(rfid_text)
            time.sleep(2)
        except Exception as e:
            print("RFID error (expected if no card present):", e)
            time.sleep(1)
        
def fetch_menu():
    global all_menu_items, filtered_menu_items
    try:
        res = requests.get(MENU_URL)
        if res.status_code == 200:
            all_menu_items = res.json()
            filtered_menu_items = list(all_menu_items) # Initialize filtered with all items
            root.after(0, build_menu) # Update UI on the main thread
        else:
            root.after(0, lambda: messagebox.showerror("Error", "Failed to load menu: " + res.text))
    except requests.exceptions.ConnectionError:
        root.after(0, lambda: messagebox.showerror("Network Error", "Could not connect to the menu API. Please check the network connection and server status."))
    except Exception as e:
        root.after(0, lambda: messagebox.showerror("Network Error", str(e)))

# Image cache to prevent repetitive loading
image_cache = {}

def load_image(image_path, size=(80, 80)):
    if image_path not in image_cache:
        try:
            response = requests.get(UPLOAD_BASE_URL + image_path, stream=True, timeout=5)
            response.raise_for_status() # Raise an exception for bad status codes
            image_data = response.content
            img = Image.open(io.BytesIO(image_data))
            img = img.resize(size, Image.Resampling.LANCZOS)
            photo = ImageTk.PhotoImage(img)
            image_cache[image_path] = photo
        except requests.exceptions.RequestException as e:
            print(f"Error loading image from {UPLOAD_BASE_URL + image_path}: {e}")
            # Load a placeholder image if fetching fails
            img = Image.open("placeholder.png") # Make sure you have a placeholder.png in your script directory
            img = img.resize(size, Image.Resampling.LANCZOS)
            photo = ImageTk.PhotoImage(img)
            image_cache[image_path] = photo # Cache placeholder too
        except Exception as e:
            print(f"General error processing image {image_path}: {e}")
            img = Image.open("placeholder.png")
            img = img.resize(size, Image.Resampling.LANCZOS)
            photo = ImageTk.PhotoImage(img)
            image_cache[image_path] = photo
    return image_cache[image_path]

def build_menu():
    for widget in menu_items_grid_frame.winfo_children():
        widget.destroy()

    # Group items by category for display
    categories = {}
    for item in filtered_menu_items:
        category = item.get("category", "Uncategorized")
        if category not in categories:
            categories[category] = []
        categories[category].append(item)
    
    current_row = 0
    for category_name, items_in_category in categories.items():
        # Category header
        ttk.Label(menu_items_grid_frame,
                  text=category_name,
                  style="Title.TLabel").grid(row=current_row, column=0, columnspan=2, sticky="w", pady=(20, 10), padx=10)
        current_row += 1

        # Display items in a grid for the current category
        col_idx = 0
        for item in items_in_category:
            card_frame = ttk.Frame(menu_items_grid_frame, style="MenuItem.TFrame", padding=10)
            card_frame.grid(row=current_row, column=col_idx, padx=10, pady=10, sticky="nsew")
            
            # Make columns expandable to fit content
            menu_items_grid_frame.grid_columnconfigure(col_idx, weight=1)

            # Image
            if item.get("imagePath"):
                try:
                    # Threading for image loading to prevent UI freeze
                    img_thread = threading.Thread(target=lambda i=item: _load_item_image_and_update_ui(i, card_frame))
                    img_thread.daemon = True
                    img_thread.start()
                except Exception as e:
                    print(f"Error starting image load thread: {e}")
                    # Fallback if thread fails or image is not immediately available
                    tk.Label(card_frame, text="No Image", width=10, height=5, bg="#e0e0e0").pack(pady=5)
            else:
                tk.Label(card_frame, text="No Image", width=10, height=5, bg="#e0e0e0").pack(pady=5)

            # Item Name
            name_label = ttk.Label(card_frame,
                                   text=item["name"],
                                   style="Item.TLabel",
                                   wraplength=120)
            name_label.pack(pady=5)

            # Item Price
            price_label = ttk.Label(card_frame,
                                    text=f"Rs. {item['price']:.2f}",
                                    style="Price.TLabel")
            price_label.pack()

            # Add/Remove icon (mimics Flutter's check_circle/add_circle_outline)
            add_remove_icon = tk.Label(card_frame, text="", font=("Helvetica", 24), bg=COLOR_CARD_BACKGROUND)
            add_remove_icon.pack(pady=5)

            # Update initial icon state
            _update_add_remove_icon(add_remove_icon, item["id"])
            
            # Bind click to the entire card to toggle cart
            card_frame.bind("<Button-1>", lambda e, i=item: toggle_item_in_cart(i, add_remove_icon))
            name_label.bind("<Button-1>", lambda e, i=item: toggle_item_in_cart(i, add_remove_icon))
            price_label.bind("<Button-1>", lambda e, i=item: toggle_item_in_cart(i, add_remove_icon))
            add_remove_icon.bind("<Button-1>", lambda e, i=item: toggle_item_in_cart(i, add_remove_icon))

            col_idx += 1
            if col_idx >= 2: # Two items per row for a cleaner grid appearance
                col_idx = 0
                current_row += 1
        
        # If the last row wasn't full, increment current_row to ensure next category starts on a new line
        if col_idx != 0:
            current_row += 1

    menu_canvas.update_idletasks() # Ensure scrollregion updates

def _load_item_image_and_update_ui(item, card_frame):
    try:
        photo = load_image(item["imagePath"])
        img_label = tk.Label(card_frame, image=photo, bg=COLOR_CARD_BACKGROUND)
        img_label.image = photo # Keep a reference to prevent garbage collection
        # Replace "No Image" label if it exists, or insert at a specific position
        current_labels = [w for w in card_frame.winfo_children() if isinstance(w, tk.Label) and w.cget("text") == "No Image"]
        if current_labels:
            current_labels[0].destroy() # Destroy the placeholder
        img_label.pack(side="top", pady=5) # Pack the image at the top
    except Exception as e:
        print(f"Failed to display image for {item['name']}: {e}")
        # Ensure a "No Image" placeholder is visible if something goes wrong after initial pack
        tk.Label(card_frame, text="No Image", width=10, height=5, bg="#e0e0e0").pack(pady=5)

def _update_add_remove_icon(icon_label, item_id):
    if item_id in selected_items:
        icon_label.config(text="\u2705", fg="green") # Checkmark
    else:
        icon_label.config(text="\u2795", fg="grey") # Plus sign

def toggle_item_in_cart(item, icon_label):
    if item["id"] in selected_items:
        del selected_items[item["id"]]
    else:
        selected_items[item["id"]] = 1 # Always add 1 for simple toggle
    
    _update_add_remove_icon(icon_label, item["id"])
    cart_items_count.set(len(selected_items))
    update_cart_badge()

def on_search_changed():
    query = search_var.get().strip().lower()
    global filtered_menu_items

    if query == "" or query == "search menu items...":
        filtered_menu_items = list(all_menu_items)
    else:
        filtered_menu_items = [item for item in all_menu_items if query in item["name"].lower()]
    
    build_menu() # Rebuild the menu with filtered items

def update_cart_badge():
    count = cart_items_count.get()
    if count > 0:
        cart_badge.configure(text=str(count))
        # Dynamically position the badge relative to the cart button
        # This is tricky with pack/place. Let's assume a fixed position for simplicity
        # Or calculate relative to cart_btn's actual position if needed
        # For now, let's place it slightly offset from the cart button area
        cart_badge.place(relx=1.0, rely=0.0, anchor="ne", x=-10, y=5) # Fixed relative to header_frame
    else:
        cart_badge.place_forget()

def show_cart():
    global cart_frame
    if cart_frame and cart_frame.winfo_exists():
        cart_frame.lift() # Bring to front if already open
        return
        
    cart_frame = tk.Toplevel(root)
    cart_frame.title("Your Cart")
    cart_frame.geometry("400x500")
    cart_frame.configure(bg=COLOR_BACKGROUND)
    cart_frame.grab_set() # Make it modal

    # Header
    ttk.Label(cart_frame,
              text="Your Cart",
              style="Header.TLabel").pack(fill="x")
    
    # Cart items
    cart_container = ttk.Frame(cart_frame, style="TFrame")
    cart_container.pack(fill="both", expand=True, padx=20, pady=10)
    
    if not selected_items:
        ttk.Label(cart_container,
                  text="Your cart is empty!",
                  font=("Helvetica", 14),
                  foreground="#666666",
                  background=COLOR_BACKGROUND).pack(expand=True)
    else:
        canvas = tk.Canvas(cart_container, bg=COLOR_BACKGROUND, highlightthickness=0)
        scroll_y = ttk.Scrollbar(cart_container, orient="vertical", command=canvas.yview)
        items_frame = ttk.Frame(canvas, style="TFrame")
        
        items_frame.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((0, 0), window=items_frame, anchor="nw")
        canvas.configure(yscrollcommand=scroll_y.set)
        
        canvas.pack(side="left", fill="both", expand=True)
        scroll_y.pack(side="right", fill="y")
        
        total = 0.0
        for item_id, quantity in selected_items.items():
            item = next((i for i in all_menu_items if i["id"] == item_id), None)
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
            
            # Quantity controls in cart
            qty_frame_cart = ttk.Frame(card, style="TFrame")
            qty_frame_cart.grid(row=0, column=1, rowspan=2, padx=10)

            def decrement_cart(qv_id=item_id):
                current_qty = selected_items.get(qv_id, 0)
                if current_qty > 1:
                    selected_items[qv_id] = current_qty - 1
                else:
                    del selected_items[qv_id] # Remove if quantity becomes 0
                cart_items_count.set(len(selected_items))
                update_cart_badge()
                show_cart() # Refresh cart display

            def increment_cart(qv_id=item_id):
                selected_items[qv_id] = selected_items.get(qv_id, 0) + 1
                cart_items_count.set(len(selected_items))
                update_cart_badge()
                show_cart() # Refresh cart display

            qty_lbl_cart = tk.Label(qty_frame_cart, text=str(quantity), width=3, bg=COLOR_CARD_BACKGROUND)
            qty_lbl_cart.pack(side="left", padx=5)
            
            ttk.Button(qty_frame_cart, text="-", width=2, command=decrement_cart).pack(side="left")
            ttk.Button(qty_frame_cart, text="+", width=2, command=increment_cart).pack(side="left")


    # Footer
    footer = ttk.Frame(cart_frame, padding=20, style="TFrame")
    footer.pack(fill="x", side="bottom")
    
    ttk.Label(footer,
              text=f"Total: Rs. {total:.2f}",
              font=("Helvetica", 14, "bold"),
              background=COLOR_BACKGROUND).pack(side="left")
    
    ttk.Button(footer,
               text="Place Order",
               style="TButton",
               command=lambda: submit_order(cart_frame)).pack(side="right")
    
    ttk.Button(footer,
               text="Clear All",
               command=clear_cart,
               style="TButton").pack(side="right", padx=10) # Using TButton style for consistency

def clear_cart():
    selected_items.clear()
    cart_items_count.set(0)
    update_cart_badge()
    # Rebuild the main menu to reset item quantities/icons
    build_menu()
    if cart_frame and cart_frame.winfo_exists():
        cart_frame.destroy()
    messagebox.showinfo("Cart Cleared", "Your cart has been emptied.")

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
        messagebox.showerror("Error", "Customer email not found. Please re-authenticate.")
        return

    order_items_payload = []
    for item_id, quantity in selected_items.items():
        order_items_payload.append({"menuItemId": item_id, "quantity": quantity})

    payload = {
        "email": email,
        "items": order_items_payload, # Use the list of objects for "items"
        "scheduledTime": None
    }

    headers = {"Authorization": f"Bearer {jwt_token}", "Content-Type": "application/json"}
    try:
        res = requests.post(ORDER_URL, json=payload, headers=headers)
        print(f"Order Response [{res.status_code}]: {res.text}")
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
            reset_ui()
        else:
            messagebox.showerror("Error", f"Order failed: {res.status_code} - {res.text}")
    except requests.exceptions.ConnectionError:
        messagebox.showerror("Network Error", "Could not connect to the order API. Please check the network connection and server status.")
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
    except requests.exceptions.ConnectionError:
        print("[Biometric] Could not connect to the biometric API server.")
    except Exception as e:
        print("Biometric call failed:", e)

def show_main():
    welcome_frame.pack_forget()
    main_frame.pack(fill="both", expand=True)
    fetch_menu()
    update_cart_badge() # Ensure badge is updated on login

def reset_ui():
    global jwt_token
    jwt_token = None
    selected_items.clear()
    cart_items_count.set(0)
    update_cart_badge()
    main_frame.pack_forget()
    welcome_frame.pack(expand=True, fill="both")
    user_label.config(text="Hi, Guest")
    # Also reset search bar and filtered menu
    search_var.set("Search menu items...")
    global filtered_menu_items
    filtered_menu_items = []
    build_menu() # Clear the displayed menu items


# User label in the header (defined late but used early, so moved down)
user_label = ttk.Label(header_frame,
                       text="Hi, Guest",
                       style="Header.TLabel")
user_label.pack(side="left", padx=20)


# Create a dummy placeholder.png if it doesn't exist for image errors
if not os.path.exists("placeholder.png"):
    try:
        from PIL import Image, ImageDraw, ImageFont
        img = Image.new('RGB', (80, 80), color = (200, 200, 200)) # Grey background
        d = ImageDraw.Draw(img)
        try:
            # Try to load a default font
            font = ImageFont.truetype("arial.ttf", 10)
        except IOError:
            font = ImageFont.load_default()
        d.text((10,30), "No Image", fill=(100,100,100), font=font)
        img.save("placeholder.png")
        print("Created placeholder.png for missing images.")
    except ImportError:
        print("Pillow not fully installed, could not create placeholder.png. Please install with 'pip install Pillow'.")
    except Exception as e:
        print(f"Could not create placeholder.png: {e}")


# Start the RFID reading loop in a background thread
threading.Thread(target=rfid_loop, daemon=True).start()

try:
    root.mainloop()
finally:
    GPIO.cleanup()