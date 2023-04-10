module SendYandex
  def self.send_yandex_request(url, body, headers)
    response = Faraday.post(url, body.to_json, headers)
    JSON.parse(response.body)
  rescue Faraday::Error => e
    puts "An error occurred: #{e.message}"
    nil
  end
end