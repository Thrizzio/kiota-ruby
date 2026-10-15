# frozen_string_literal: true

require 'microsoft_kiota_abstractions'

module Files
  class User
    include MicrosoftKiotaAbstractions::Parsable

    def self.create_from_discriminator_value(_parse_node) = User.new
  end
end
