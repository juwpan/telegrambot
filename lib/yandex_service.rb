require_relative 'uri_parse'

EDPOINT = "https://transcribe.api.cloud.yandex.net/speech/stt/v2/longRunningRecognize"

class YandexService
  def initialize(token_yandex, bucket, file, object_url)
    @token_yandex = token_yandex
    @bucket = bucket
    @file = file
    @object_url = object_url
  end

  def headers
    { 'Authorization': "Api-key #{@token_yandex}" }
  end
  
  # Загрузка файла на Yandex Object Storage
  def load_file_yandex_storage(object_key)
    create_s3_resource.bucket(@bucket).object(object_key).put(body: @file)
  end

  # Получения ответа от сервиса после отправки звукого файла
  def get_response_yandex
    response = send_yandex_request(URI(EDPOINT), body, headers)
  end
  
  private
  
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

  # Отправка запроса звукого файла на распознование в яндекс
  def send_yandex_request(url, body, headers)
    response = Net::HTTP.post(url, body.to_json, headers)
    JSON.parse(response.body)
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
