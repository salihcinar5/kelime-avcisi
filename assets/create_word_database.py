import os
import sqlite3

# Veritabanı dosyasının tam yolunu belirleyin
db_path = os.path.join(os.getcwd(), 'word_database.db')

# Veritabanı bağlantısı oluştur
conn = sqlite3.connect(db_path)
c = conn.cursor()

# Kelime tablosunu oluştur
c.execute('''
    CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL
    )
''')

# Kelime listesini oku ve filtrele
with open('turkce_kelime_listesi.txt', 'r', encoding='utf-8') as file:
    for line in file:
        word = line.strip()
        if 4 <= len(word) <= 6 and ' ' not in word and '-' not in word:
            c.execute('INSERT INTO words (word) VALUES (?)', (word,))
            print(f"Kelime eklendi: {word}")

# Değişiklikleri kaydet ve bağlantıyı kapat
conn.commit()
conn.close()
