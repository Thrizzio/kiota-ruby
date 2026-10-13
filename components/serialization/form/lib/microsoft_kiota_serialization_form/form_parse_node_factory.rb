# frozen_string_literal: true

require 'microsoft_kiota_abstractions'

module MicrosoftKiotaSerializationForm
  class FormParseNodeFactory
    include MicrosoftKiotaAbstractions::ParseNodeFactory

    def get_valid_content_type
      'application/x-www-form-urlencoded'
    end

    def get_parse_node(content_type, content)
      valid = get_valid_content_type
      raise ArgumentError, 'content type cannot be undefined or empty' if content_type.nil? || content_type.empty?
      raise ArgumentError, "expected a #{valid} content type" unless content_type.casecmp?(valid)
      raise ArgumentError, 'content cannot be undefined or empty' if content.nil?

      FormParseNode.new(content)
    end
  end
end
