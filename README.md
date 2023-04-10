# Телеграм бот

<div>
  <a href="https://rubyonrails.org">
    <img src="https://img.shields.io/badge/Ruby-3.1.2-ff0000?logo=Ruby&logoColor=white&?style=for-the-badge"
    alt="Rails badge" />
  </a>
</div>

#### "Телеграм бот" реализованные функции:
1. Преобразования голоса в текст

### Важно!
Запуск команд производится в консоли вашей опреционой системы.

### Пошаговое руководство запуска приложения.

### Скачать репозиторий:

Перейдите в папку, в которую вы хотите скачать исходный код Ruby, и запустите:

```
$ git clone git@github.com:juwpan/telegrambot.git
```
```
$ cd telegrambot
```
### Установка зависимостей

```
bundle install
```

### Создание ключей

```
Создайте файл в корне папки '.env'
```

```
Пропишите туда переменные окружения для telegram и yandex speechkit и yandex cloud
```

### Запуск приложения

```
bundle exec puma
```

### Сервисы которые испульзуются
- Yandex speechkit
- Yandex Cloud
- Telegram API
