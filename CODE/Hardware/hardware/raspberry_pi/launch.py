import tkinter as tk
import subprocess
import os
import sys
from tkinter import messagebox



def run_script(script_name):
    full_path = os.path.join(os.path.dirname(__file__), script_name)
    if os.path.exists(full_path):
        subprocess.Popen([sys.executable, full_path])
    else:
        messagebox.showerror("Error", f"{script_name} not found.")

root = tk.Tk()
root.title("Smart Canteen - Select Role")
root.geometry("400x300")
root.configure(bg="#1e1e2f")

# --- Header ---
tk.Label(root, text="Smart Canteen System", font=("Helvetica", 18, "bold"), fg="#00adb5", bg="#1e1e2f").pack(pady=30)
tk.Label(root, text="Choose your role", font=("Helvetica", 12), fg="white", bg="#1e1e2f").pack(pady=10)

# --- Buttons ---
tk.Button(root, text="REGISTRATION", width=25, height=2,
          command=lambda: run_script("bio_up.py"), bg="#00adb5", fg="white", font=("Helvetica", 10, "bold")).pack(pady=10)

tk.Button(root, text="SHOPPING", width=25, height=2,
          command=lambda: run_script("gui.py"), bg="#00adb5", fg="white", font=("Helvetica", 10, "bold")).pack(pady=10)

# --- Exit ---
tk.Button(root, text="EXIT", width=25, height=2,
          command=root.quit, bg="#ff4b5c", fg="white", font=("Helvetica", 10, "bold")).pack(pady=20)

root.mainloop()
