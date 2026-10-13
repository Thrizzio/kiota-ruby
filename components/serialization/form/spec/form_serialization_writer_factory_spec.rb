# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe MicrosoftKiotaSerializationForm::FormSerializationWriterFactory do
  subject(:factory) { described_class.new }

  let(:form_content_type) { 'application/x-www-form-urlencoded' }

  it 'gets a serialization writer' do
    expect(factory.get_serialization_writer(form_content_type))
      .to be_a(MicrosoftKiotaSerializationForm::FormSerializationWriter)
  end

  it 'raises without a content type' do
    expect { factory.get_serialization_writer('') }
      .to raise_error(ArgumentError, 'content type cannot be undefined or empty')
  end

  it 'raises on an unsupported content type' do
    expect { factory.get_serialization_writer('application/xml') }
      .to raise_error(ArgumentError, "expected a #{form_content_type} content type")
  end

  it 'gets the valid content type' do
    expect(factory.get_valid_content_type).to eq(form_content_type)
  end

  it 'matches the content type case-insensitively' do
    expect(factory.get_serialization_writer(form_content_type.upcase))
      .to be_a(MicrosoftKiotaSerializationForm::FormSerializationWriter)
  end
end
