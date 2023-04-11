module UriParse
  def self.get_file_data(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
  end
end