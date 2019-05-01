# frozen_string_literal: true

module Private
  module Settings
    class EditProfileController < BaseRequestProcessController
      before_action :read_barong_account
      @@barongAccount
      @@first_call = true
      @@step = 1
      @@authorizationCode = ""
      helper_method :step1_class
      helper_method :step2_class
      helper_method :step3_class
      helper_method :step4_class

      def index
        @barongAccount = @@barongAccount
        if @@first_call
          @step = @@step = @barongAccount.level.to_i + 1
          @@first_call = false
        else
          @step = @@step
        end
        if @barongAccount.level == 2
          @profile = Barong::Profile.new
          Rails.logger.debug('Profile: ' + @profile.inspect)
        end
=begin  
        redirect_to new_phone_path if @barongAccount.level == 1
        redirect_to new_profile_path if @barongAccount.level == 2 #&& @barongAccount.documents.blank?
        redirect_to new_profile_path if @barongAccount.level == 2
=end
      end

      def send_code
        if ENV["BARONG_DOMAIN"]
          if !current_user.nil?
            currentUserAuth = Authentication.find_by!(provider: "barong", member_id: current_user.id)
            if !currentUserAuth.token.nil?
              # set variables
              barongBaseURL = ENV.fetch("BARONG_DOMAIN")
              apiURL = "/api/v1/phones"
              token = "Bearer " + currentUserAuth.token
              # init connection object
              connection = Faraday.new(:url => barongBaseURL) do |c|
                c.use Faraday::Request::UrlEncoded
                c.use Faraday::Adapter::NetHttp
              end
              # send request
              response = connection.post apiURL do |request|
                phoneNumber = params["number"]
                request.headers["Authorization"] = token
                request.params["phone_number"] = phoneNumber
              end
              if !response.nil?
                responseJSON = JSON.parse(response.body)
                #Rails.logger.debug("responseJSON inspect: " + responseJSON.inspect)
                if responseJSON["error"]
                  render json: { success: "false", message: responseJSON["error"] }
                else
                  render json: { success: "true", message: responseJSON["message"] }
                end
              else
                render json: { success: "false", message: "There was a problem in the response" }
              end
            end
          end
        end
      end

      def verify_phone(_phoneNumber, _code)
        result = OpenStruct.new
        result.success = false
        if ENV["BARONG_DOMAIN"]
          if !current_user.nil?
            currentUserAuth = Authentication.find_by!(provider: "barong", member_id: current_user.id)
            if !currentUserAuth.token.nil?
              # set variables
              barongBaseURL = ENV.fetch("BARONG_DOMAIN")
              apiURL = "/api/v1/phones/verify"
              token = "Bearer " + currentUserAuth.token
              # init connection object
              connection = Faraday.new(:url => barongBaseURL) do |c|
                c.use Faraday::Request::UrlEncoded
                c.use Faraday::Adapter::NetHttp
              end
              # send request
              response = connection.post apiURL do |request|
                request.headers["Authorization"] = token
                request.params["phone_number"] = _phoneNumber
                request.params["verification_code"] = _code
              end
              if !response.nil?
                Rails.logger.debug("Response Inspect: " + response.inspect)
                if response.status >= 200 && response.status <= 299 && valid_json?(response.body)
                  Rails.logger.debug("Response Body Inspect: " + response.body.inspect)
                  responseJSON = JSON.parse(response.body)
                  if responseJSON["error"]
                    result.message = responseJSON["error"]
                  else
                    result.success = true
                    result.message = responseJSON["message"]
                  end
                elsif response.status >= 300 && response.status <= 599 && valid_json?(response.body)
                  Rails.logger.debug("Response Body Inspect: " + response.body.inspect)
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

      def submit_edit_profile_form
        commitParameter = params[:commit]
        Rails.logger.debug("Commit Parameter: " + commitParameter)
        countryCode = params["country_code"]
        phoneNumber = params["number"]
        if !countryCode.nil? && !phoneNumber.nil?
          phoneNumber = countryCode + phoneNumber
        end
        code = params["code"]
        if commitParameter == "Back"
          # A was pressed
          previous_step
        elsif commitParameter == "Submit"
          # B was pressed
          next_step(phoneNumber, code)
        end
      end

      def step1_class
        #completed current
        if @@step == 1
          return "current"
        elsif @@step == 2
          return "completed"
        elsif @@step == 3
          return "completed"
        elsif @@step == 4
          return "completed"
        end
      end

      def step2_class
        #completed current
        if @@step == 1
          return ""
        elsif @@step == 2
          return "current"
        elsif @@step == 3
          return "completed"
        elsif @@step == 4
          return "completed"
        end
      end

      def step3_class
        #completed current
        if @@step == 1
          return ""
        elsif @@step == 2
          return ""
        elsif @@step == 3
          return "current"
        elsif @@step == 4
          return "completed"
        end
      end

      def step4_class
        #completed current
        if @@step == 1
          return ""
        elsif @@step == 2
          return ""
        elsif @@step == 3
          return ""
        elsif @@step == 4
          return "current"
        end
      end

      private

      def next_step(_phoneNumber, _code)
        result = OpenStruct.new
        result.success = false
        if @@step == 1
          #Confirm e-mail
        elsif @@step == 2
          #Confirm phone
          result = verify_phone(_phoneNumber, _code)
          Rails.logger.debug("Verify Phone Result: " + result.inspect)
        elsif @@step == 3
          #Insert profile data
        elsif @@step == 4
          #Upload document
        end
        if result.success
          @@step += 1
          Rails.logger.debug("Step: " + @@step.to_s)
          if @@step > 4
            @@first_call = true
            redirect_to settings_path
          end
        else
          flash[:alert] = result.message
        end
        redirect_to settings_edit_profile_path
      end

      def previous_step
        @@step -= 1
        Rails.logger.debug("Step: " + @@step.to_s)
        if @@step < (@@barongAccount.level + 1)
          @@first_call = true
          redirect_to settings_path
        else
          redirect_to settings_edit_profile_path
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
                barongAccountJSON = JSON.parse(response.body)
                #Rails.logger.debug("Barong Account inspect: " + barongAccountJSON.inspect)
                session[:barongAccount] = barongAccountJSON
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
