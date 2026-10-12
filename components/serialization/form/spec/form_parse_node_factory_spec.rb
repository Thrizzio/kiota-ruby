# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe MicrosoftKiotaSerializationForm::FormParseNodeFactory do
  subject(:factory) { described_class.new }

  let(:form_content_type) { 'application/x-www-form-urlencoded' }
  let(:sample_form_string) { 'name=Tesla&age=2&city=New+York' }

  it 'gets a root parse node' do
    expect(factory.get_parse_node(form_content_type, sample_form_string))
      .to be_a(MicrosoftKiotaSerializationForm::FormParseNode)
  end

  it 'raises without a content type' do
    expect { factory.get_parse_node('', sample_form_string) }
      .to raise_error(ArgumentError, 'content type cannot be undefined or empty')
  end

  it 'raises on an unsupported content type' do
    expect { factory.get_parse_node('application/xml', sample_form_string) }
      .to raise_error(ArgumentError, "expected a #{form_content_type} content type")
  end

  it 'raises on an empty form' do
    expect { factory.get_parse_node(form_content_type, '') }
      .to raise_error(ArgumentError, 'content cannot be undefined or empty')
  end

  it 'gets the valid content type' do
    expect(factory.get_valid_content_type).to eq(form_content_type)
  end

  it 'matches the content type case-insensitively' do
    expect(factory.get_parse_node(form_content_type.upcase, sample_form_string).get_child_node('city').get_string_value)
      .to eq('New York')
  end
end
