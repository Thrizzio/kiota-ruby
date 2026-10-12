# frozen_string_literal: true

require 'time'
require 'date'
require 'uuidtools'
require 'microsoft_kiota_abstractions'

module MicrosoftKiotaSerializationText
  class TextParseNode
    include MicrosoftKiotaAbstractions::ParseNode

    NO_STRUCTURED_DATA_MESSAGE = 'Text does not support structured data'

    def initialize(text)
      @text = text
    end

    def get_string_value
      @text unless @text.nil? || @text.empty?
    end

    def get_boolean_value
      case scalar_text&.downcase
      when 'true' then true
      when 'false' then false
      end
    end

    def get_number_value
      text = scalar_text
      Integer(text, 10, exception: false) if text
    end

    def get_float_value
      text = scalar_text
      Float(text, exception: false) if text
    end

    def get_guid_value
      text = scalar_text
      UUIDTools::UUID.parse(text) if text
    end

    def get_date_value
      text = scalar_text
      Date.parse(text) if text
    end

    def get_time_value
      text = scalar_text
      Time.parse(text) if text
    end

    def get_date_time_value
      text = scalar_text
      DateTime.parse(text) if text
    end

    def get_duration_value
      text = scalar_text
      MicrosoftKiotaAbstractions::ISODuration.new(text) if text
    end

    def get_byte_array_value
      scalar_text&.unpack1('m')
    end

    def get_enum_value(type)
      text = scalar_text
      resolve_enum_member(type, text) if text
    end

    def get_child_node(_name)
      raise StandardError, NO_STRUCTURED_DATA_MESSAGE
    end

    def get_collection_of_primitive_values(_type)
      raise StandardError, NO_STRUCTURED_DATA_MESSAGE
    end

    def get_collection_of_object_values(_factory)
      raise StandardError, NO_STRUCTURED_DATA_MESSAGE
    end

    def get_collection_of_enum_values(_type)
      raise StandardError, NO_STRUCTURED_DATA_MESSAGE
    end

    def get_object_value(_factory)
      raise StandardError, NO_STRUCTURED_DATA_MESSAGE
    end

    private

    # typed values ignore surrounding whitespace, as .NET's TryParse does
    def scalar_text
      text = get_string_value&.strip
      text unless text.nil? || text.empty?
    end

    # same resolution as JsonParseNode: the wire value first, then the member name
    def resolve_enum_member(type, raw)
      return raw.to_sym unless type.is_a?(Hash)

      type.each_value { |value| return value if value.to_s == raw }
      type[raw.to_sym] || type[(raw[0].to_s.upcase + raw[1..].to_s).to_sym]
    end
  end
end
