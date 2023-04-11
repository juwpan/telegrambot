module SendYandex
  def self.send_yandex_request(url, body, headers)
    response = Net::HTTP.post(url, body.to_json, headers)
    JSON.parse(response.body)
  end
end