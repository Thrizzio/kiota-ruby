# frozen_string_literal: true

require 'time'
require 'date'
require 'uuidtools'
require 'microsoft_kiota_abstractions'
require_relative 'encoding'
require_relative 'text_parse_node'

module MicrosoftKiotaSerializationText
  class TextSerializationWriter
    include MicrosoftKiotaAbstractions::SerializationWriter

    NO_STRUCTURED_DATA_MESSAGE = TextParseNode::NO_STRUCTURED_DATA_MESSAGE
    VALUE_ALREADY_WRITTEN_MESSAGE =
      'a value was already written for this serialization writer, text content only supports a single value'

    def initialize
      @content = nil
    end

    def write_string_value(key, value)
      return if value.nil?
      raise StandardError, NO_STRUCTURED_DATA_MESSAGE unless key.nil? || key.empty?
      raise StandardError, VALUE_ALREADY_WRITTEN_MESSAGE unless @content.nil?

      @content = value
    end

    def write_boolean_value(key, value)
      write_string_value(key, value&.to_s)
    end

    def write_number_value(key, value)
      write_string_value(key, value&.to_s)
    end

    def write_float_value(key, value)
      write_string_value(key, value&.to_s)
    end

    def write_guid_value(key, value)
      write_string_value(key, value&.to_s)
    end

    def write_date_value(key, value)
      write_string_value(key, value&.strftime('%Y-%m-%d'))
    end

    def write_time_value(key, value)
      return if value.nil?

      digits = fraction_digits(value)
      write_string_value(key, value.strftime(digits.zero? ? '%H:%M:%S' : "%H:%M:%S.%#{digits}N"))
    end

    def write_date_time_value(key, value)
      write_string_value(key, value&.iso8601(fraction_digits(value)))
    end

    def write_duration_value(key, value)
      write_string_value(key, value&.string)
    end

    def write_enum_value(key, value)
      write_string_value(key, value&.to_s)
    end

    def write_byte_array_value(key, value)
      write_string_value(key, value && [value].pack('m0'))
    end

    def write_null_value(key)
      write_string_value(key, 'null')
    end

    def write_any_value(key, value)
      case value
      when nil then nil
      when String then write_string_value(key, value)
      when true, false then write_boolean_value(key, value)
      when Integer then write_number_value(key, value)
      when Float then write_float_value(key, value)
      when DateTime then write_date_time_value(key, value)
      when Date then write_date_value(key, value)
      when Time then write_time_value(key, value)
      when MicrosoftKiotaAbstractions::ISODuration then write_duration_value(key, value)
      when UUIDTools::UUID then write_guid_value(key, value)
      when Symbol then write_enum_value(key, value)
      when Array, Hash, MicrosoftKiotaAbstractions::Parsable then raise StandardError, NO_STRUCTURED_DATA_MESSAGE
      else raise StandardError, "encountered unknown value type during serialization #{value}"
      end
    end

    def write_collection_of_primitive_values(_key, _values)
      raise StandardError, NO_STRUCTURED_DATA_MESSAGE
    end

    def write_collection_of_object_values(_key, _values)
      raise StandardError, NO_STRUCTURED_DATA_MESSAGE
    end

    def write_collection_of_enum_values(_key, _values)
      raise StandardError, NO_STRUCTURED_DATA_MESSAGE
    end

    def write_object_value(_key, _value, *_additional_values_to_merge)
      raise StandardError, NO_STRUCTURED_DATA_MESSAGE
    end

    def write_additional_data(_value)
      raise StandardError, NO_STRUCTURED_DATA_MESSAGE
    end

    def get_serialized_content
      @content.nil? ? '' : MicrosoftKiotaSerializationText.to_utf8(@content)
    end

    private

    def fraction_digits(value)
      value.strftime('%N').sub(/0+\z/, '').length
    end
  end
end
