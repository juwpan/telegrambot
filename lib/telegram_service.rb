require_relative "service"

class TelegramService < Service
  attr_reader :token
  
  def initialize(*args, bot, message)
    super(*args)
    @bot = bot
    @message = message
  end

  # Вернет полученные данные ввиде бинарного кода
  def listen
    return result_yandex = extracting_a_voice_file
  end

  private

  # Извлечение записанного голосового файла
  def extracting_a_voice_file
    file_path = @bot.api.get_file(file_id: @message.voice.file_id).fetch('result').fetch('file_path')
    get_file_data(file_path)
  end

  # Получение данных файла
  def get_file_data(file_path)
    voice_url = "https://api.telegram.org/file/bot#{@token}/#{file_path}"
    response = Net::HTTP.get_response(URI(voice_url))
  end
end
