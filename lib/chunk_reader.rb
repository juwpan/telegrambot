module ChunkReader
  def self.read_chunks(chunk_size, bytes)
    Enumerator.new do |enum|
      i = 0
      while i < bytes.length
        chunk = bytes[i...i + chunk_size]
        enum.yield chunk
        i += chunk_size
      end
    end
  end
end