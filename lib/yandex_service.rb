require_relative "service"

EDPOINT = "https://transcribe.api.cloud.yandex.net/speech/stt/v2/longRunningRecognize"

class YandexService < Service
  attr_reader :headers

  def initialize(*args, bucket, file, object_url)
    super(*args)
    @bucket = bucket
    @file = file
    @object_url = object_url
    @headers = { 'Authorization': "Api-key #{@token}" }
  end
  
  # Загрузка файла на Yandex Object Storage
  def load_file_yandex_storage(object_key)
    create_s3_resource.bucket(@bucket).object(object_key).put(body: @file)
  end

  # Получения ответа от сервиса после отправки звукого файла
  def get_response_yandex
    send_yandex_request(URI(EDPOINT))
  end

  # Когда произойдет подключение подключится к серверу яндекс то вернет данные текста из голоса
  def get_response_form_object(url)
    response = Net::HTTP.get_response(url, @headers)
    result = JSON.parse(response.body)

    while result['done'] != true
      response = Net::HTTP.get_response(url, @headers)
      result = JSON.parse(response.body)
      p 'No connect'
      sleep 1
    end
    result
  end
  
  private

  # Отправка запроса звукого файла на распознование в яндекс
  def send_yandex_request(url)
    response = Net::HTTP.post(url, body.to_json, @headers)
    JSON.parse(response.body)
  end

  def body
    {
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
        uri: @object_url
      }
    }
  end

  # Взаимодействия с сервисом яндекс хранилища
  def create_s3_resource
    s3 = Aws::S3::Resource.new(
      region: "ru-central1",
      access_key_id: ENV["YC_AK_ID"],
      secret_access_key: ENV["YC_SECRET"],
      endpoint: "https://storage.yandexcloud.net",
    )
  end
end
