class Main
  require 'telegram/bot'
  require 'net/http'
  require 'stringio'
  require 'dotenv/load'
  require 'puma'

  Telegram::Bot::Client.run(ENV['TOKEN'], { polling: true }) do |bot|
    bot.listen do |message|
      if message.voice
        # Извлечение голосового файла
        file_id = message.voice.file_id
        file_path = bot.api.get_file(file_id: message.voice.file_id).fetch('result').fetch('file_path')

        # Проверка файла на допустимый формат
        if file_path !~ /\.oga\z/
          bot.api.send_message(chat_id: message.chat.id, text: 'Формат файла не поддерживается.')
          next
        end

        # # Проверка наличия файла
        file_path = "/#{file_path}" unless file_path.start_with?('\/')

        # Проверка наличия файла
        uri = URI("https://api.telegram.org/file/bot#{ENV['TOKEN']}#{file_path}")
        response = Net::HTTP.get_response(uri)
        voice_url = "https://api.telegram.org/file/bot#{ENV['TOKEN']}/#{file_path}"
        uri = URI(voice_url)
        response = Net::HTTP.get_response(uri)

        # Отправка для преобразования yandex spechkit
        uri = URI("https://stt.api.cloud.yandex.net/speech/v1/stt:recognize?folderId=#{ENV['FOLDER_ID']}&lang=ru-RU")
        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = 'Api-key ' + ENV['TOKEN_YANDEX']
        request.body = response.body
        yandex_response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        # Вывод результата пользователю в форме текста
        recognized_text = JSON.parse(yandex_response.body)['result']

        if recognized_text.nil?
          bot.api.send_message(chat_id: message.chat.id, text: 'Лимит 30с....в поиске решения')
          recognized_text = ""
        elsif recognized_text.empty?
          bot.api.send_message(chat_id: message.chat.id, text: '...')
        else
          bot.api.send_message(chat_id: message.chat.id, text: recognized_text)
        end
      end
    end
  end
end
