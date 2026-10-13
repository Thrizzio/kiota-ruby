# frozen_string_literal: true

require 'microsoft_kiota_abstractions'
require_relative 'test_enum'

module Files
  class TestEntity
    include MicrosoftKiotaAbstractions::Parsable
    include MicrosoftKiotaAbstractions::AdditionalDataHolder

    attr_accessor :additional_data, :id, :device_names, :numbers, :work_duration, :birthday,
                  :start_work_time, :end_work_time, :created_date_time, :office_location

    def self.create_from_discriminator_value(parse_node)
      raise StandardError, 'parse_node cannot be null' if parse_node.nil?

      TestEntity.new
    end

    def initialize(additional_data: {})
      @additional_data = additional_data
    end

    def get_field_deserializers
      {
        'id' => ->(n) { @id = n.get_guid_value },
        'deviceNames' => ->(n) { @device_names = n.get_collection_of_primitive_values(String) },
        'numbers' => ->(n) { @numbers = n.get_enum_values(TEST_ENUM) },
        'workDuration' => ->(n) { @work_duration = n.get_duration_value },
        'birthDay' => ->(n) { @birthday = n.get_date_value },
        'startWorkTime' => ->(n) { @start_work_time = n.get_time_value },
        'endWorkTime' => ->(n) { @end_work_time = n.get_time_value },
        'createdDateTime' => ->(n) { @created_date_time = n.get_date_time_value },
        'officeLocation' => ->(n) { @office_location = n.get_string_value }
      }
    end

    def serialize(writer)
      raise StandardError, 'writer cannot be null' if writer.nil?

      writer.write_guid_value('id', @id)
      writer.write_collection_of_primitive_values('deviceNames', @device_names)
      writer.write_enum_value('numbers', @numbers)
      writer.write_duration_value('workDuration', @work_duration)
      writer.write_date_value('birthDay', @birthday)
      writer.write_time_value('startWorkTime', @start_work_time)
      writer.write_time_value('endWorkTime', @end_work_time)
      writer.write_date_time_value('createdDateTime', @created_date_time)
      writer.write_string_value('officeLocation', @office_location)
      writer.write_additional_data(@additional_data)
    end
  end
end
