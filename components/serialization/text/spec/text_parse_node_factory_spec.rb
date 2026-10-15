# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe MicrosoftKiotaSerializationText::TextParseNodeFactory do
  subject(:factory) { described_class.new }

  let(:sample_text_string) { 'Microsoft Graph'.encode(Encoding::UTF_8).b }

  it 'gets a root parse node' do
    expect(factory.get_parse_node('text/plain', sample_text_string)).to be_a(MicrosoftKiotaSerializationText::TextParseNode)
  end

  it 'raises without a content type' do
    expect { factory.get_parse_node('', sample_text_string) }.to raise_error(ArgumentError, 'content type cannot be undefined or empty')
  end

  it 'raises for an unsupported content type' do
    expect { factory.get_parse_node('application/xml', sample_text_string) }.to raise_error(
      ArgumentError, 'expected a text/plain content type'
    )
  end

  it 'raises for empty content' do
    expect { factory.get_parse_node('text/plain', ''.b) }.to raise_error(ArgumentError, 'content cannot be undefined or empty')
  end

  it 'matches the content type ignoring case' do
    expect(factory.get_parse_node('Text/Plain', sample_text_string).get_string_value).to eq('Microsoft Graph')
  end

  it 'reads a body still in bytes as UTF-8' do
    node = factory.get_parse_node('text/plain', 'café'.b)
    expect(node.get_string_value).to eq('café')
  end

  it 'converts a body tagged with another charset, as Faraday tags it' do
    node = factory.get_parse_node('text/plain', 'café'.encode(Encoding::ISO_8859_1))
    expect(node.get_string_value).to eq('café')
    expect(node.get_string_value).to be_valid_encoding
  end

  it 'drops a byte order mark' do
    node = factory.get_parse_node('text/plain', "\uFEFF42".b)
    expect([node.get_string_value, node.get_number_value]).to eq(['42', 42])
  end

  it 'gets the valid content type' do
    expect(factory.get_valid_content_type).to eq('text/plain')
  end
end
