# frozen_string_literal: true

require_relative 'spec_helper'
require_relative 'files/files'

RSpec.describe MicrosoftKiotaSerializationForm::FormParseNode do
  let(:test_user_form) do
    'displayName=Megan+Bowen&' \
      'numbers=one,two&' \
      'givenName=Megan&' \
      'accountEnabled=true&' \
      'createdDateTime=2017-07-29T03:07:25Z&' \
      'jobTitle=Auditor&' \
      'mail=MeganB@M365x214355.onmicrosoft.com&' \
      'mobilePhone=null&' \
      'officeLocation=null&' \
      'preferredLanguage=en-US&' \
      'surname=Bowen&' \
      'workDuration=PT1H&' \
      'startWorkTime=08:00:00.0000000&' \
      'endWorkTime=17:00:00.0000000&' \
      'userPrincipalName=MeganB@M365x214355.onmicrosoft.com&' \
      'birthDay=2017-09-04&' \
      'deviceNames=device1&deviceNames=device2&' \
      'otherPhones=123456789&otherPhones=987654321&' \
      'id=48d31887-5fad-4d73-a9f5-3c356e68a038'
  end
  let(:entity_factory) { ->(node) { Files::TestEntity.create_from_discriminator_value(node) } }
  let(:test_enum) { Files::TEST_ENUM }

  def node(raw) = described_class.new(raw)

  it 'gets a string value' do
    expect(node('Megan+Bowen').get_string_value).to eq('Megan Bowen')
  end

  it 'gets a number value' do
    expect(node('1454').get_number_value).to eq(1454)
  end

  it 'gets a boolean value' do
    expect(node('false').get_boolean_value).to be(false)
  end

  it 'gets a float value' do
    expect(node('44.6').get_float_value).to eq(44.6)
  end

  it 'gets a guid value' do
    expect(node('f58411c7-ae78-4d3c-bb0d-3f24d948de41').get_guid_value)
      .to eq(UUIDTools::UUID.parse('f58411c7-ae78-4d3c-bb0d-3f24d948de41'))
  end

  it 'gets a date time value' do
    expect(node('2022-01-27T12:59:45.596117').get_date_time_value).to be_a(DateTime)
  end

  it 'gets a date value' do
    result = node('2015-04-20').get_date_value
    expect(result).to be_a(Date)
    expect(result.to_s).to eq('2015-04-20')
  end

  it 'gets a time value' do
    result = node('12:59:45.596117').get_time_value
    expect(result).to be_a(Time)
    expect(result.strftime('%H:%M:%S.%6N')).to eq('12:59:45.596117')
  end

  it 'gets a duration value' do
    result = node('PT30S').get_duration_value
    expect(result).to be_a(MicrosoftKiotaAbstractions::ISODuration)
    expect(result.seconds).to eq(30)
    expect(result.string).to eq('PT30S')
  end

  it 'gets a byte array value' do
    expect(node('SGVsbG8gd29ybGQ%3D').get_byte_array_value).to eq('Hello world'.b)
  end

  it 'gets a collection of numerical primitive values' do
    number_node = node('numbers=1&numbers=2&numbers=3&').get_child_node('numbers')

    expect(number_node.get_collection_of_primitive_values(Integer)).to eq([1, 2, 3])
    expect(number_node.get_collection_of_primitive_values(String)).to eq(%w[1 2 3])
    expect(number_node.get_collection_of_primitive_values(Float)).to eq([1.0, 2.0, 3.0])
  end

  it 'gets a collection of boolean primitive values' do
    boolean_node = node('booleans=true&booleans=false&booleans=true&').get_child_node('booleans')

    expect(boolean_node.get_collection_of_primitive_values('boolean')).to eq([true, false, true])
    expect(boolean_node.get_collection_of_primitive_values(String)).to eq(%w[true false true])
  end

  it 'gets a collection of guid primitive values' do
    id = '8f841f30-e6e3-439a-a812-ebd369559c36'
    uuid_node = node("uuids=#{id}&uuids=#{id}&uuids=#{id}&").get_child_node('uuids')

    expect(uuid_node.get_collection_of_primitive_values(UUIDTools::UUID)).to eq([UUIDTools::UUID.parse(id)] * 3)
    expect(uuid_node.get_collection_of_primitive_values(String)).to eq([id] * 3)
  end

  it 'raises when the primitive type of a collection is missing' do
    expect { node('numbers=1&numbers=2&numbers=3&').get_collection_of_primitive_values(nil) }
      .to raise_error(StandardError, 'Primitive type for deserialization cannot be null')
  end

  it 'gets a collection of enum values' do
    enum_node = node('numbers=one&numbers=two&numbers=four&').get_child_node('numbers')

    expect(enum_node.get_collection_of_enum_values(test_enum))
      .to eq([test_enum[:One], test_enum[:Two], test_enum[:Four]])
  end

  it 'reads nil for an enum value the enum does not declare' do
    enum_node = node('numbers=one&numbers=two&numbers=thirty+two&').get_child_node('numbers')

    expect(enum_node.get_collection_of_enum_values(test_enum)).to eq([test_enum[:One], test_enum[:Two], nil])
  end

  it 'does not support collections of objects' do
    expect { node(test_user_form).get_collection_of_object_values(entity_factory) }
      .to raise_error(StandardError, /Collection of object values is not supported /)
  end

  it 'gets an object value' do
    result = node(test_user_form).get_object_value(entity_factory)

    expect(result).to be_a(Files::TestEntity)
    expect(result.id).to eq(UUIDTools::UUID.parse('48d31887-5fad-4d73-a9f5-3c356e68a038'))
    expect(result.device_names).to eq(%w[device1 device2])
    expect(result.numbers).to eq([test_enum[:One], test_enum[:Two]])
    expect(result.work_duration).to eq(MicrosoftKiotaAbstractions::ISODuration.new({ hours: 1 }))
    expect(result.birthday).to eq(Date.new(2017, 9, 4))
    expect([result.start_work_time.hour, result.start_work_time.min, result.start_work_time.sec]).to eq([8, 0, 0])
    expect([result.end_work_time.hour, result.end_work_time.min, result.end_work_time.sec]).to eq([17, 0, 0])
    expect(result.created_date_time).to be_a(DateTime)
    expect(result.office_location).to be_nil
    expect(result.additional_data['otherPhones']).to eq('123456789,987654321')
    expect(result.additional_data['mobilePhone']).to eq('null')
    expect(result.additional_data['accountEnabled']).to eq('true')
    expect(result.additional_data['jobTitle']).to eq('Auditor')
  end

  it 'returns nil when the child node does not exist' do
    expect(node(test_user_form).get_child_node('nonExistent')).to be_nil
  end
