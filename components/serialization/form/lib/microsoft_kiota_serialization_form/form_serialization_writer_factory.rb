# frozen_string_literal: true

require 'microsoft_kiota_abstractions'

module MicrosoftKiotaSerializationForm
  class FormSerializationWriterFactory
    include MicrosoftKiotaAbstractions::SerializationWriterFactory

    def get_valid_content_type
      'application/x-www-form-urlencoded'
    end

    def get_serialization_writer(content_type)
      valid = get_valid_content_type
      raise ArgumentError, 'content type cannot be undefined or empty' if content_type.nil? || content_type.empty?
      raise ArgumentError, "expected a #{valid} content type" unless content_type.casecmp?(valid)

      FormSerializationWriter.new
    end
  end
end
