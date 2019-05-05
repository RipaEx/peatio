# frozen_string_literal: true

module Private
  module Settings
    module Security
      class ChangePasswordController < BaseRequestProcessController
        before_action :read_barong_account
        @@barongAccount
        @@first_call = true
        @@step = 1
        @@authorizationCode = ""
        helper_method :step1_class
        helper_method :step2_class

        def index
          @barongAccount = @@barongAccount
          @step = @@step
        end

        def submit_change_password_form
          commitParameter = params[:commit]
          if commitParameter == "Back"
            previous_step
          elsif commitParameter == "Submit"
            next_step(params)
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

        def next_step(params)
          result = OpenStruct.new
          result.success = false
          result.redirect = false
          if @@step == 1
            #Change Password
            profile = params["profile"]
            newPassword = profile[:password]
            confirmPassword = profile[:password_confirmation]
            if newPassword != confirmPassword
              result.message = "New Password and Password Confirmations do not match"
            else
              result = change_password(profile)
              Rails.logger.debug("Change Password Result: " + result.inspect)
            end
          elsif @@step == 2
            #Confirm
          end
          if result.success
            @@step += 1
          else
            flash[:alert] = result.message
          end
          redirect_to settings_security_change_password_path
        end

        def previous_step
          @@step -= 1
          if @@step < 1
            @@step = 1
            redirect_to settings_security_path
          else
            redirect_to settings_security_change_password_path
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

        def change_password(_profile)
          result = OpenStruct.new
          result.success = false
          if ENV["BARONG_DOMAIN"]
            if !current_user.nil?
              currentUserAuth = Authentication.find_by!(provider: "barong", member_id: current_user.id)
              if !currentUserAuth.token.nil?
                # set variables
                barongBaseURL = ENV.fetch("BARONG_DOMAIN")
                apiURL = "/api/v1/accounts/password"
                token = "Bearer " + currentUserAuth.token
                # init connection object
                connection = Faraday.new(:url => barongBaseURL) do |c|
                  c.use Faraday::Request::UrlEncoded
                  c.use Faraday::Adapter::NetHttp
                end
                # send request
                response = connection.put apiURL do |request|
                  request.headers["Authorization"] = token
                  request.params["old_password"] = _profile[:current_password]
                  request.params["new_password"] = _profile[:password]
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
