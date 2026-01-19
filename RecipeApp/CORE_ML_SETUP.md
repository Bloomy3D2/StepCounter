# Инструкция по подключению Core ML модели

## Шаг 1: Подготовка модели

### Вариант A: Использование готовой Core ML модели

1. Найдите или создайте Core ML модель для генерации текста
2. Рекомендуемые модели:
   - **LLaMA 2/3 7B** (квантованная версия)
   - **Mistral 7B** (оптимизированная для мобильных)
   - **Phi-2** (Microsoft, маленькая модель)

### Вариант B: Конвертация существующей модели

#### Использование llama.cpp

```bash
# Установка llama.cpp
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp

# Конвертация в Core ML
python convert-llama-to-coreml.py \
    --model-dir ./models/llama-7b \
    --output-dir ./models/coreml \
    --quantization q4_0
```

#### Использование coremltools

```python
import coremltools as ct

# Загрузите вашу модель (PyTorch, TensorFlow и т.д.)
# Конвертируйте в Core ML
mlmodel = ct.convert(model, inputs=[...])

# Сохраните
mlmodel.save("RecipeGenerator.mlmodel")
```

## Шаг 2: Добавление модели в проект

1. Скопируйте `.mlmodelc` файл в папку `RecipeApp/`
2. Откройте Xcode
3. Перетащите файл в проект
4. Убедитесь, что:
   - ✅ Файл добавлен в Target "RecipeApp"
   - ✅ "Copy items if needed" отмечен
   - ✅ "Add to targets: RecipeApp" отмечен

## Шаг 3: Обновление LocalAIService.swift

Откройте `RecipeApp/Models/LocalAIService.swift` и обновите метод `loadModel()`:

```swift
private func loadModel() {
    guard let modelURL = Bundle.main.url(
        forResource: "RecipeGenerator",
        withExtension: "mlmodelc"
    ) else {
        print("⚠️ Core ML модель не найдена, используется шаблонная генерация")
        return
    }
    
    do {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine // или .all для GPU
        
        recipeModel = try MLModel(contentsOf: modelURL, configuration: config)
        print("✅ Core ML модель загружена успешно")
    } catch {
        print("❌ Ошибка загрузки модели: \(error)")
    }
}
```

## Шаг 4: Реализация генерации

Обновите метод `generateWithModel()` в `LocalAIService.swift`:

```swift
private func generateWithModel(
    model: MLModel,
    ingredients: [String],
    category: RecipeCategory?
) async throws -> Recipe {
    // 1. Подготовка входных данных
    let prompt = createPrompt(ingredients: ingredients, category: category)
    
    // 2. Конвертация в MLMultiArray или другой формат
    // (зависит от вашей модели)
    
    // 3. Выполнение inference
    // let prediction = try model.prediction(from: input)
    
    // 4. Парсинг результата
    // let generatedText = parseOutput(prediction)
    
    // 5. Создание Recipe из сгенерированного текста
    // return parseRecipe(from: generatedText, ingredients: ingredients)
    
    // Пока возвращаем шаблонный рецепт
    return generateTemplateRecipe(from: ingredients, category: category)
}
```

### Пример создания промпта

```swift
private func createPrompt(
    ingredients: [String],
    category: RecipeCategory?
) -> String {
    let ingredientsList = ingredients.joined(separator: ", ")
    let categoryText = category?.rawValue ?? "любая"
    
    return """
    Создай рецепт блюда категории "\(categoryText)" используя ТОЛЬКО следующие ингредиенты:
    \(ingredientsList)
    
    Рецепт должен включать:
    1. Название блюда
    2. Список ингредиентов с количествами
    3. Пошаговую инструкцию приготовления
    4. Время приготовления в минутах
    5. Количество порций
    6. Сложность (легко/средне/сложно)
    
    Формат ответа: JSON
    """
}
```

## Шаг 5: Оптимизация для мобильных устройств

### Квантование модели

Используйте квантованную версию модели (q4_0, q4_1) для уменьшения размера:
- Полная модель (FP16): ~14 GB
- Квантованная (Q4_0): ~4 GB
- Квантованная (Q4_1): ~4.5 GB

### Настройка computeUnits

В `MLModelConfiguration`:

```swift
let config = MLModelConfiguration()

// CPU только (самый медленный, но работает везде)
config.computeUnits = .cpuOnly

// CPU + Neural Engine (рекомендуется для iPhone)
config.computeUnits = .cpuAndNeuralEngine

// Все доступные (CPU + Neural Engine + GPU)
config.computeUnits = .all
```

## Шаг 6: Тестирование

1. Запустите приложение
2. Добавьте ингредиенты
3. Попробуйте сгенерировать рецепт
4. Проверьте логи в консоли Xcode

## Возможные проблемы

### Модель не загружается

- Проверьте, что файл добавлен в Bundle
- Убедитесь, что имя файла совпадает (без расширения)
- Проверьте размер файла (не превышает лимиты App Store)

### Медленная генерация

- Используйте квантованную модель
- Настройте `computeUnits` на `.cpuAndNeuralEngine`
- Ограничьте длину генерируемого текста

### Большой размер приложения

- Используйте загрузку модели по требованию (On-Demand Resources)
- Или загружайте модель при первом использовании из сервера

## Альтернативные подходы

### Использование Apple MLX

Если доступно, можно использовать Apple MLX для более эффективной работы с моделями на Apple Silicon.

### Онлайн генерация (fallback)

Если модель не загружена или слишком медленная, можно использовать шаблонную генерацию (текущая реализация).

## Полезные ресурсы

- [Apple Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [llama.cpp](https://github.com/ggerganov/llama.cpp)
- [coremltools](https://coremltools.readme.io/)
- [Apple MLX](https://github.com/ml-explore/mlx)
