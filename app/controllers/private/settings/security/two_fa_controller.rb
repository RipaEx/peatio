# frozen_string_literal: true

module Private
  module Settings
    module Security
      class TwoFaController < BaseRequestProcessController
        before_action :read_barong_account 
        @@barongAccount
        @@otp
        @@otp_secret
        @@step = 1
        helper_method :step1_class
        helper_method :step2_class

        def index
          @barongAccount = @@barongAccount
          @step = @@step
          generate_barong_2fa
          if defined?(@@otp)
            @otp = OpenStruct.new
            data = @@otp["data"]
            @otp.barcode = data["barcode"]
            @otp.url = data["url"]
          end
          if defined?(@@otp_secret)
            @otp_secret = @@otp_secret
          end
        end

        def disable_2fa
          @barongAccount = @@barongAccount
          @step = @@step          
        end

        def submit_2fa_form
          commitParameter = params[:commit]
          if commitParameter == "Back"
            previous_step(false)
          elsif commitParameter == "Submit"
            next_step(params, false)
          elsif commitParameter == "Security"
            @@step = 1
            redirect_to settings_security_path
          end
        end

        def submit_2fa_form_disable
          commitParameter = params[:commit]
          if commitParameter == "Back"
            previous_step(true)
          elsif commitParameter == "Submit"
            next_step(params, true)
          elsif commitParameter == "Security"
            @@step = 1
            redirect_to settings_security_path
          end
        end

        def step1_class
          #completed current
          if @@step == 1
            return "current"
          elsif @@step == 2
            return "completed"
          end
        end

        def step2_class
          #completed current
          if @@step == 1
            return ""
          elsif @@step == 2
            return "current"
          end
        end

        private

        def next_step(params, disable)
          result = OpenStruct.new
          result.success = false
          result.redirect = false
          if @@step == 1
            #Enable 2FA
            otp = params[:otp]
            if disable == false
              result = enable_2fa(otp)
            else
              result = disable_2fa_action(otp)
            end
            Rails.logger.debug("Enable/Disable 2FA Result: " + result.inspect)
          elsif @@step == 2
            #Confirm
          end
          if result.success
            @@step += 1
          else
            flash[:alert] = result.message
          end
          if disable == false
            redirect_to settings_security_two_fa_path
          else
            redirect_to settings_security_two_fa_disable_path
          end
        end

        def previous_step(disable)
          @@step -= 1
          if @@step < 1
            @@step = 1
            redirect_to settings_security_path
          else
            if disable == false
              redirect_to settings_security_two_fa_path
            else
              redirect_to settings_security_two_fa_disable_path
            end
          end
        end

        def read_barong_account
          if ENV["BARONG_DOMAIN"]
            if !current_user.nil?
              currentUserAuth = Authentication.find_by!(provider: "barong", member_id: current_user.id)
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
                  if response.status >= 200 && response.status <= 299 && valid_json?(response.body)
                    barongAccountJSON = JSON.parse(response.body)
                    @@barongAccount = Barong::Account.new
                    @@barongAccount.uid = barongAccountJSON["uid"]
                    @@barongAccount.email = barongAccountJSON["email"]
                    @@barongAccount.role = barongAccountJSON["role"]
                    @@barongAccount.level = barongAccountJSON["level"]
                    @@barongAccount.otp_enabled = barongAccountJSON["otp_enabled"]
                    @@barongAccount.state = barongAccountJSON["state"]
                  end
                end
              end
            end
          end
        end

        def generate_barong_2fa
          result = OpenStruct.new
          result.success = false
          if ENV["BARONG_DOMAIN"]
            if !current_user.nil?
              currentUserAuth = Authentication.find_by!(provider: "barong", member_id: current_user.id)
              if !currentUserAuth.token.nil?
                # set variables
                barongBaseURL = ENV.fetch("BARONG_DOMAIN")
                apiURL = "/api/v1/security/generate_qrcode"
                token = "Bearer " + currentUserAuth.token
                # init connection object
                connection = Faraday.new(:url => barongBaseURL) do |c|
                  c.use Faraday::Request::UrlEncoded
                  c.use Faraday::Adapter::NetHttp
                end
                # send request
                response = connection.post apiURL do |request|
                  request.headers["Authorization"] = token
                end
                if !response.nil?
                  if response.status >= 200 && response.status <= 299 && valid_json?(response.body)
                    result.success = true
                    result.otp_data = JSON.parse(response.body)
                    @@otp = result.otp_data["otp"]
                    @@otp_secret = result.otp_data["otp_secret"]
                  end
                end
              end
            end
          end
          return result
        end

        def enable_2fa(otp)
          result = OpenStruct.new
          result.success = false
          if ENV["BARONG_DOMAIN"]
            if !current_user.nil?
              currentUserAuth = Authentication.find_by!(provider: "barong", member_id: current_user.id)
              if !currentUserAuth.token.nil?
                # set variables
                barongBaseURL = ENV.fetch("BARONG_DOMAIN")
                apiURL = "/api/v1/security/enable_2fa"
                token = "Bearer " + currentUserAuth.token
                # init connection object
                connection = Faraday.new(:url => barongBaseURL) do |c|
                  c.use Faraday::Request::UrlEncoded
                  c.use Faraday::Adapter::NetHttp
                end
                # send request
                response = connection.post apiURL do |request|
                  request.headers["Authorization"] = token
                  request.params["code"] = otp
                end
                if !response.nil?
                  if response.status >= 200 && response.status <= 299 && valid_json?(response.body)
                    result.success = true
                  elsif response.status >= 300 && response.status <= 599 && valid_json?(response.body)
                    responseJSON = JSON.parse(response.body)
                    if responseJSON["error"]
                      result.message = responseJSON["error"]
                    else
                      result.message = response.reason_phrase
                    end
                  else
                    result.message = response.reason_phrase
                  end
                end
              end
            end
          end
          return result
        end

        def disable_2fa_action(otp)
          result = OpenStruct.new
          result.success = false
          if ENV["BARONG_DOMAIN"]
            if !current_user.nil?
              currentUserAuth = Authentication.find_by!(provider: "barong", member_id: current_user.id)
              if !currentUserAuth.token.nil?
                # set variables
                barongBaseURL = ENV.fetch("BARONG_DOMAIN")
                apiURL = "/api/v1/security/disable_2fa"
                token = "Bearer " + currentUserAuth.token
                # init connection object
                connection = Faraday.new(:url => barongBaseURL) do |c|
                  c.use Faraday::Request::UrlEncoded
                  c.use Faraday::Adapter::NetHttp
                end
                # send request
                response = connection.post apiURL do |request|
                  request.headers["Authorization"] = token
                  request.params["code"] = otp
                end
                if !response.nil?
                  if response.status >= 200 && response.status <= 299 && valid_json?(response.body)
                    result.success = true
                  elsif response.status >= 300 && response.status <= 599 && valid_json?(response.body)
                    responseJSON = JSON.parse(response.body)
                    if responseJSON["error"]
                      result.message = responseJSON["error"]
                    else
                      result.message = response.reason_phrase
                    end
                  else
                    result.message = response.reason_phrase
                  end
                end
              end
            end
          end
          return result
        end

        def valid_json?(json)
          if json.nil?
            return false
          end
          JSON.parse(json)
          return true
        rescue JSON::ParserError => e
          return false
        end
      end
    end
  end
end
