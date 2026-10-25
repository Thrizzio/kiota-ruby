# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe MicrosoftKiotaAuthenticationOAuth::OAuthAccessTokenProvider do
  let(:context) do
    MicrosoftKiotaAuthenticationOAuth::ClientCredentialContext.new('tenant_id', 'client_id', 'client_secret', {})
  end
  let(:allowed_hosts) { ['api.example.com'] }
  let(:provider) { described_class.new(context, allowed_hosts, ['https://api.example.com/.default']) }
  let(:token) { instance_double(OAuth2::AccessToken, token: 'test_token', to_hash: {}) }

  before do
    allow(context).to receive(:get_token).and_return(token)
    allow(context).to receive(:initialize_scopes)
  end

  it 'returns a fiber yielding nil for a host outside the allowed hosts' do
    result = provider.get_authorization_token('https://other.example.com')

    expect(result).to be_a(Fiber)
    expect(result.resume).to be_nil
    expect(context).not_to have_received(:initialize_scopes)
    expect(context).not_to have_received(:get_token)
  end

  it 'returns a fiber yielding nil for a missing URI' do
    result = provider.get_authorization_token(nil)

    expect(result).to be_a(Fiber)
    expect(result.resume).to be_nil
    expect(context).not_to have_received(:get_token)
  end

  it 'returns a token for an allowed host' do
    expect(provider.get_authorization_token('https://api.example.com').resume).to eq('test_token')
    expect(context).to have_received(:get_token).once
  end

  context 'with no allowed hosts configured' do
    let(:allowed_hosts) { [] }

    it 'returns a token for any HTTPS host' do
      expect(provider.get_authorization_token('https://other.example.com').resume).to eq('test_token')
    end
  end

  it 'leaves a request to a host outside the allowed hosts without an authorization header' do
    authentication_provider = MicrosoftKiotaAuthenticationOAuth::OAuthAuthenticationProvider.new(
      context, allowed_hosts, ['https://api.example.com/.default']
    )
    request = MicrosoftKiotaAbstractions::RequestInformation.new
    request.uri = 'https://other.example.com'

    authentication_provider.authenticate_request(request).resume

    expect(request.headers.get_all).not_to have_key('Authorization')
    expect(context).not_to have_received(:get_token)
  end

  context 'when deriving default scopes per request' do
    let(:multi_host_provider) do
      described_class.new(context, ['one.example.com', 'two.example.com'])
    end

    it 'derives distinct default scopes for consecutive requests to different allowed hosts' do
      initialized_scopes = []
      allow(context).to receive(:initialize_scopes) { |scopes| initialized_scopes << scopes }

      multi_host_provider.get_authorization_token('https://one.example.com').resume
      multi_host_provider.get_authorization_token('https://two.example.com').resume

      expect(initialized_scopes).to eq([
                                         ['https://one.example.com/.default'],
                                         ['https://two.example.com/.default']
                                       ])
      expect(multi_host_provider.scopes).to be_empty
    end

    it 'does not mutate the caller-supplied scopes array' do
      caller_scopes = []
      scoped_provider = described_class.new(context, ['one.example.com'], caller_scopes)

      scoped_provider.get_authorization_token('https://one.example.com').resume

      expect(caller_scopes).to be_empty
      expect(scoped_provider.scopes).to be_empty
    end

    it 'preserves explicitly configured scopes across requests' do
      explicit_scopes = ['User.Read', 'Mail.Read']
      configured_provider = described_class.new(context, ['one.example.com', 'two.example.com'], explicit_scopes)
      initialized_scopes = []
      allow(context).to receive(:initialize_scopes) { |scopes| initialized_scopes << scopes }

      configured_provider.get_authorization_token('https://one.example.com').resume
      configured_provider.get_authorization_token('https://two.example.com').resume

      expect(initialized_scopes).to eq([explicit_scopes, explicit_scopes])
      expect(configured_provider.scopes).to eq(explicit_scopes)
    end

    it 'does not reuse cached tokens across requests with different effective scopes' do
      client = context.oauth_provider
      token1 = OAuth2::AccessToken.new(client, 'token_one')
      token2 = OAuth2::AccessToken.new(client, 'token_two')
      tokens = [token1, token2]
      allow(context).to receive(:get_token) { tokens.shift }

      first_token = multi_host_provider.get_authorization_token('https://one.example.com').resume
      second_token = multi_host_provider.get_authorization_token('https://two.example.com').resume

      expect(first_token).to eq('token_one')
      expect(second_token).to eq('token_two')
      expect(context).to have_received(:get_token).twice
    end

    it 'reuses a cached token for consecutive requests to the same host with matching effective scopes' do
      client = context.oauth_provider
      cached_access_token = OAuth2::AccessToken.new(client, 'cached_valid_token')
      allow(context).to receive(:get_token).and_return(cached_access_token)

      first_token = multi_host_provider.get_authorization_token('https://one.example.com').resume
      second_token = multi_host_provider.get_authorization_token('https://one.example.com').resume

      expect(first_token).to eq('cached_valid_token')
      expect(second_token).to eq('cached_valid_token')
      expect(context).to have_received(:get_token).once
    end
  end
end
