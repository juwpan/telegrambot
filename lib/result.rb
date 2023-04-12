class Result < TelegramService
  def initialize(*args)
    super
  end

  def result(result_yandex)
    recognized_text = ""

    if result_yandex["response"]["chunks"].nil?
      @bot.api.send_message(chat_id: @message.chat.id, text: "Речь не распознана или ошибки на сервере")
    else
      result_yandex["response"]["chunks"].each do |word|
        recognized_text += word["alternatives"][0]["text"]
      end
      @bot.api.send_message(chat_id: @message.chat.id, text: recognized_text)
    end
  end
end
