# frozen_string_literal: true

require 'microsoft_kiota_abstractions'
require_relative 'encoding'

module MicrosoftKiotaSerializationText
  class TextParseNodeFactory
    include MicrosoftKiotaAbstractions::ParseNodeFactory

    def get_valid_content_type
      'text/plain'
    end

    def get_parse_node(content_type, content)
      raise ArgumentError, 'content type cannot be undefined or empty' if content_type.nil? || content_type.empty?
      raise ArgumentError, "expected a #{get_valid_content_type} content type" unless get_valid_content_type.casecmp?(content_type)
      raise ArgumentError, 'content cannot be undefined or empty' if content.nil? || content.empty?

      TextParseNode.new(MicrosoftKiotaSerializationText.to_utf8(content).delete_prefix("\uFEFF"))
    end
  end
end
