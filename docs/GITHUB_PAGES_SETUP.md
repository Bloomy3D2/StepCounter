# Инструкция по настройке GitHub Pages для StepCounter

## Шаг 1: Создание репозитория на GitHub

1. Перейдите на [GitHub](https://github.com) и войдите в свой аккаунт
2. Нажмите кнопку **"New"** (или **"+"** → **"New repository"**)
3. Заполните форму:
   - **Repository name:** `StepCounter` (или любое другое имя)
   - **Description:** "Умный шагомер с геймификацией для iOS"
   - **Visibility:** Public (для бесплатного GitHub Pages) или Private
   - **НЕ** добавляйте README, .gitignore или лицензию (если репозиторий уже существует)
4. Нажмите **"Create repository"**

## Шаг 2: Инициализация Git в локальном проекте

Откройте терминал в папке проекта и выполните:

```bash
cd /Users/maratgaliev/Downloads/Project/MyProjectGame

# Инициализируем Git (если еще не инициализирован)
git init

# Добавляем все файлы
git add .

# Создаем первый коммит
git commit -m "Initial commit: StepCounter app with GitHub Pages"

# Добавляем remote репозиторий (замените YOUR_USERNAME на ваш GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/StepCounter.git

# Отправляем код на GitHub
git branch -M main
git push -u origin main
```

## Шаг 3: Настройка GitHub Pages

1. Перейдите в ваш репозиторий на GitHub
2. Откройте **Settings** (Настройки) в верхнем меню репозитория
3. В левом меню найдите раздел **"Pages"** (в секции "Code and automation")
4. В разделе **"Source"** выберите:
   - **Branch:** `main` (или `master`)
   - **Folder:** `/docs`
5. Нажмите **"Save"**

## Шаг 4: Ожидание публикации

GitHub Pages обычно публикуется в течение 1-2 минут. Вы увидите сообщение:
> "Your site is live at https://YOUR_USERNAME.github.io/StepCounter/"

## Шаг 5: Проверка работы

1. Подождите 1-2 минуты после настройки
2. Откройте в браузере: `https://YOUR_USERNAME.github.io/StepCounter/`
3. Вы должны увидеть главную страницу приложения

## Структура файлов

После настройки структура должна быть такой:

```
StepCounter/
├── docs/
│   ├── index.html          ← Главная страница
│   ├── privacy-policy.html  ← Политика конфиденциальности
│   └── .nojekyll           ← Отключает Jekyll (для чистого HTML)
├── StepCounter/            ← Код приложения
└── ...                     ← Остальные файлы проекта
```

## Обновление страницы

После любых изменений в папке `docs/`:

```bash
git add docs/
git commit -m "Update GitHub Pages"
git push
```

Изменения появятся на сайте через 1-2 минуты.

## Настройка URL политики конфиденциальности в приложении

После публикации GitHub Pages обновите URL в приложении:

1. Откройте `StepCounter/Views/PrivacyPolicyWebView.swift` (или где используется URL)
2. Замените URL на: `https://YOUR_USERNAME.github.io/StepCounter/privacy-policy.html`

## Дополнительные настройки

### Кастомный домен (опционально)

Если у вас есть собственный домен:

1. В настройках GitHub Pages добавьте ваш домен
2. Настройте DNS записи у вашего регистратора домена
3. Подробнее: [GitHub Pages Custom Domain](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)

### HTTPS

GitHub Pages автоматически предоставляет HTTPS для всех сайтов. Сертификат обновляется автоматически.

## Устранение проблем

### Страница не загружается

1. Проверьте, что папка `docs/` существует и содержит `index.html`
2. Убедитесь, что в настройках Pages выбран правильный branch и папка `/docs`
3. Подождите 2-3 минуты (GitHub может обрабатывать изменения)

### Изображения не отображаются

1. Убедитесь, что пути к изображениям относительные (например, `./images/icon.png`)
2. Проверьте, что файлы изображений добавлены в репозиторий

### Стили не применяются

1. Проверьте, что CSS находится внутри `<style>` тега в `index.html`
2. Или используйте внешний файл CSS (добавьте его в папку `docs/`)

## Полезные ссылки

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [GitHub Pages Quickstart](https://docs.github.com/en/pages/quickstart)
- [Custom 404 Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-custom-404-page-for-your-github-pages-site)

---

**Готово!** Ваш сайт должен быть доступен по адресу: `https://YOUR_USERNAME.github.io/StepCounter/`
