#!/usr/bin/env python3
"""
Генератор 1000 рецептов для RecipeApp
"""

import json
import uuid
import random

# Базовые продукты
BASIC_INGREDIENTS = {
    "яйца": {"amounts": ["1 шт", "2 шт", "3 шт", "4 шт"], "category": "basics"},
    "молоко": {"amounts": ["50 мл", "100 мл", "200 мл", "500 мл"], "category": "dairy"},
    "мука": {"amounts": ["100г", "200г", "300г", "500г"], "category": "grains"},
    "сахар": {"amounts": ["1 ст.л.", "2 ст.л.", "3 ст.л.", "100г"], "category": "basics"},
    "масло": {"amounts": ["1 ст.л.", "2 ст.л.", "50г", "100г"], "category": "oils"},
    "соль": {"amounts": ["щепотка", "по вкусу", "1 ч.л."], "category": "spices"},
    "лук": {"amounts": ["1 шт", "2 шт", "100г"], "category": "vegetables"},
    "морковь": {"amounts": ["1 шт", "2 шт", "200г"], "category": "vegetables"},
    "помидоры": {"amounts": ["1 шт", "2 шт", "3 шт", "200г"], "category": "vegetables"},
    "огурцы": {"amounts": ["1 шт", "2 шт", "3 шт", "200г"], "category": "vegetables"},
    "картофель": {"amounts": ["1 шт", "2 шт", "300г", "500г"], "category": "vegetables"},
    "рис": {"amounts": ["100г", "200г", "300г"], "category": "grains"},
    "макароны": {"amounts": ["200г", "300г", "500г"], "category": "grains"},
    "сыр": {"amounts": ["50г", "100г", "200г"], "category": "dairy"},
    "творог": {"amounts": ["100г", "200г", "300г"], "category": "dairy"},
    "перец": {"amounts": ["щепотка", "по вкусу"], "category": "spices"},
    "чеснок": {"amounts": ["1 зубчик", "2 зубчика", "3 зубчика"], "category": "vegetables"},
    "укроп": {"amounts": ["пучок", "по вкусу"], "category": "spices"},
    "петрушка": {"amounts": ["пучок", "по вкусу"], "category": "spices"},
    "сметана": {"amounts": ["50г", "100г", "200г"], "category": "dairy"},
    "курица": {"amounts": ["200г", "300г", "500г"], "category": "meat"},
    "говядина": {"amounts": ["200г", "300г", "500г"], "category": "meat"},
    "рыба": {"amounts": ["200г", "300г", "500г"], "category": "fish"},
    "капуста": {"amounts": ["200г", "300г", "500г"], "category": "vegetables"},
    "свекла": {"amounts": ["1 шт", "2 шт", "200г"], "category": "vegetables"},
    "перец болгарский": {"amounts": ["1 шт", "2 шт"], "category": "vegetables"},
    "кабачок": {"amounts": ["1 шт", "2 шт", "300г"], "category": "vegetables"},
    "баклажан": {"amounts": ["1 шт", "2 шт", "300г"], "category": "vegetables"},
    "грибы": {"amounts": ["200г", "300г", "500г"], "category": "vegetables"},
    "фасоль": {"amounts": ["200г", "300г"], "category": "vegetables"},
}

