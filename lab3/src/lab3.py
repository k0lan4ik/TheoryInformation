import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import os

def is_prime(num):
    if num < 2: return False
    for i in range(2, int(num**0.5) + 1):
        if num % i == 0: return False
    return True

def extended_gcd(a, b):
    if a == 0:
        return b, 0, 1
    gcd, x1, y1 = extended_gcd(b % a, a)
    x = y1 - (b // a) * x1
    y = x1
    return gcd, x, y

def mod_inverse(e, phi):
    gcd, x, y = extended_gcd(e, phi)
    if gcd != 1:
        raise ValueError("Числа не взаимно простые")
    return x % phi

def fast_pow(base, exp, mod):
    res = 1
    base = base % mod
    while exp > 0:
        if exp % 2 == 1:
            res = (res * base) % mod
        base = (base * base) % mod
        exp >>= 1
    return res

class RSAApp:
    def __init__(self, root):
        self.root = root
        self.root.title("RSA Шифрование (Коля)")
        self.root.geometry("650x700")
        
        self.n = None
        self.phi = None
        self.e = None
        self.d = None
        
        self.create_widgets()

    def create_widgets(self):
        # Frame 1: Ввод p и q 
        frame_input = tk.LabelFrame(self.root, text="1. Генерация модуля (только для создания новых ключей)", padx=10, pady=10)
        frame_input.pack(fill="x", padx=10, pady=5)
        
        tk.Label(frame_input, text="p (простое):").grid(row=0, column=0, sticky="e")
        self.entry_p = tk.Entry(frame_input, width=12)
        self.entry_p.grid(row=0, column=1, padx=5)
        
        tk.Label(frame_input, text="q (простое):").grid(row=0, column=2, sticky="e")
        self.entry_q = tk.Entry(frame_input, width=12)
        self.entry_q.grid(row=0, column=3, padx=5)
        
        tk.Button(frame_input, text="Рассчитать N и Ф(N)", command=self.calc_module).grid(row=0, column=4, padx=10)
        
        self.lbl_module_info = tk.Label(frame_input, text="N = ? | Ф(N) = ?", fg="blue")
        self.lbl_module_info.grid(row=1, column=0, columnspan=5, pady=5)
        
        # Frame 2: Выбор ключа e
        frame_keys = tk.LabelFrame(self.root, text="2. Выбор ключей", padx=10, pady=10)
        frame_keys.pack(fill="x", padx=10, pady=5)
        
        tk.Label(frame_keys, text="Выберите открытый ключ (e):").grid(row=0, column=0, sticky="w")
        self.combo_e = ttk.Combobox(frame_keys, width=15, state="disabled")
        self.combo_e.grid(row=0, column=1, padx=5)
        
        tk.Button(frame_keys, text="Вычислить закрытый (d)", command=self.calc_keys).grid(row=0, column=2, padx=10)
        
        # Frame 3: Файловые операции
        frame_files = tk.LabelFrame(self.root, text="3. Файловые операции (можно ввести готовые ключи вручную)", padx=10, pady=10)
        frame_files.pack(fill="x", padx=10, pady=5)
        
        tk.Label(frame_files, text="Модуль (N):").grid(row=0, column=0, sticky="e")
        self.entry_n_manual = tk.Entry(frame_files, width=12)
        self.entry_n_manual.grid(row=0, column=1, padx=5)
        
        tk.Label(frame_files, text="Открытый ключ (e):").grid(row=0, column=2, sticky="e")
        self.entry_e_manual = tk.Entry(frame_files, width=12)
        self.entry_e_manual.grid(row=0, column=3, padx=5)
        
        tk.Label(frame_files, text="Закрытый ключ (d):").grid(row=0, column=4, sticky="e")
        self.entry_d_manual = tk.Entry(frame_files, width=12)
        self.entry_d_manual.grid(row=0, column=5, padx=5)

        tk.Button(frame_files, text="Зашифровать файл...", command=self.encrypt_file, width=22).grid(row=1, column=0, columnspan=3, pady=10)
        tk.Button(frame_files, text="Расшифровать файл...", command=self.decrypt_file, width=22).grid(row=1, column=3, columnspan=3, pady=10)

        # Frame 4: Логи
        frame_logs = tk.LabelFrame(self.root, text="Вывод блоков (в 10-й системе, первые 1000 шт.)", padx=10, pady=10)
        frame_logs.pack(fill="both", expand=True, padx=10, pady=5)
        
        self.text_logs = tk.Text(frame_logs, wrap="word", height=10)
        self.text_logs.pack(fill="both", expand=True)
        
        scrollbar = ttk.Scrollbar(self.text_logs, command=self.text_logs.yview)
        scrollbar.pack(side="right", fill="y")
        self.text_logs.config(yscrollcommand=scrollbar.set)

    def log(self, message):
        self.text_logs.insert(tk.END, message + "\n")
        self.text_logs.see(tk.END)

    def calc_module(self):
        try:
            p = int(self.entry_p.get())
            q = int(self.entry_q.get())
        except ValueError:
            messagebox.showerror("Ошибка", "p и q должны быть целыми числами.")
            return

        if not (is_prime(p) and is_prime(q)):
            messagebox.showerror("Ошибка", "Оба числа p и q должны быть простыми!")
            return
            
        if p == q:
            messagebox.showerror("Ошибка", "Числа p и q должны быть различными по правилам RSA!")
            return
            
        n = p * q
        if not (n <= 65535):
            messagebox.showerror("Ошибка", f"Модуль N={n}. Он должен не превышать 65535 (2 байта).")
            return
            
        self.n = n
        self.phi = (p - 1) * (q - 1)
        self.lbl_module_info.config(text=f"N = {self.n} (Размер: 2 байта) | Ф(N) = {self.phi}")
        
        self.log(f"Генерация возможных открытых ключей e для Ф(N)={self.phi}...")
        self.root.update()
        
        valid_e = []
        for i in range(2, self.phi):
            gcd_val, _, _ = extended_gcd(i, self.phi)
            if gcd_val == 1:
                valid_e.append(str(i))
                
        self.combo_e.config(values=valid_e, state="readonly")
        if valid_e:
            self.combo_e.current(0)
        self.log(f"Найдено {len(valid_e)} возможных значений для ключа.")
        messagebox.showinfo("Успех", "Модуль рассчитан. Выберите открытый ключ из списка.")

    def calc_keys(self):
        if not self.phi:
            messagebox.showerror("Ошибка", "Сначала рассчитайте модуль N.")
            return
            
        selected_e = self.combo_e.get()
        if not selected_e:
            messagebox.showerror("Ошибка", "Выберите открытый ключ (e) из списка.")
            return
            
        self.e = int(selected_e)
        self.d = mod_inverse(self.e, self.phi)
        self.log(f"Ключи установлены! Открытый(e)={self.e}, Закрытый(d)={self.d}")
        
        self.entry_n_manual.delete(0, tk.END)
        self.entry_n_manual.insert(0, str(self.n))
        self.entry_e_manual.delete(0, tk.END)
        self.entry_e_manual.insert(0, str(self.e))
        self.entry_d_manual.delete(0, tk.END)
        self.entry_d_manual.insert(0, str(self.d))

    def encrypt_file(self):
        try:
            current_n = int(self.entry_n_manual.get())
            current_e = int(self.entry_e_manual.get())
        except ValueError:
            messagebox.showerror("Ошибка", "Модуль (N) и Открытый ключ (e) должны быть целыми числами!")
            return
            
        # Проверки на границы (вместимость в 2 байта)
        if not (current_n <= 65535):
            messagebox.showerror("Ошибка", "Модуль (N) должен не превышать 65535 (2 байта).")
            return
        if not (1 < current_e <= 65535):
            messagebox.showerror("Ошибка", "Открытый ключ (e) должен быть больше 1 и не превышать 65535 (2 байта).")
            return
            
        filepath = filedialog.askopenfilename(title="Выберите файл для шифрования")
        if not filepath:
            return
            
        enc_filepath = filepath + ".enc"
        
        self.log(f"\n--- Начало шифрования: {os.path.basename(filepath)} ---")
        self.text_logs.insert(tk.END, "Зашифрованные блоки: ")
        
        blocks_processed = 0
        try:
            with open(filepath, "rb") as fin, open(enc_filepath, "wb") as fout:
                while True:
                    byte = fin.read(1)
                    if not byte:
                        break
                    
                    m = int.from_bytes(byte, byteorder='big', signed=False)
                    c = fast_pow(m, current_e, current_n)
                    
                    fout.write(c.to_bytes(2, byteorder='big', signed=False))
                    
                    if blocks_processed < 1000:
                        self.text_logs.insert(tk.END, f"{c} ")
                    elif blocks_processed == 1000:
                        self.text_logs.insert(tk.END, "\n... [вывод скрыт для ускорения работы] ")
                        
                    blocks_processed += 1
                    
            self.log(f"\nШифрование завершено. Обработано байт: {blocks_processed}. Сохранено в: {enc_filepath}")
            messagebox.showinfo("Успех", "Файл успешно зашифрован открытым ключом!")
        except Exception as ex:
            messagebox.showerror("Ошибка", str(ex))

    def decrypt_file(self):
        try:
            current_n = int(self.entry_n_manual.get())
            current_d = int(self.entry_d_manual.get())
        except ValueError:
            messagebox.showerror("Ошибка", "Модуль (N) и Закрытый ключ (d) должны быть целыми числами!")
            return
            
        # Проверки на границы (вместимость в 2 байта)
        if not (current_n <= 65535):
            messagebox.showerror("Ошибка", "Модуль (N) должен не превышать 65535 (2 байта).")
            return
        if not (1 < current_d <= 65535):
            messagebox.showerror("Ошибка", "Закрытый ключ (d) должен быть больше 1 и не превышать 65535 (2 байта).")
            return
            
        filepath = filedialog.askopenfilename(title="Выберите .enc файл для расшифровки")
        if not filepath:
            return
            
        base_name = os.path.basename(filepath)
        if base_name.endswith('.enc'):
            dec_name = "dec_" + base_name[:-4]
        else:
            dec_name = "dec_" + base_name
            
        dec_filepath = os.path.join(os.path.dirname(filepath), dec_name)
        
        self.log(f"\n--- Начало дешифрования: {base_name} ---")
        self.text_logs.insert(tk.END, "Расшифрованные байты (в 10-й системе): ")
        
        blocks_processed = 0
        try:
            with open(filepath, "rb") as fin, open(dec_filepath, "wb") as fout:
                while True:
                    bytes_block = fin.read(2)
                    if len(bytes_block) < 2:
                        break
                        
                    c = int.from_bytes(bytes_block, byteorder='big', signed=False)
                    m = fast_pow(c, current_d, current_n)
                    
                    if m > 255:
                        raise ValueError(f"Расшифрованный байт равен {m}. Такое происходит, если введен неверный ключ или файл поврежден.")

                    fout.write(m.to_bytes(1, byteorder='big', signed=False))
                    
                    if blocks_processed < 1000:
                        self.text_logs.insert(tk.END, f"{m} ")
                    elif blocks_processed == 1000:
                        self.text_logs.insert(tk.END, "\n... [вывод скрыт для ускорения работы] ")
                        
                    blocks_processed += 1
                    
            self.log(f"\nДешифрование завершено. Обработано блоков: {blocks_processed}. Сохранено в: {dec_filepath}")
            messagebox.showinfo("Успех", "Файл успешно расшифрован закрытым ключом!")
        except Exception as ex:
            if os.path.exists(dec_filepath):
                os.remove(dec_filepath)
            messagebox.showerror("Ошибка дешифрования", str(ex))

if __name__ == "__main__":
    root = tk.Tk()
    app = RSAApp(root)
    root.mainloop()