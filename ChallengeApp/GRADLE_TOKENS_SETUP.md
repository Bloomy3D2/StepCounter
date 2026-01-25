# Настройка токенов для Nexus и SberOS

Инструкция по получению токенов и настройке `gradle.properties` для работы с корпоративными репозиториями.

---

## 📋 Содержание

1. [Получение токена Nexus](#1-получение-токена-nexus)
2. [Получение токена SberOS](#2-получение-токена-sberos)
3. [Настройка gradle.properties](#3-настройка-gradleproperties)
4. [Настройка IntelliJ IDEA и Gradle Wrapper](#4-настройка-intellij-idea-и-gradle-wrapper)
5. [Проверка настройки](#5-проверка-настройки)

---

## 1. Получение токена Nexus

### Шаги:

1. Откройте страницу: https://nexus-ci.delta.sbrf.ru/nosso/#user/usertoken
2. Выполните вход, используя логин и пароль от личной учетной записи
3. Перейдите во вкладку **User Token**
4. Создайте новый токен или используйте существующий
5. Сохраните следующие значения:
   - **User token name code** (имя токена)
   - **User token pass code** (пароль токена)

> ⚠️ **Важно:** Сохраните эти значения в безопасном месте, они понадобятся для настройки `gradle.properties`

---

## 2. Получение токена SberOS

### Шаги:

1. Откройте страницу: https://sberosc.sigma.sbrf.ru/
2. Выполните вход через **СУДИР**
3. В правом верхнем углу выберите **"Профиль"**
4. Создайте новый токен
5. Сохраните значение токена

> ⚠️ **Важно:** Токен понадобится в двух форматах:
> - Оригинальный токен
> - Токен в формате Base64 (можно конвертировать онлайн или через команду: `echo -n "your_token" | base64`)

---

## 3. Настройка gradle.properties

### 3.1. Создание файла

Создайте файл `gradle.properties` по пути:
```
%USER_HOME%/.gradle/gradle.properties
```

**Для macOS/Linux:**
```bash
~/.gradle/gradle.properties
```

**Для Windows:**
```
C:\Users\<ВашеИмя>\.gradle\gradle.properties
```

### 3.2. Содержимое файла

Откройте файл для редактирования и заполните следующим содержимым:

```properties
# ============================================
# Gradle Performance Settings
# ============================================
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.vfs.watch=false
org.gradle.jvmargs=-Xmx1024m -XX:MaxMetaspaceSize=512m -Dfile.encoding=UTF-8

# ============================================
# Nexus Delta Credentials
# ============================================
# Замените значения на ваши данные из Nexus
systemProp.gradle.wrapperUser=<Your user token name code from Nexus>
systemProp.gradle.wrapperPassword=<Your user token pass code from Nexus>
nexusDeltaUserTokenNameCode=<Your user token name code from Nexus>
nexusDeltaUserTokenPasswordCode=<Your user token pass code from Nexus>
deltaUsername=<Your user token name code from Nexus>
deltaPassword=<Your user token pass code from Nexus>
user=<Your user token name code from Nexus>
password=<Your user token pass code from Nexus>

# ============================================
# SberOS Credentials
# ============================================
# Замените значения на ваш токен из SberOS
tokenSberOSC=<Your token from SberOS>
sberOscTokenBase64=<Your token from SberOS in Base64 format>
sberOSCSigmaUserTokenNameCode=token
sberOSCSigmaUserTokenPasswordCode=<Your token from SberOS>

# ============================================
# Maven Repository Settings
# ============================================
mavenExternalEnabled=false
mavenLocalEnabled=false
mavenSberOscEnabled=false

# ============================================
# Cache Settings
# ============================================
cacheDynamicVersionsFor=0
cacheChangingModulesFor=0
```

### 3.3. Заполнение значений

#### Значения из Nexus (замените все вхождения):
- `<Your user token name code from Nexus>` → вставьте **User token name code** из Nexus
- `<Your user token pass code from Nexus>` → вставьте **User token pass code** из Nexus

#### Значения из SberOS (замените все вхождения):
- `<Your token from SberOS>` → вставьте оригинальный токен из SberOS
- `<Your token from SberOS in Base64 format>` → вставьте токен в формате Base64

> 💡 **Совет:** Для конвертации токена в Base64 используйте:
> - **macOS/Linux:** `echo -n "your_token" | base64`
> - **Windows (PowerShell):** `[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("your_token"))`
> - **Онлайн:** https://www.base64encode.org/

---

## 4. Настройка IntelliJ IDEA и Gradle Wrapper

Для корректной работы проекта необходимо настроить Java SberOS в IntelliJ IDEA и убедиться, что Gradle Wrapper использует ту же версию Java.

### 4.1. Настройка Java SberOS в IntelliJ IDEA

#### Шаги:

1. Откройте IntelliJ IDEA
2. Перейдите в настройки:
   - **macOS:** `IntelliJ IDEA` → `Settings` (или `Preferences` с помощью `Cmd + ,`)
   - **Windows/Linux:** `File` → `Settings` (или `Ctrl + Alt + S`)
3. В левом меню выберите: `Build, Execution, Deployment` → `Build Tools` → `Gradle`
4. В разделе **Gradle JVM** выберите Java SberOS:
   - Если Java SberOS уже установлена, выберите её из списка
   - Если нет, нажмите `Download JDK...` или добавьте существующую установку через `Add SDK...`
5. Убедитесь, что выбранная версия Java соответствует требованиям проекта
6. Нажмите `Apply` и `OK`

#### Альтернативный способ (через Project Structure):

1. Перейдите в `File` → `Project Structure` (или `Ctrl + Alt + Shift + S` / `Cmd + ;`)
2. В разделе **Project**:
   - **Project SDK:** выберите Java SberOS
   - **Project language level:** выберите соответствующий уровень (обычно соответствует версии Java)
3. В разделе **Modules** → выберите ваш модуль → **Language level:** должен совпадать с Project language level
4. Нажмите `Apply` и `OK`

### 4.2. Настройка Gradle Wrapper

Gradle Wrapper должен использовать ту же версию Java, что и настроена в IntelliJ IDEA.

#### Проверка текущей версии Java в Gradle Wrapper:

1. Откройте файл `gradle/wrapper/gradle-wrapper.properties` в корне проекта
2. Проверьте, что указана корректная версия Gradle

#### Настройка Java для Gradle Wrapper:

**Вариант 1: Через gradle.properties (рекомендуется)**

Добавьте в файл `~/.gradle/gradle.properties` (или `%USERPROFILE%\.gradle\gradle.properties`):

```properties
# ============================================
# Java Settings for Gradle
# ============================================
org.gradle.java.home=/path/to/sberos/java
```

> ⚠️ **Важно:** Замените `/path/to/sberos/java` на реальный путь к установке Java SberOS
> 
> **Примеры путей:**
> - **macOS:** `/Library/Java/JavaVirtualMachines/sberos-jdk-XX.jdk/Contents/Home`
> - **Windows:** `C:\Program Files\Java\sberos-jdk-XX`
> - **Linux:** `/usr/lib/jvm/sberos-jdk-XX`

**Вариант 2: Через локальный gradle.properties проекта**

Создайте или отредактируйте файл `gradle.properties` в корне проекта:

```properties
org.gradle.java.home=/path/to/sberos/java
```

**Вариант 3: Через переменную окружения**

Установите переменную окружения `JAVA_HOME`:

**macOS/Linux:**
```bash
export JAVA_HOME=/path/to/sberos/java
```

**Windows (PowerShell):**
```powershell
$env:JAVA_HOME="C:\path\to\sberos\java"
```

**Windows (CMD):**
```cmd
set JAVA_HOME=C:\path\to\sberos\java
```

### 4.3. Проверка версии Java

Убедитесь, что Gradle использует правильную версию Java:

```bash
# Проверка версии Java, используемой Gradle
./gradlew -version
```

В выводе команды проверьте:
- **JVM:** должна быть указана версия Java SberOS
- **Java version:** должна соответствовать версии, настроенной в IDEA

### 4.4. Синхронизация проекта

После настройки Java:

1. В IntelliJ IDEA нажмите на кнопку **Gradle** в правой панели (или `View` → `Tool Windows` → `Gradle`)
2. Нажмите на иконку **Reload All Gradle Projects** (🔄) для перезагрузки проекта
3. Дождитесь завершения синхронизации

> 💡 **Совет:** Если возникают проблемы, попробуйте:
> - `File` → `Invalidate Caches...` → `Invalidate and Restart`
> - Удалить папку `.idea` и `.gradle` в корне проекта (после этого IDEA пересоздаст их)

---

## 5. Проверка настройки

### 5.1. Проверка файла

Убедитесь, что файл создан и содержит все необходимые свойства:

```bash
# macOS/Linux
cat ~/.gradle/gradle.properties

# Windows
type %USERPROFILE%\.gradle\gradle.properties
```

### 5.2. Проверка подключения

Попробуйте выполнить сборку проекта:

```bash
./gradlew build
```

Если настройка выполнена правильно, сборка должна пройти успешно без ошибок аутентификации.

### 5.3. Проверка версии Java

Убедитесь, что все компоненты используют одну и ту же версию Java:

```bash
# Проверка версии Java в системе
java -version

# Проверка версии Java, используемой Gradle
./gradlew -version
```

Обе команды должны показывать одинаковую версию Java SberOS.

### 5.4. Возможные проблемы

**Проблема:** Ошибка аутентификации при сборке
- **Решение:** Проверьте правильность введенных токенов и их формат

**Проблема:** Файл не найден
- **Решение:** Убедитесь, что файл создан в правильной директории (`~/.gradle/` или `%USERPROFILE%\.gradle\`)

**Проблема:** Ошибка Base64
- **Решение:** Проверьте правильность конвертации токена в Base64 (не должно быть переносов строк)

**Проблема:** Gradle использует другую версию Java, не SberOS
- **Решение:** 
  - Проверьте настройку `org.gradle.java.home` в `gradle.properties`
  - Убедитесь, что `JAVA_HOME` указывает на Java SberOS
  - Перезагрузите проект в IntelliJ IDEA

**Проблема:** IntelliJ IDEA не видит Java SberOS
- **Решение:**
  - Убедитесь, что Java SberOS установлена в системе
  - Добавьте SDK вручную через `File` → `Project Structure` → `SDKs` → `+` → `Add JDK...`
  - Укажите путь к установке Java SberOS

**Проблема:** Несоответствие версий Java между IDEA и Gradle
- **Решение:**
  - Убедитесь, что в `File` → `Project Structure` → `Project` → `Project SDK` выбрана Java SberOS
  - Проверьте, что `org.gradle.java.home` в `gradle.properties` указывает на ту же установку
  - Выполните `./gradlew -version` для проверки версии Java, используемой Gradle

---

## 📝 Пример заполненного файла

```properties
# ============================================
# Gradle Performance Settings
# ============================================
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.vfs.watch=false
org.gradle.jvmargs=-Xmx1024m -XX:MaxMetaspaceSize=512m -Dfile.encoding=UTF-8

# ============================================
# Java Settings for Gradle
# ============================================
# Укажите путь к установке Java SberOS
org.gradle.java.home=/Library/Java/JavaVirtualMachines/sberos-jdk-17.jdk/Contents/Home

# ============================================
# Nexus Delta Credentials
# ============================================
systemProp.gradle.wrapperUser=my_nexus_token_name
systemProp.gradle.wrapperPassword=my_nexus_token_pass
nexusDeltaUserTokenNameCode=my_nexus_token_name
nexusDeltaUserTokenPasswordCode=my_nexus_token_pass
deltaUsername=my_nexus_token_name
deltaPassword=my_nexus_token_pass
user=my_nexus_token_name
password=my_nexus_token_pass

# ============================================
# SberOS Credentials
# ============================================
tokenSberOSC=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
sberOscTokenBase64=ZXlKaGJHY2lPaUpTVXpJMU5pSXNJblI1Y0NJNklrcFhWQ0o5...
sberOSCSigmaUserTokenNameCode=token
sberOSCSigmaUserTokenPasswordCode=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# ============================================
# Maven Repository Settings
# ============================================
mavenExternalEnabled=false
mavenLocalEnabled=false
mavenSberOscEnabled=false

# ============================================
# Cache Settings
# ============================================
cacheDynamicVersionsFor=0
cacheChangingModulesFor=0
```

> ⚠️ **Важно:** 
> - Замените путь в `org.gradle.java.home` на реальный путь к вашей установке Java SberOS
> - Для Windows используйте формат: `C:\\Program Files\\Java\\sberos-jdk-17`
> - Для Linux используйте формат: `/usr/lib/jvm/sberos-jdk-17`

---

## 🔒 Безопасность

> ⚠️ **Важно для безопасности:**
> - Файл `gradle.properties` содержит конфиденциальные данные
> - Не коммитьте этот файл в систему контроля версий
> - Убедитесь, что файл добавлен в `.gitignore`
> - Храните токены в безопасном месте
> - Регулярно обновляйте токены при необходимости

---

## ✅ Чеклист

- [ ] Получен токен из Nexus (name code и pass code)
- [ ] Получен токен из SberOS
- [ ] Токен SberOS конвертирован в Base64
- [ ] Создан файл `~/.gradle/gradle.properties` (или `%USERPROFILE%\.gradle\gradle.properties`)
- [ ] Все значения заполнены в файле
- [ ] Java SberOS установлена в системе
- [ ] Java SberOS настроена в IntelliJ IDEA (Project SDK)
- [ ] `org.gradle.java.home` настроен в `gradle.properties` на путь к Java SberOS
- [ ] Проверена версия Java через `./gradlew -version`
- [ ] Версии Java в системе, IDEA и Gradle совпадают
- [ ] Выполнена синхронизация проекта в IntelliJ IDEA
- [ ] Выполнена проверка сборки проекта
- [ ] Файл `gradle.properties` добавлен в `.gitignore` (если используется Git)

---

**Готово!** Теперь вы можете использовать Gradle с корпоративными репозиториями. 🚀