# Категории рецептов
CATEGORIES = {
    "breakfast": {
        "names": ["Омлет", "Яичница", "Блины", "Сырники", "Завтрак", "Каша", "Тост", "Бутерброд"],
        "ingredients": ["яйца", "молоко", "мука", "сыр", "творог", "масло", "сметана"],
        "time_range": (5, 30),
        "difficulty": ["easy", "medium"]
    },
    "salad": {
        "names": ["Салат", "Винегрет", "Оливье", "Цезарь", "Греческий", "Капустный"],
        "ingredients": ["помидоры", "огурцы", "лук", "морковь", "капуста", "свекла", "масло", "сметана"],
        "time_range": (10, 20),
        "difficulty": ["easy"]
    },
    "main": {
        "names": ["Плов", "Рагу", "Жаркое", "Гуляш", "Котлеты", "Тефтели", "Шашлык"],
        "ingredients": ["мясо", "курица", "картофель", "лук", "морковь", "рис", "макароны"],
        "time_range": (30, 90),
        "difficulty": ["medium", "hard"]
    },
    "soup": {
        "names": ["Борщ", "Щи", "Суп", "Рассольник", "Солянка", "Харчо"],
        "ingredients": ["картофель", "морковь", "лук", "капуста", "свекла", "мясо", "курица"],
        "time_range": (30, 60),
        "difficulty": ["medium"]
    },
    "dessert": {
        "names": ["Печенье", "Торт", "Пирог", "Кекс", "Булочка", "Пончик", "Вафли"],
        "ingredients": ["мука", "сахар", "яйца", "молоко", "масло", "творог"],
        "time_range": (20, 60),
        "difficulty": ["medium", "hard"]
    },
    "side": {
        "names": ["Гарнир", "Пюре", "Каша", "Макароны", "Рис", "Гречка"],
        "ingredients": ["картофель", "рис", "макароны", "лук", "морковь", "масло"],
        "time_range": (15, 40),
        "difficulty": ["easy", "medium"]
    }
}

# Шаблоны инструкций
INSTRUCTION_TEMPLATES = {
    "breakfast": [
        ["Подготовьте все ингредиенты", "Взбейте яйца с молоком", "Разогрейте сковороду", "Приготовьте на среднем огне"],
        ["Смешайте ингредиенты", "Замесите тесто", "Разогрейте сковороду", "Жарьте до золотистого цвета"],
        ["Подготовьте продукты", "Смешайте компоненты", "Выложите на сковороду", "Готовьте до готовности"]
    ],
    "salad": [
        ["Вымойте овощи", "Нарежьте все ингредиенты", "Смешайте в миске", "Заправьте и посолите"],
        ["Подготовьте овощи", "Нарежьте кубиками", "Добавьте заправку", "Перемешайте и подавайте"]
    ],
    "main": [
        ["Подготовьте мясо и овощи", "Обжарьте мясо", "Добавьте овощи", "Тушите до готовности"],
        ["Нарежьте ингредиенты", "Обжарьте на сковороде", "Добавьте специи", "Тушите 30-40 минут"]
    ],
    "soup": [
        ["Подготовьте овощи", "Нарежьте кубиками", "Обжарьте лук и морковь", "Добавьте в бульон", "Варите до готовности"],
        ["Вскипятите воду", "Добавьте овощи", "Варите 20 минут", "Добавьте специи", "Подавайте горячим"]
    ],
    "dessert": [
        ["Смешайте сухие ингредиенты", "Добавьте жидкие", "Замесите тесто", "Выложите на противень", "Выпекайте при 180°C"],
        ["Взбейте яйца с сахаром", "Добавьте муку", "Замесите", "Выпекайте 25-30 минут"]
    ],
    "side": [
        ["Отварите до готовности", "Обжарьте лук", "Смешайте с основным ингредиентом", "Подавайте горячим"],
        ["Подготовьте ингредиенты", "Отварите", "Добавьте масло", "Перемешайте"]
    ]
}

def generate_recipe_id():
    return str(uuid.uuid4())

