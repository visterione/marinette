import csv
import json

# Укажите путь к вашему CSV-файлу
csv_file = 'C:\\Users\\stece\\Downloads\\pl.csv'
json_file = 'pl.json'

# Создаём словарь для хранения ключей и текстов
data = {}

# Читаем CSV и наполняем словарь
with open(csv_file, 'r', encoding='utf-8') as file:
    reader = csv.reader(file)
    for row in reader:
        key, text = row
        data[key] = text

# Сохраняем данные в JSON
with open(json_file, 'w', encoding='utf-8') as file:
    json.dump(data, file, ensure_ascii=False, indent=2)

print(f'JSON успешно создан: {json_file}')
