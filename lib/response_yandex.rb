# Если подключится к серверу яндекс то вернет данные текста из голоса
module ResponseYandex
  def self.get_response_form_object(url, headers)
    response = Net::HTTP.get_response(url, headers)
    result = JSON.parse(response.body)

    while result['done'] != true
      if result['done'] == true
        p 'Connect'
        return result
      else
        response = Net::HTTP.get_response(url, headers)
        result = JSON.parse(response.body)
        p 'No connect'
        sleep 1
      end
    end

    result
  end
end