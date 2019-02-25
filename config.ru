# frozen_string_literal: true

require 'rubygems'
require 'bundler'
require 'sinatra'
require 'omniauth-idplus'
require 'dotenv/load'
require 'json'

# main class for Sinatra app
class IdplusApp < Sinatra::Base
  get '/' do
    <<-HTML
      <p><a href="/auth/idplus">Sign into Id +</a></p>
      <p><a href="#{ENV['IDPLUS_ENV']}/ext/ae-logout?return_to=#{ENV['REQUEST_DOMAIN']}/signout&platsite=HIV/hive">Sign Out</a></p>
    HTML
  end

  post '/signout' do
    <<-HTML
      <p>Successfully signed out from ID +</p>
    HTML
  end

  get '/auth/:provider/callback' do |provider|
    content_type :json
    begin
      %( #{provider} token: #{request.env['omniauth.auth'].to_json}
          )
    rescue StandardError
      'No data returned'
    end
  end

  get '/auth/failure' do
    content_type 'text/plain'
    begin
      %( Error: #{request.env['omniauth.auth'].to_hash.inspect}
          )
    rescue StandardError
      'No data returned'
    end
  end
end

use Rack::Session::Cookie, secret: 'abc'

use OmniAuth::Builder do
  provider :idplus, ENV['CLIENT_ID'], ENV['CLIENT_SECRET'],
           client_options: { site: ENV['IDPLUS_ENV'],
                             authorize_url:  [ ENV['IDPLUS_ENV'], 'as/authorization.oauth2' ].join('/'),
                             token_url: [ ENV['IDPLUS_ENV'], 'as/token.oauth2' ].join('/') },
           platSite: 'HIV/hive',
           scope: 'openid email profile els_auth_info urn:com:elsevier:idp:policy:product:indv_identity',
           prompt: 'login',
           redirect_uri: [ ENV['REQUEST_DOMAIN'], 'auth/idplus/callback' ].join('/')
end

run IdplusApp.new

# shotgun --server=thin --port=9292 config.ru
