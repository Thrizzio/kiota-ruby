# frozen_string_literal: true

require_relative 'spec_helper'
require_relative 'files/files'

RSpec.describe MicrosoftKiotaSerializationForm::FormSerializationWriter do
  subject(:writer) { described_class.new }

  let(:test_enum) { Files::TEST_ENUM }
  let(:user) do
    additional_data = {
      'otherPhones' => %w[123456789 987654321],
      'mobilePhone' => nil,
      'accountEnabled' => false,
      'jobTitle' => 'Auditor',
      'intValue' => 1,
      'floatValue' => 3.14
    }
    Files::TestEntity.new(additional_data: additional_data).tap do |user|
      user.created_date_time = DateTime.parse('2022-01-27T12:59:45.596117+00:00')
      user.work_duration = MicrosoftKiotaAbstractions::ISODuration.new({ seconds: 7200 })
      user.birthday = Date.new(2000, 9, 4)
      user.start_work_time = Time.parse('08:00:00')
      user.id = UUIDTools::UUID.parse('8f841f30-e6e3-439a-a812-ebd369559c36')
      user.numbers = [test_enum[:One], test_enum[:Eight]]
      user.device_names = %w[device1 device2]
    end
  end

  def entity(additional_data = {}) = Files::TestEntity.new(additional_data: additional_data)

  it 'writes a string value' do
    writer.write_string_value('displayName', 'Adele Vance')
    expect(writer.get_serialized_content).to eq('displayName=Adele+Vance')
  end

  it 'writes a boolean value' do
    writer.write_boolean_value('isActive', false)
    expect(writer.get_serialized_content).to eq('isActive=false')
  end

  it 'writes a number value' do
    writer.write_number_value('count', 0)
    expect(writer.get_serialized_content).to eq('count=0')
  end

  it 'writes a float value' do
    writer.write_float_value('gpa', 0.0)
    expect(writer.get_serialized_content).to eq('gpa=0.0')
  end

  it 'writes a guid value' do
    writer.write_guid_value('id', UUIDTools::UUID.parse('8f841f30-e6e3-439a-a812-ebd369559c36'))
    expect(writer.get_serialized_content).to eq('id=8f841f30-e6e3-439a-a812-ebd369559c36')
  end

  it 'writes a guid value given as a string' do
    writer.write_guid_value('id', '8f841f30-e6e3-439a-a812-ebd369559c36')
    expect(writer.get_serialized_content).to eq('id=8f841f30-e6e3-439a-a812-ebd369559c36')
  end

  it 'writes a date time value' do
    writer.write_date_time_value('updatedAt', DateTime.new(2022, 1, 27, 12, 59, 45.596117r))
    expect(writer.get_serialized_content).to eq('updatedAt=2022-01-27T12%3A59%3A45.596117%2B00%3A00')
  end

  it 'writes a date time value given as a string' do
    writer.write_date_time_value('updatedAt', '2022-01-27T12:59:45.596117')
    expect(writer.get_serialized_content).to eq('updatedAt=2022-01-27T12%3A59%3A45.596117')
  end

  it 'writes a duration value' do
    writer.write_duration_value('diff', MicrosoftKiotaAbstractions::ISODuration.new({ seconds: 7200 }))
    expect(writer.get_serialized_content).to eq('diff=PT2H')
  end

  it 'writes a date value' do
    writer.write_date_value('birthday', Date.new(2000, 9, 4))
    expect(writer.get_serialized_content).to eq('birthday=2000-09-04')
  end

  it 'writes a time value' do
    writer.write_time_value('time', Time.parse('2022-01-27T12:59:45.596117'))
    expect(writer.get_serialized_content).to eq('time=12%3A59%3A45.596117')
  end

  it 'writes a byte array value' do
    writer.write_byte_array_value('message', 'Hello world')
    expect(writer.get_serialized_content).to eq('message=SGVsbG8gd29ybGQ%3D')
  end

  it 'writes a collection of primitive values' do
    writer.write_collection_of_primitive_values('numbers', [1, 2.0, '3'])
    expect(writer.get_serialized_content).to eq('numbers=1&numbers=2.0&numbers=3')
  end

  it 'writes a collection of enum values' do
    writer.write_collection_of_enum_values('numbers', [test_enum[:Four], test_enum[:Eight]])
    expect(writer.get_serialized_content).to eq('numbers=four&numbers=eight')
  end

  it 'writes an enum value' do
    writer.write_enum_value('number', test_enum[:Four])
    expect(writer.get_serialized_content).to eq('number=four')
  end

  it 'writes a flags enum value' do
    writer.write_enum_value('number', [test_enum[:Four], test_enum[:Eight]])
    expect(writer.get_serialized_content).to eq('number=four%2Ceight')
  end

  it 'does not support collections of objects' do
    expect { writer.write_collection_of_object_values('users', [entity]) }
      .to raise_error(StandardError, 'Form serialization does not support collections.')
  end

  it 'writes a named root object flat, as .NET does' do
    writer.write_object_value('user', user)
    expect(writer.get_serialized_content).to eq(
      'id=8f841f30-e6e3-439a-a812-ebd369559c36&' \
      'deviceNames=device1&deviceNames=device2&' \
      'numbers=one%2Ceight&' \
      'workDuration=PT2H&' \
      'birthDay=2000-09-04&' \
      'startWorkTime=08%3A00%3A00&' \
      'createdDateTime=2022-01-27T12%3A59%3A45.596117%2B00%3A00&' \
      'otherPhones=123456789&otherPhones=987654321&' \
      'accountEnabled=false&' \
      'jobTitle=Auditor&' \
      'intValue=1&' \
      'floatValue=3.14'
    )
  end

  [nil, ''].each do |key|
    it "writes a root object value with the key #{key.inspect}" do
      writer.write_object_value(key, entity('body' => 'example', 'title' => 'a&b'))
      expect(writer.get_serialized_content).to eq('body=example&title=a%26b')
    end
  end

  it 'writes a root object after an existing field' do
    writer.write_string_value('first', 'value')
    writer.write_object_value(nil, entity('body' => 'example'))
    expect(writer.get_serialized_content).to eq('first=value&body=example')
  end

  it 'writes a root object with additional values' do
    writer.write_object_value(nil, entity('body' => 'example'), entity('title' => 'example title'))
    expect(writer.get_serialized_content).to eq('body=example&title=example+title')
  end

  it 'writes an empty root object' do
    writer.write_object_value(nil, entity)
    expect(writer.get_serialized_content).to eq('')
  end

  [nil, ''].each do |key|
    it "writes an empty root object with the key #{key.inspect} between fields" do
      writer.write_string_value('first', 'value')
      writer.write_object_value(key, entity)
      expect(writer.get_serialized_content).to eq('first=value')
      writer.write_object_value(nil, entity('last' => 'value'))
      expect(writer.get_serialized_content).to eq('first=value&last=value')
    end
  end

  it 'writes nothing for an empty named root object' do
    writer.write_string_value('first', 'value')
    writer.write_object_value('empty', entity)
    expect(writer.get_serialized_content).to eq('first=value')
  end
