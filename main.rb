require "telegram/bot"
require "net/http"
require "dotenv/load"
require "tempfile"
require "aws-sdk-s3"
require "puma"
require "json"

require_relative "lib/yandex_service"
require_relative "lib/telegram_service"
require_relative "lib/response_yandex"
require_relative "lib/result"

TOKEN = ENV["TOKEN"]
TOKEN_YANDEX = ENV["TOKEN_YANDEX"]
FOLDER_ID = ENV["FOLDER_ID"]
IAM_TOKEN = ENV["IAM_TOKEN"]
BUCKET = ENV["BUCKET"]

OBJECT_KEY = "voice.ogg"
OBJECT_URL = "https://storage.yandexcloud.net/#{BUCKET}/#{OBJECT_KEY}"

Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|
    if message.voice
      # Создание эксемпляра телеграм сервиса для возврата записанного голосового файла
      telegram_bot = TelegramService.new(TOKEN, bot, message)

      # Данные голосовго файла из телеграмма
      response = telegram_bot.listen

      # Создание временного файла в памяти и запись в него содержимого файла
      file = Tempfile.new("voice_file")
      file.binmode
      file.write(response.body)
      file.rewind

      # Создание эксемпляра яндекс для реализации загрузки файлов в хранилище и получение ссылки
      # из этого хранилища для передачи в yandex speechkit
      yandex = YandexService.new(TOKEN_YANDEX, BUCKET, file, OBJECT_URL)

      # Загрузка файла на Yandex Object Storage
      yandex.load_file_yandex_storage(OBJECT_KEY)

      # Удаление временного файла из памяти
      file.close
      file.unlink

      # Получения ответа от сервиса
      response = yandex.get_response_yandex
      task_id = response["id"]

      # Ссылка на записаное аудио
      edpoint_voice = "https://operation.api.cloud.yandex.net/operations/#{task_id}"

      # Авторизация(почему то через раз)
      result_yandex = ResponseYandex.get_response_form_object(URI(edpoint_voice), yandex.headers)

      # Результат
      result = Result.new(TOKEN, bot, message)
      result.result(result_yandex)
    end
  end
end
