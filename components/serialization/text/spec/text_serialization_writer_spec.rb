# frozen_string_literal: true

require_relative 'spec_helper'
require_relative 'files/files'

RSpec.describe MicrosoftKiotaSerializationText::TextSerializationWriter do
  subject(:writer) { described_class.new }

  let(:structured_data_error) { [StandardError, 'Text does not support structured data'] }
  let(:two_hours) { MicrosoftKiotaAbstractions::ISODuration.new(hours: 2) }
  let(:user1) { Files::User.new }
  let(:user2) { Files::User.new }

  it 'writes a string value' do
    writer.write_string_value('', 'Adele Vance')
    expect(writer.get_serialized_content).to eq('Adele Vance')
  end

  it 'raises when writing a string value with a key' do
    expect { writer.write_string_value('displayName', 'Adele Vance') }.to raise_error(*structured_data_error)
  end

  it 'writes a boolean value' do
    writer.write_boolean_value(nil, true)
    expect(writer.get_serialized_content).to eq('true')
  end

  it 'raises when writing a boolean value with a key' do
    expect { writer.write_boolean_value('isActive', true) }.to raise_error(*structured_data_error)
  end

  it 'writes a number value' do
    writer.write_number_value('', 28_192_199_291_929_192)
    expect(writer.get_serialized_content).to eq('28192199291929192')
  end

  it 'raises when writing a number value with a key' do
    expect { writer.write_number_value('timestamp', 28_192_199_291_929_192) }.to raise_error(*structured_data_error)
  end

  it 'writes a float value' do
    writer.write_float_value('', 3.2)
    expect(writer.get_serialized_content).to eq('3.2')
  end

  it 'raises when writing a float value with a key' do
    expect { writer.write_float_value('gpa', 3.2) }.to raise_error(*structured_data_error)
  end

  it 'writes a guid value' do
    writer.write_guid_value('', UUIDTools::UUID.parse('8f841f30-e6e3-439a-a812-ebd369559c36'))
    expect(writer.get_serialized_content).to eq('8f841f30-e6e3-439a-a812-ebd369559c36')
  end

  it 'raises when writing a guid value with a key' do
    uuid = UUIDTools::UUID.parse('8f841f30-e6e3-439a-a812-ebd369559c36')
    expect { writer.write_guid_value('id', uuid) }.to raise_error(*structured_data_error)
  end

  it 'writes a date time value' do
    writer.write_date_time_value('', DateTime.iso8601('2022-01-27T12:59:45.596117'))
    expect(writer.get_serialized_content).to eq('2022-01-27T12:59:45.596117+00:00')
  end

  it 'raises when writing a date time value with a key' do
    date_time = DateTime.iso8601('2022-01-27T12:59:45.596117')
    expect { writer.write_date_time_value('updatedAt', date_time) }.to raise_error(*structured_data_error)
  end

  it 'writes a duration value' do
    writer.write_duration_value('', two_hours)
    expect(writer.get_serialized_content).to eq('PT2H')
  end

  it 'raises when writing a duration value with a key' do
    expect { writer.write_duration_value('diff', two_hours) }.to raise_error(*structured_data_error)
  end

  it 'writes a date value' do
    writer.write_date_value('', Date.iso8601('2000-09-04'))
    expect(writer.get_serialized_content).to eq('2000-09-04')
  end

  it 'raises when writing a date value with a key' do
    expect { writer.write_date_value('birthday', Date.iso8601('2000-09-04')) }.to raise_error(*structured_data_error)
  end

  it 'writes a time value' do
    writer.write_time_value('', Time.parse('2022-01-27T12:59:45.596117'))
    expect(writer.get_serialized_content).to eq('12:59:45.596117')
  end

  it 'raises when writing a time value with a key' do
    time = Time.parse('2022-01-27T12:59:45.596117')
    expect { writer.write_time_value('time', time) }.to raise_error(*structured_data_error)
  end

  it 'raises when writing a collection of primitive values' do
    values = ['+1 412 555 0109', 1]
    expect { writer.write_collection_of_primitive_values('businessPhones', values) }.to raise_error(*structured_data_error)
  end

  it 'raises when writing a collection of object values' do
    expect { writer.write_collection_of_object_values('users', [user1, user2]) }.to raise_error(*structured_data_error)
  end

  it 'raises when writing a collection of enum values' do
    values = Files::OFFICE_LOCATION.values_at(:Dunhill, :Oval)
    expect { writer.write_collection_of_enum_values('officeLocation', values) }.to raise_error(*structured_data_error)
  end

  it 'raises when writing an object value' do
    expect { writer.write_object_value('user1', user1) }.to raise_error(*structured_data_error)
  end

  it 'writes an enum value' do
    writer.write_enum_value('', Files::OFFICE_LOCATION[:Dunhill])
    expect(writer.get_serialized_content).to eq('dunhill')
  end

  it 'raises when writing an enum value with a key' do
    expect { writer.write_enum_value('officeLocation', Files::OFFICE_LOCATION[:Dunhill]) }.to raise_error(*structured_data_error)
  end

  it 'writes a null value' do
    writer.write_null_value('')
    expect(writer.get_serialized_content).to eq('null')
  end

  it 'raises when writing a null value with a key' do
    expect { writer.write_null_value('mobilePhone') }.to raise_error(*structured_data_error)
  end

  it 'raises when writing additional data' do
    additional_data = {
      '@odata.context' => 'https://graph.microsoft.com/v1.0/$metadata#users/$entity',
      'businessPhones' => ['+1 205 555 0108']
    }
    expect { writer.write_additional_data(additional_data) }.to raise_error(*structured_data_error)
  end

  it 'writes a byte array value as base64' do
    writer.write_byte_array_value(nil, 'Samwel is the best')
    expect(writer.get_serialized_content).to eq('U2Ftd2VsIGlzIHRoZSBiZXN0')
  end

  it 'raises when a second value is written' do
    writer.write_string_value(nil, 'first')
    expect { writer.write_string_value(nil, 'second') }.to raise_error(
      StandardError,
      'a value was already written for this serialization writer, text content only supports a single value'
    )
  end

  it 'writes an empty body when no content was written, as .NET does' do
    writer.write_string_value(nil, '')
    expect(writer.get_serialized_content).to eq('')
  end

  it 'raises when a value follows an empty one' do
    writer.write_string_value(nil, '')
    expect { writer.write_string_value(nil, 'second') }.to raise_error(StandardError, /a value was already written/)
  end

  it 'writes a string held in bytes as UTF-8' do
    writer.write_string_value(nil, 'café'.b)
    expect(writer.get_serialized_content).to eq('café')
  end

  describe 'edge cases' do
    it 'writes a zero number' do
      writer.write_number_value(nil, 0)
      expect(writer.get_serialized_content).to eq('0')
    end

    it 'writes a zero float' do
      writer.write_float_value(nil, 0.0)
      expect(writer.get_serialized_content).to eq('0.0')
    end

    it 'writes a duration as ISO 8601 that reads back to the same duration' do
      writer.write_duration_value(nil, two_hours)
      content = writer.get_serialized_content
      expect(content).to eq('PT2H')
      expect(MicrosoftKiotaSerializationText::TextParseNode.new(content).get_duration_value).to eq(two_hours)
    end
  end
