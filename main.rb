require 'telegram/bot'
require 'net/http'
require 'dotenv/load'
require 'tempfile'
require 'aws-sdk-s3'
require 'puma'
require 'json'

require_relative 'lib/send_yandex'
require_relative 'lib/response_yandex'
require_relative 'lib/uri_parse'

TOKEN = ENV['TOKEN']
TOKEN_YANDEX = ENV['TOKEN_YANDEX']
FOLDER_ID = ENV['FOLDER_ID']
IAM_TOKEN = ENV['IAM_TOKEN']
BUCKET = ENV['BUCKET']
EDPOINT = 'https://transcribe.api.cloud.yandex.net/speech/stt/v2/longRunningRecognize'

s3 = Aws::S3::Resource.new(
  region: 'ru-central1',
  access_key_id: ENV['YC_AK_ID'],
  secret_access_key: ENV['YC_SECRET'],
  endpoint: 'https://storage.yandexcloud.net',
)

Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|
    if message.voice
      # Извлечение голосового файла
      file_id = message.voice.file_id
      file_path = bot.api.get_file(file_id: message.voice.file_id).fetch('result').fetch('file_path')

      # Получение данных файла
      voice_url = "https://api.telegram.org/file/bot#{TOKEN}/#{file_path}"
      response = UriParse.get_file_data(voice_url)

      # Создание временного файла в памяти и запись в него содержимого файла
      file = Tempfile.new('voice_file')
      file.binmode
      file.write(response.body)
      file.rewind
  
      # Загрузка файла на Yandex Object Storage
      object_key = "voice.ogg"
      s3.bucket(BUCKET).object(object_key).put(body: file)
  
      # Удаление временного файла из памяти
      file.close
      file.unlink

      # Получение ссылки на загруженный файл
      object_url = "https://storage.yandexcloud.net/#{BUCKET}/#{object_key}"
      response = UriParse.get_file_data(object_url)

      headers = { 'Authorization': "Api-key #{TOKEN_YANDEX}" }
      body = {
        config: {
          specification: {
            languageCode: 'ru-RU',
            model: 'general',
            profanityFilter: 'true',
            audioEncoding: 'OGG_OPUS',
            sampleRateHertz: 48000,
            audioChannelCount: 1,
            rawResults: true,
            literature_text: true
          }
        },
        audio: {
          uri: object_url
        }
      }

      # Получения ответа от сервиса
      response = SendYandex.send_yandex_request(URI(EDPOINT), body, headers)
      task_id = response['id']

      # Запись данных из файла
      edpoint_voice = "https://operation.api.cloud.yandex.net/operations/#{task_id}"

      # Авторизация почему то через раз
      result = ResponseYandex.get_response_form_object(URI(edpoint_voice), headers)

      recognized_text = ''

      if result['response']['chunks'].nil?
        bot.api.send_message(chat_id: message.chat.id, text: 'Речь не распознана или ошибки на сервере')
      else
        result['response']['chunks'].each do |word|
          recognized_text += word['alternatives'][0]['text']
        end
        bot.api.send_message(chat_id: message.chat.id, text: recognized_text)
      end
    end
  end
end
