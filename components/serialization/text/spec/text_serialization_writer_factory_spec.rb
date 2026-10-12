# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe MicrosoftKiotaSerializationText::TextSerializationWriterFactory do
  subject(:factory) { described_class.new }

  it 'gets a serialization writer' do
    expect(factory.get_serialization_writer('text/plain')).to be_a(MicrosoftKiotaSerializationText::TextSerializationWriter)
  end

  it 'raises without a content type' do
    expect { factory.get_serialization_writer('') }.to raise_error(ArgumentError, 'content type cannot be undefined or empty')
  end

  it 'raises for an unsupported content type' do
    expect { factory.get_serialization_writer('application/xml') }.to raise_error(
      ArgumentError, 'expected a text/plain content type'
    )
  end

  it 'matches the content type ignoring case' do
    expect(factory.get_serialization_writer('TEXT/PLAIN')).to be_a(MicrosoftKiotaSerializationText::TextSerializationWriter)
  end

  it 'gets the valid content type' do
    expect(factory.get_valid_content_type).to eq('text/plain')
  end
end
