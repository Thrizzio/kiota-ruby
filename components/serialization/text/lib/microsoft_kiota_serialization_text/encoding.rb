# frozen_string_literal: true

module MicrosoftKiotaSerializationText
  # bytes are read as UTF-8; a string Faraday tagged with its charset is converted
  def self.to_utf8(text)
    text.encoding == Encoding::BINARY ? text.dup.force_encoding(Encoding::UTF_8) : text.encode(Encoding::UTF_8)
  end
end
