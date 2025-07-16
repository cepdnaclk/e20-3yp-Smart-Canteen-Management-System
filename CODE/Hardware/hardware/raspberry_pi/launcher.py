import tkinter as tk
from tkinter import ttk, messagebox
import subprocess
import os
import time
import threading

# --- Color Palette ---
BACKGROUND_COLOR = "#E9D9F4"  # Light lavender
PRIMARY_ACCENT = "#6A1B9A"    # Deep purple
SECONDARY_ACCENT = "#AB47BC"  # Medium purple
TEXT_COLOR = "#2E2E2E"        # Dark gray
SUCCESS_COLOR = "#4CAF50"     # Green
ERROR_COLOR = "#D32F2F"       # Red
NEUTRAL_BG = "#F5F5F5"       # Light gray

# --- Virtual Environment Python Path ---
VENV_PYTHON = "/home/p1/mfrc522-env/bin/python3"

# --- Tkinter GUI ---
class LauncherGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Smart Canteen - Launcher")
        self.root.geometry("400x300")
        self.root.configure(bg=BACKGROUND_COLOR)
        self.root.resizable(False, False)

        # Style configuration
        style = ttk.Style()
        style.theme_use('clam')
        style.configure('Custom.TButton', background=PRIMARY_ACCENT, foreground='#FFFFFF', font=('Arial', 12, 'bold'), padding=10)
        style.map('Custom.TButton', background=[('active', SECONDARY_ACCENT)], foreground=[('active', '#FFFFFF')])
        style.configure('Custom.TProgressbar', troughcolor=BACKGROUND_COLOR, background=SUCCESS_COLOR, bordercolor=PRIMARY_ACCENT)
        style.layout('Custom.TProgressbar', [
            ('Horizontal.Progressbar.trough', {
                'children': [('Horizontal.Progressbar.pbar', {'side': 'left', 'sticky': 'ns'})],
                'sticky': 'nswe'
            })
        ])

        # Main frame
        self.main_frame = tk.Frame(self.root, bg=BACKGROUND_COLOR)
        self.main_frame.pack(expand=True, fill='both', padx=20, pady=20)

        # Welcome label
        self.welcome_label = tk.Label(self.main_frame, text="??? Welcome to Smart Canteen", fg=PRIMARY_ACCENT, bg=BACKGROUND_COLOR,
                                      font=('Noto Color Emoji', 20, 'bold'), wraplength=350, justify="center")
        self.welcome_label.pack(pady=20)

        # Buttons frame
        self.buttons_frame = tk.Frame(self.main_frame, bg=BACKGROUND_COLOR)
        self.buttons_frame.pack(pady=20)

        # Registration button
        self.reg_button = ttk.Button(self.buttons_frame, text="?? Registration", command=self.launch_registration, style='Custom.TButton')
        self.reg_button.pack(pady=10)
        self._add_tooltip(self.reg_button, "Enroll RFID and fingerprint")

        # Shopping button
        self.shop_button = ttk.Button(self.buttons_frame, text="?? Shopping", command=self.launch_shopping, style='Custom.TButton')
        self.shop_button.pack(pady=10)
        self._add_tooltip(self.shop_button, "Place an order")

        # Progress bar
        self.progress_bar = ttk.Progressbar(self.main_frame, style='Custom.TProgressbar', mode='indeterminate', length=200)

    def _add_tooltip(self, widget, text):
        class Tooltip:
            def __init__(self, widget, text):
                self.widget = widget
                self.text = text
                self.tip_window = None
                self.widget.bind("<Enter>", self.show_tip)
                self.widget.bind("<Leave>", self.hide_tip)

            def show_tip(self, event=None):
                if self.tip_window or not self.text:
                    return
                x, y, _, _ = self.widget.bbox("insert") or (0, 0, 0, 0)
                x += self.widget.winfo_rootx() + 25
                y += self.widget.winfo_rooty() + 25
                self.tip_window = tw = tk.Toplevel(self.widget)
                tw.wm_overrideredirect(True)
                tw.wm_geometry(f"+{x}+{y}")
                label = tk.Label(tw, text=self.text, justify='left', background=NEUTRAL_BG,
                                 foreground=TEXT_COLOR, relief='solid', borderwidth=1, font=('Arial', 10))
                label.pack()

            def hide_tip(self, event=None):
                if self.tip_window:
                    self.tip_window.destroy()
                    self.tip_window = None
        Tooltip(widget, text)

    def fade_transition(self, callback=None):
        def fade_out(alpha=1.0):
            if alpha > 0:
                self.root.attributes('-alpha', alpha)
                self.root.after(30, lambda: fade_out(alpha - 0.1))
            else:
                if callback:
                    callback()
                self.root.attributes('-alpha', 1.0)
        self.root.after(0, lambda: fade_out())

    def launch_script(self, script_name):
        self.reg_button.config(state='disabled')
        self.shop_button.config(state='disabled')
        self.progress_bar.pack(pady=10)
        self.progress_bar.start(10)
        self.welcome_label.config(text="? Launching...")

        def run_script():
            try:
                if not os.path.exists(script_name):
                    self.root.after(0, lambda: [
                        self.progress_bar.stop(),
                        self.progress_bar.pack_forget(),
                        self.reg_button.config(state='normal'),
                        self.shop_button.config(state='normal'),
                        self.welcome_label.config(text="??? Welcome to Smart Canteen"),
                        messagebox.showerror("Error", f"? {script_name} not found!", icon='error')
                    ])
                    return
                subprocess.run([VENV_PYTHON, script_name], check=True)
                self.root.after(0, lambda: [
                    self.progress_bar.stop(),
                    self.progress_bar.pack_forget(),
                    self.reg_button.config(state='normal'),
                    self.shop_button.config(state='normal'),
                    self.welcome_label.config(text="??? Welcome to Smart Canteen")
                ])
            except subprocess.CalledProcessError as e:
                self.root.after(0, lambda: [
                    self.progress_bar.stop(),
                    self.progress_bar.pack_forget(),
                    self.reg_button.config(state='normal'),
                    self.shop_button.config(state='normal'),
                    self.welcome_label.config(text="??? Welcome to Smart Canteen"),
                    messagebox.showerror("Error", f"? Failed to launch {script_name}: {e}", icon='error')
                ])

        threading.Thread(target=run_script, daemon=True).start()

    def launch_registration(self):
        self.fade_transition(lambda: self.launch_script('purple.py'))

    def launch_shopping(self):
        self.fade_transition(lambda: self.launch_script('purple_bio.py'))

# --- Main Execution ---
if __name__ == "__main__":
    root = tk.Tk()
    app = LauncherGUI(root)
    root.mainloop()