end

RSpec.describe MicrosoftKiotaSerializationForm::FormSerializationWriter, 'edge cases' do
  subject(:writer) { described_class.new }

  let(:test_enum) { Files::TEST_ENUM }
  # a composed type writes its member with a nil key, as generated code does
  let(:wrapper_class) do
    Class.new do
      include MicrosoftKiotaAbstractions::Parsable

      def initialize(member)
        @member = member
      end

      def serialize(writer) = writer.write_object_value(nil, @member)
    end
  end

  def entity(additional_data = {}) = Files::TestEntity.new(additional_data: additional_data)

  it 'does not strip string values' do
    writer.write_string_value('name', ' padded ')
    expect(writer.get_serialized_content).to eq('name=+padded+')
  end

  it 'writes symbols and strings in a collection of primitive values, skipping nils' do
    writer.write_collection_of_primitive_values('values', [:Red, nil, test_enum[:Four]])
    expect(writer.get_serialized_content).to eq('values=Red&values=four')
  end

  it 'raises on a model nested in a model' do
    parent = Class.new do
      include MicrosoftKiotaAbstractions::Parsable

      def serialize(writer) = writer.write_object_value('child', Files::TestEntity.new)
    end

    expect { writer.write_object_value(nil, parent.new) }
      .to raise_error(StandardError, 'Form serialization does not support nested objects.')
  end

  it 'writes falsy additional data' do
    writer.write_additional_data('enabled' => false, 'count' => 0, 'ratio' => 0.0, 'note' => '', 'tags' => [])
    expect(writer.get_serialized_content).to eq('enabled=false&count=0&ratio=0.0&note=')
  end

  it 'writes nothing for a nil collection of objects, as generated models pass for unset properties' do
    writer.write_collection_of_object_values('items', nil)
    expect(writer.get_serialized_content).to eq('')
  end

  it 'writes nothing for a named nil object' do
    writer.write_object_value('missing', nil)
    expect(writer.get_serialized_content).to eq('')
  end

  describe 'values' do
    it 'writes an empty string' do
      writer.write_string_value('note', '')
      expect(writer.get_serialized_content).to eq('note=')
    end

    it 'skips a nil value or a missing key' do
      writer.write_string_value('note', nil)
      writer.write_number_value(nil, 1)
      writer.write_string_value('', 'value')
      expect(writer.get_serialized_content).to eq('')
    end

    it 'writes a null value' do
      writer.write_null_value('note')
      expect(writer.get_serialized_content).to eq('note=null')
    end

    it 'writes a time value with an offset as a date time in additional data' do
      writer.write_additional_data('at' => Time.utc(2022, 1, 27, 12, 59, 45))
      expect(writer.get_serialized_content).to eq('at=2022-01-27T12%3A59%3A45Z')
    end

    it 'raises on a hash in additional data' do
      expect { writer.write_additional_data('nested' => { 'a' => 1 }) }
        .to raise_error(StandardError, 'Form serialization does not support nested objects.')
    end

    it 'raises on a model in additional data' do
      expect { writer.write_additional_data('nested' => entity) }
        .to raise_error(StandardError, 'Form serialization does not support nested objects.')
    end

    it 'raises on an unknown type' do
      expect { writer.write_any_value('range', 1..2) }
        .to raise_error(StandardError, 'Encountered an unknown type during serialization Range with key range')
    end
  end

  describe 'composed types' do
    it 'merges a member written with a nil key into the enclosing object' do
      writer.write_object_value(nil, wrapper_class.new(entity('body' => 'example')))
      expect(writer.get_serialized_content).to eq('body=example')
    end
  end

  describe 'hooks' do
    it 'calls the hooks around each model, with the writer that receives its fields' do
      calls = []
      model = entity('body' => 'example')
      writer.on_before_object_serialization = ->(value) { calls << [:before, value] }
      writer.on_start_object_serialization = lambda do |value, target|
        calls << [:start, value]
        target.write_null_value('cleared')
      end
      writer.on_after_object_serialization = ->(value) { calls << [:after, value] }

      writer.write_object_value(nil, model)
      expect(calls).to eq([[:before, model], [:start, model], [:after, model]])
      expect(writer.get_serialized_content).to eq('cleared=null&body=example')
    end

    it 'calls the after hook when the model raises' do
      calls = []
      model = entity
      allow(model).to receive(:serialize).and_raise(StandardError, 'boom')
      writer.on_after_object_serialization = ->(value) { calls << value }

      expect { writer.write_object_value(nil, model) }.to raise_error(StandardError, 'boom')
      expect(calls).to eq([model])
    end

    it 'gives nested writers the same hooks' do
      calls = []
      member = entity('body' => 'example')
      wrapper = wrapper_class.new(member)
      writer.on_before_object_serialization = ->(value) { calls << value }

      writer.write_object_value(nil, wrapper)
      expect(calls).to eq([wrapper, member])
    end
  end
end
