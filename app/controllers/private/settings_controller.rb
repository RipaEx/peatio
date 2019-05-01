# encoding: UTF-8
# frozen_string_literal: true

module Private
  class SettingsController < BaseController
    def index
      if ENV["BARONG_DOMAIN"]
        if !current_user.nil?
          currentUserAuth = Authentication.find_by!(provider: 'barong', member_id: current_user.id)
          if !currentUserAuth.token.nil?
            # set variables
            barongBaseURL = ENV.fetch("BARONG_DOMAIN")
            apiURL = "/api/v1/accounts/me"
            token = "Bearer " + currentUserAuth.token
            # init connection object
            connection = Faraday.new(:url => barongBaseURL) do |c|
              c.use Faraday::Request::UrlEncoded
              c.use Faraday::Adapter::NetHttp
            end
            # send request
            response = connection.get apiURL do |request|
              request.headers["Authorization"] = token
            end
            if !response.nil?
              barongAccountJSON = JSON.parse(response.body)
              Rails.logger.debug("Barong Account inspect: " + barongAccountJSON.inspect)
              session[:barongAccount] = barongAccountJSON
              @barongAccount = OpenStruct.new
              @barongAccount.uid = barongAccountJSON["uid"]
              @barongAccount.email = barongAccountJSON["email"]
              @barongAccount.role = barongAccountJSON["role"]
              @barongAccount.level = barongAccountJSON["level"]
              @barongAccount.otp_enabled = barongAccountJSON["otp_enabled"]
              @barongAccount.state = barongAccountJSON["state"]
            end
          end
        end
      end
    end
  end
end