end

RSpec.describe MicrosoftKiotaSerializationText::TextSerializationWriter, '#write_any_value' do
  subject(:writer) { described_class.new }

  let(:structured_data_error) { [StandardError, 'Text does not support structured data'] }
  let(:two_hours) { MicrosoftKiotaAbstractions::ISODuration.new(hours: 2) }

  it 'writes any scalar value' do
    uuid = UUIDTools::UUID.parse('8f841f30-e6e3-439a-a812-ebd369559c36')
    {
      'hi' => 'hi', 42 => '42', 1.5 => '1.5', false => 'false', uuid => uuid.to_s, two_hours => 'PT2H',
      Date.new(2000, 9, 4) => '2000-09-04', DateTime.new(2024, 1, 2, 3, 4, 5) => '2024-01-02T03:04:05+00:00',
      Time.utc(2024, 1, 2, 3, 4, 5) => '03:04:05', :dunhill => 'dunhill'
    }.each do |value, expected|
      text_writer = described_class.new
      text_writer.write_any_value(nil, value)
      expect(text_writer.get_serialized_content).to eq(expected), value.inspect
    end
  end

  it 'raises for a structured or unknown value' do
    expect { writer.write_any_value(nil, [1, 2]) }.to raise_error(*structured_data_error)
    expect { writer.write_any_value(nil, { 'a' => 1 }) }.to raise_error(*structured_data_error)
    expect { writer.write_any_value(nil, Rational(1, 3)) }.to raise_error(StandardError, /unknown value type/)
  end
end
