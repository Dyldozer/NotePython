import tkinter as tk
from tkinter import font


class ResponsiveApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.window_font_size = 10
        self.title("NotesAHK PyShell")
        self.minsize(width=200, height=300)

        self.grid_rowconfigure(0, weight=1)

        button = tk.Button(self, text=f"Networking")
        button.grid(row=0, column=0, sticky="nsew", padx=5, pady=5)

        button = tk.Button(self, text=f"Commands")
        button.grid(row=0, column=0, sticky="nsew", padx=5, pady=5)

        button = tk.Button(self, text=f"Templates")
        button.grid(row=0, column=1, sticky="nsew", padx=5, pady=5)

        button = tk.Button(self, text=f"Settings")
        button.grid(row=0, column=1, sticky="nsew", padx=5, pady=5)

        for i in range(6):
            self.grid_rowconfigure(i + 1, weight=1)

        self.grid_columnconfigure(0, weight=5)
        self.grid_columnconfigure(1, weight=1)

        self.grid_rowconfigure(6, weight=200)
        self.grid_rowconfigure(7, weight=200)

        self.fields = []
        self.buttons = []
        for i in range(4):
            field = tk.Entry(self)
            field.grid(row=i + 1, column=0, sticky="nsew", padx=5, pady=5)
            self.fields.append(field)
            field.bind("<KeyRelease>", self.on_key_release)

        button = tk.Button(self, text=f"Copy Appbar", command=lambda i=i: self.on_button_click(f"Button {i + 1}"))
        button.grid(row=1, column=1, sticky="nsew", padx=5, pady=5)
        self.buttons.append(button)

        button = tk.Button(self, text=f"Open ACSR", command=lambda i=i: self.on_button_click(f"Button {i + 1}"))
        button.grid(row=2, column=1, sticky="nsew", padx=5, pady=5)
        self.buttons.append(button)

        button = tk.Button(self, text=f"Open SAT", command=lambda i=i: self.on_button_click(f"Button {i + 1}"))
        button.grid(row=3, column=1, sticky="nsew", padx=5, pady=5)
        self.buttons.append(button)

        button = tk.Button(self, text=f"Paste Notes", command=lambda i=i: self.on_button_click(f"Button {i + 1}"))
        button.grid(row=4, column=1, sticky="nsew", padx=5, pady=5)
        self.buttons.append(button)

        self.large_field1 = tk.Text(self, wrap="word")
        self.large_field1.grid(row=6, column=0, columnspan=2, sticky="nsew", padx=5, pady=5)

        self.large_field2 = tk.Text(self, wrap="word")
        self.large_field2.grid(row=7, column=0, columnspan=2, sticky="nsew", padx=5, pady=5)

        self.bind("<Configure>", self._resize_fonts)

    def on_button_click(self, button_id):
        print(f"{self.winfo_width()} width!")
        print(f"{self.winfo_height()} height!")

    def _resize_fonts(self, event):
        scale_factor = min(self.winfo_width() / 200, self.winfo_height() / 400)
        self.window_font_size = max(int(10 * scale_factor), 8)

        font_config = font.Font(size=self.window_font_size)
        for field in self.fields:
            field.configure(font=font_config)

        for button in self.buttons:
            button.configure(font=font_config)

        self.large_field1.configure(font=font_config)
        self.large_field2.configure(font=font_config)

        for field in self.fields:
            self.adjust_font_size_to_fit(field)

    def on_key_release(self, event):
        for field in self.fields:
            self.adjust_font_size_to_fit(field)

    def adjust_font_size_to_fit(self, field):
        text = field.get()
        if text:
            temp_font = font.Font(font=field.cget("font"))
            temp_font.configure(size=self.window_font_size)
            text_width = temp_font.measure(text)

            if text_width > field.winfo_width():
                while text_width > field.winfo_width() and temp_font.cget("size") > 8:
                    temp_font.configure(size=temp_font.cget("size") - 1)
                    text_width = temp_font.measure(text)

            field.configure(font=temp_font)


if __name__ == "__main__":
    app = ResponsiveApp()
    app.geometry("300x600")
    app.mainloop()