def generate_ingredients(category_data, num_ingredients=None):
    """Генерирует список ингредиентов для рецепта"""
    if num_ingredients is None:
        num_ingredients = random.randint(3, 6)
    
    available = category_data["ingredients"]
    selected = random.sample(available, min(num_ingredients, len(available)))
    
    # Добавляем базовые ингредиенты
    if "масло" not in selected and random.random() > 0.3:
        selected.append("масло")
    if "соль" not in selected:
        selected.append("соль")
    
    ingredients = []
    for ing in selected:
        if ing in BASIC_INGREDIENTS:
            ing_data = BASIC_INGREDIENTS[ing]
            amount = random.choice(ing_data["amounts"])
            # Конвертируем категорию ингредиента в значения из Swift enum
            category_map = {
                "dairy": "Молочные",
                "vegetables": "Овощи",
                "fruits": "Фрукты",
                "meat": "Мясо",
                "fish": "Рыба",
                "grains": "Крупы",
                "spices": "Специи",
                "oils": "Масла",
                "basics": "Базовые",
                "other": "Другое"
            }
            category_swift = category_map.get(ing_data["category"], "Другое")
            ingredients.append({
                "id": str(uuid.uuid4()),
                "name": ing,
                "amount": amount,
                "category": category_swift
            })
    
    return ingredients

def generate_instructions(category):
    """Генерирует инструкции по шаблону"""
    templates = INSTRUCTION_TEMPLATES.get(category, INSTRUCTION_TEMPLATES["main"])
    template = random.choice(templates)
    return template.copy()

def generate_recipe_name(category_data, ingredients):
    """Генерирует название рецепта"""
    base_name = random.choice(category_data["names"])
    main_ingredient = ingredients[0]["name"] if ingredients else "продуктов"
    
    variations = [
        f"{base_name} с {main_ingredient}",
        f"{base_name} из {main_ingredient}",
        f"{base_name}",
        f"{base_name} по-домашнему",
        f"{base_name} классический"
    ]
    
    return random.choice(variations).capitalize()

def generate_description(name, category):
    """Генерирует описание рецепта"""
    descriptions = [
        f"Вкусное блюдо категории {category}",
        "Простой и быстрый рецепт",
        "Домашнее блюдо",
        "Классический рецепт",
        "Проверенный временем рецепт"
    ]
    return random.choice(descriptions)

def generate_recipe(category_key, category_data):
    """Генерирует один рецепт"""
    ingredients = generate_ingredients(category_data)
    name = generate_recipe_name(category_data, ingredients)
    
    time_range = category_data["time_range"]
    cooking_time = random.randint(time_range[0], time_range[1])
    
    difficulty = random.choice(category_data["difficulty"])
    # Конвертируем в значения из Swift enum
    difficulty_map = {
        "easy": "Легко",
        "medium": "Средне",
        "hard": "Сложно"
    }
    difficulty_swift = difficulty_map.get(difficulty, "Легко")
    
    # Конвертируем категорию в значения из Swift enum
    category_map = {
        "breakfast": "Завтрак",
        "salad": "Салат",
        "main": "Основное",
        "soup": "Суп",
        "dessert": "Десерт",
        "side": "Гарнир"
    }
    category_swift = category_map.get(category_key, "Основное")
    
    servings = random.choice([2, 4, 6])
    
    instructions = generate_instructions(category_key)
    description = generate_description(name, category_key)
    
    return {
        "id": generate_recipe_id(),
        "name": name,
        "description": description,
        "ingredients": ingredients,
        "instructions": instructions,
        "cookingTime": cooking_time,
        "difficulty": difficulty_swift,
        "servings": servings,
        "category": category_swift
    }

def main():
    """Генерирует 1000 рецептов"""
    recipes = []
    
    # Распределение по категориям
    distribution = {
        "breakfast": 200,
        "salad": 150,
        "main": 250,
        "soup": 150,
        "dessert": 150,
        "side": 100
    }
    
    for category_key, category_data in CATEGORIES.items():
        count = distribution[category_key]
        print(f"Генерирую {count} рецептов категории {category_key}...")
        
        for _ in range(count):
            recipe = generate_recipe(category_key, category_data)
            recipes.append(recipe)
    
    # Сохраняем в JSON
    output_file = "recipes_1000.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(recipes, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ Сгенерировано {len(recipes)} рецептов!")
    print(f"📁 Файл сохранен: {output_file}")
    print(f"📊 Распределение:")
    for cat, count in distribution.items():
        print(f"   - {cat}: {count} рецептов")

if __name__ == "__main__":
    main()
