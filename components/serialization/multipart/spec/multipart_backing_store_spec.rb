# frozen_string_literal: true

require_relative 'spec_helper'
require 'microsoft_kiota_serialization_json'

module BackedMultipartModels
  class User
    include MicrosoftKiotaAbstractions::Parsable
    include MicrosoftKiotaAbstractions::BackedModel

    def initialize
      @backing_store = MicrosoftKiotaAbstractions::BackingStoreFactorySingleton.instance.create_backing_store
    end

    %w[id name].each do |property|
      define_method(property) { @backing_store.get(property) }
      define_method("#{property}=") { |value| @backing_store.set(property, value) }
    end

    def get_field_deserializers
      { 'id' => ->(n) { self.id = n.get_string_value }, 'name' => ->(n) { self.name = n.get_string_value } }
    end

    def serialize(writer)
      writer.write_string_value('id', id)
      writer.write_string_value('name', name)
    end
  end
end

RSpec.describe 'a multipart body with the backing store' do
  let(:registry) do
    MicrosoftKiotaAbstractions::SerializationWriterFactoryRegistry.new.tap do |registry|
      factories = registry.content_type_associated_factories
      factories['application/json'] = proxy(MicrosoftKiotaSerializationJson::JsonSerializationWriterFactory.new)
      factories['multipart/form-data'] = proxy(MicrosoftKiotaSerializationMultipart::MultipartSerializationWriterFactory.new)
    end
  end
  let(:adapter) { double('adapter', get_serialization_writer_factory: registry) }
  let(:user) do
    MicrosoftKiotaAbstractions::BackingStoreParseNodeFactory.new(MicrosoftKiotaSerializationJson::JsonParseNodeFactory.new)
                                                            .get_parse_node('application/json', '{"id":"u1","name":"Ann"}')
                                                            .get_object_value(->(_) { BackedMultipartModels::User.new })
  end

  def proxy(factory) = MicrosoftKiotaAbstractions::BackingStoreSerializationWriterProxyFactory.new(factory)

  def json_parts(body)
    request_info = MicrosoftKiotaAbstractions::RequestInformation.new
    request_info.set_content_from_parsable(adapter, 'multipart/form-data', body)
    request_info.content.scan(/\r\n\r\n(\{.*?\})\r\n/).flatten
  end

  def body_with(parts)
    MicrosoftKiotaAbstractions::MultipartBody.new.tap do |body|
      parts.each { |name, content_type, value| body.add_or_replace_part(name, content_type, value) }
    end
  end

  it 'writes the changes of a model in every part it appears in' do
    user.name = 'Bea'
    body = body_with([['first', 'application/json', user], ['second', 'application/json', user]])
    expect(json_parts(body)).to eq(['{"name":"Bea"}', '{"name":"Bea"}'])
  end

  it 'keeps the changes of a model when a later part fails' do
    user.name = 'Bea'
    body = body_with([['first', 'application/json', user], ['broken', 'text/plain', 42]])
    expect { json_parts(body) }.to raise_error(StandardError)
    body.remove_part('broken')
    expect(json_parts(body)).to eq(['{"name":"Bea"}'])
  end

  it 'marks the models clean once the whole body is written' do
    user.name = 'Bea'
    body = body_with([['first', 'application/json', user]])
    json_parts(body)
    expect(json_parts(body)).to eq(['{}'])
  end
end