end

RSpec.describe MicrosoftKiotaSerializationForm::FormParseNode, 'edge cases' do
  let(:entity_factory) { ->(node) { Files::TestEntity.create_from_discriminator_value(node) } }
  let(:test_enum) { Files::TEST_ENUM }

  def node(raw) = described_class.new(raw)

  it 'matches keys case-insensitively' do
    parse_node = node('DisplayName=Megan&ID=48d31887-5fad-4d73-a9f5-3c356e68a038&devicenames=a&DeviceNames=b')

    expect(parse_node.get_child_node('displayName').get_string_value).to eq('Megan')
    result = parse_node.get_object_value(entity_factory)
    expect(result.id).to eq(UUIDTools::UUID.parse('48d31887-5fad-4d73-a9f5-3c356e68a038'))
    expect(result.device_names).to eq(%w[a b])
  end

  it 'passes the hooks on to child nodes' do
    before = ->(_item) {}
    after = ->(_item) {}
    parse_node = node('name=value')
    parse_node.on_before_assign_field_values = before
    parse_node.on_after_assign_field_values = after

    child = parse_node.get_child_node('name')
    expect(child.on_before_assign_field_values).to be(before)
    expect(child.on_after_assign_field_values).to be(after)
  end

  it 'keeps a comma inside an item of a repeated key' do
    tags = node('tags=Lee%2C+Ann&tags=Bob').get_child_node('tags')

    expect(tags.get_collection_of_primitive_values(String)).to eq(['Lee, Ann', 'Bob'])
  end

  it 'skips only the exact null sentinel, as Python does, so a value like Null is kept' do
    expect(node('officeLocation=Null').get_object_value(entity_factory).office_location).to eq('Null')
    expect(node('officeLocation=null').get_object_value(entity_factory).office_location).to be_nil
  end

  it 'keeps literal spaces around keys and values, as the standard form decoder does' do
    expect(node('officeLocation= padded ').get_child_node('officeLocation').get_string_value).to eq(' padded ')
    expect(node(' key =1').get_child_node(' key ').get_number_value).to eq(1)
  end

  it 'reads back an empty string the writer wrote' do
    writer = MicrosoftKiotaSerializationForm::FormSerializationWriter.new
    writer.write_string_value('note', '')

    expect(node(writer.get_serialized_content).get_child_node('note').get_string_value).to eq('')
  end

  it 'reads back a single item that contains a comma' do
    writer = MicrosoftKiotaSerializationForm::FormSerializationWriter.new
    writer.write_collection_of_primitive_values('tags', ['Lee, Ann'])
    tags = node(writer.get_serialized_content).get_child_node('tags')

    expect(tags.get_collection_of_primitive_values(String)).to eq(['Lee, Ann'])
    expect(node('tags=a,b').get_child_node('tags').get_collection_of_primitive_values(String)).to eq(%w[a b])
  end

  it 'replaces invalid UTF-8 even when the body is tagged as UTF-8' do
    body = (+"name=caf\xE9").force_encoding(Encoding::UTF_8)

    expect(node(body).get_child_node('name').get_string_value).to eq("caf\uFFFD")
  end

  it 'decodes each item of a collection once' do
    values = node('values=a%2Bb&values=100%25').get_child_node('values')

    expect(values.get_collection_of_primitive_values(String)).to eq(['a+b', '100%'])
  end

  it 'stores unknown keys as decoded strings' do
    form = 'note=a+b%26c&when=2017-07-29T03%3A07%3A25Z&ref=48d31887-5fad-4d73-a9f5-3c356e68a038'
    result = node(form).get_object_value(entity_factory)

    expect(result.additional_data).to eq(
      'note' => 'a b&c',
      'when' => '2017-07-29T03:07:25Z',
      'ref' => '48d31887-5fad-4d73-a9f5-3c356e68a038'
    )
  end

  describe 'scalars' do
    it 'returns nil for an empty value or null' do
      expect(node('null').get_string_value).to be_nil
      expect(node('').get_number_value).to be_nil
      expect(node('null').get_number_value).to be_nil
      expect(node('null').get_enum_value(test_enum)).to be_nil
    end

    it 'returns nil when the value does not parse' do
      expect(node('abc').get_number_value).to be_nil
      expect(node('abc').get_float_value).to be_nil
      expect(node('abc').get_guid_value).to be_nil
      expect(node('abc').get_date_value).to be_nil
      expect(node('abc').get_duration_value).to be_nil
      expect(node('!!').get_byte_array_value).to be_nil
    end

    it 'reads only true or false as a boolean, so a union can tell it from a string' do
      expect(node('auto').get_boolean_value).to be_nil
      expect([node('TRUE').get_boolean_value, node('false').get_boolean_value]).to eq([true, false])
    end

    it 'reads a date, time or date time only in its own shape, as the Go form node does' do
      expect([node('2017-09-04').get_date_value, node('2017-09-04').get_date_time_value, node('2017-09-04').get_time_value])
        .to eq([Date.new(2017, 9, 4), nil, nil])
      expect([node('2017-07-29T03:07:25Z').get_date_value, node('2017-07-29T03:07:25Z').get_time_value]).to eq([nil, nil])
      expect(node('2017-07-29T03:07:25Z').get_date_time_value).to eq(DateTime.new(2017, 7, 29, 3, 7, 25))
      expect([node('08:00:00').get_date_value, node('08:00:00').get_date_time_value]).to eq([nil, nil])
      expect(node('08:00:00.0000000').get_time_value.strftime('%H:%M:%S')).to eq('08:00:00')
    end

    it 'keeps a stray percent sign' do
      expect(node('100%+sure').get_string_value).to eq('100% sure')
    end
  end

  describe 'enums' do
    it 'reads a flags value as an Array of members' do
      expect(node('one,four').get_enum_values(test_enum)).to eq([test_enum[:One], test_enum[:Four]])
    end

    it 'reads a single member from a scalar enum, like the JSON gem' do
      expect(node('one,four').get_enum_value(test_enum)).to eq(test_enum[:One])
    end

    it 'reads nil for an unknown member, like the JSON gem' do
      expect(node('five').get_enum_value(test_enum)).to be_nil
      expect(node('one,five').get_enum_values(test_enum)).to eq([test_enum[:One], nil])
    end

    it 'falls back to the member name, like the JSON gem' do
      expect(node('Four').get_enum_value(test_enum)).to eq(test_enum[:Four])
    end
  end

  describe 'round trip' do
    it 'reads back what the writer wrote' do
      original = Files::TestEntity.new(additional_data: { 'accountEnabled' => false, 'count' => 0 })
      original.id = UUIDTools::UUID.parse('8f841f30-e6e3-439a-a812-ebd369559c36')
      original.device_names = ['dev 1', 'dev+2']
      original.numbers = [test_enum[:One], test_enum[:Eight]]
      original.work_duration = MicrosoftKiotaAbstractions::ISODuration.new('PT2H')
      original.birthday = Date.new(2000, 9, 4)
      original.created_date_time = DateTime.parse('2022-01-27T12:59:45.596117+01:00')
      original.office_location = 'a&b=c'
      writer = MicrosoftKiotaSerializationForm::FormSerializationWriter.new
      writer.write_object_value(nil, original)

      result = node(writer.get_serialized_content).get_object_value(entity_factory)
      expect(result.id).to eq(original.id)
      expect(result.device_names).to eq(original.device_names)
      expect(result.numbers).to eq(original.numbers)
      expect(result.work_duration).to eq(original.work_duration)
      expect(result.birthday).to eq(original.birthday)
      expect(result.created_date_time).to eq(original.created_date_time)
      expect(result.office_location).to eq(original.office_location)
      expect(result.additional_data).to eq('accountEnabled' => 'false', 'count' => '0')
    end
  end
end

RSpec.describe MicrosoftKiotaSerializationForm::FormParseNode, 'hooks' do
  def node(raw) = described_class.new(raw)

  it 'calls the hooks around the field assignment, even when it raises' do
    calls = []
    parse_node = node('id=1')
    parse_node.on_before_assign_field_values = ->(item) { calls << [:before, item] }
    parse_node.on_after_assign_field_values = ->(item) { calls << [:after, item] }
    failing = Files::TestEntity.new
    allow(failing).to receive(:get_field_deserializers).and_raise(StandardError, 'boom')

    expect { parse_node.get_object_value(->(_node) { failing }) }.to raise_error(StandardError, 'boom')
    expect(calls).to eq([[:before, failing], [:after, failing]])
  end

  it 'gives the field nodes the same hooks' do
    seen = nil
    before = ->(_item) {}
    parse_node = node('name=value')
    parse_node.on_before_assign_field_values = before
    item = Files::TestEntity.new
    allow(item).to receive(:get_field_deserializers)
      .and_return('name' => ->(field) { seen = field.on_before_assign_field_values })

    parse_node.get_object_value(->(_node) { item })
    expect(seen).to be(before)
  end
end
