# frozen_string_literal: true

module Private
  module Settings
    class EditProfileController < BaseRequestProcessController
      before_action :read_barong_account
      @@barongAccount
      @@barongAccountProfile
      @@barongAccountDocuments
      @@first_call = true
      @@step = 1
      @@authorizationCode = ""
      helper_method :step1_class
      helper_method :step2_class
      helper_method :step3_class
      helper_method :step4_class
      helper_method :step5_class

      def index
        @barongAccount = @@barongAccount
        @@barongAccountProfile = OpenStruct.new
        @@barongAccountProfile.success = false
        if @@first_call
          @step = @@step = @barongAccount.level.to_i + 1
          @@first_call = false
          if @barongAccount.level == 2
            @@barongAccountProfile = read_barong_profile
            if @@barongAccountProfile.success == true
              @step = @@step = 4
              @@barongAccountDocuments = read_barong_documents
              if @@barongAccountDocuments.success == true
                @step = @@step = 5
              end
            end
          end
        else
          @step = @@step
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

      def submit_edit_profile_form
        commitParameter = params[:commit]
        if commitParameter == "Back"
          previous_step
        elsif commitParameter == "Submit"
          next_step(params)
        elsif commitParameter == "Trade"
          redirect_to trading_path(market_id: 'btcusd')
        elsif commitParameter == "Settings"
          redirect_to settings_path
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
        elsif @@step == 5
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
        elsif @@step == 5
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
        elsif @@step == 5
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
        elsif @@step == 5
          return "completed"
        end
      end

      def step5_class
        #completed current
        if @@step == 1
          return ""
        elsif @@step == 2
          return ""
        elsif @@step == 3
          return ""
        elsif @@step == 4
          return ""
        elsif @@step == 5
          return "current"
        end
      end

      private

      def next_step(params)
        result = OpenStruct.new
        result.success = false
        result.redirect = false
        if @@step == 1
          #Confirm e-mail
        elsif @@step == 2
          #Confirm phone
          countryCode = params["country_code"]
          phoneNumber = params["number"]
          if !countryCode.nil? && !phoneNumber.nil?
            phoneNumber = countryCode + phoneNumber
          end
          code = params["code"]
          result = verify_phone(phoneNumber, code)
          Rails.logger.debug("Verify Phone Result: " + result.inspect)
        elsif @@step == 3
          #Insert profile data
          profile = params["profile"]
          barongProfile = Barong::Profile.new(profile[:first_name], profile[:last_name], profile[:dob], profile[:address], profile[:city], profile[:country], profile[:postcode])
          result = create_profile(barongProfile)
          Rails.logger.debug("Create Profile Result: " + result.inspect)
        elsif @@step == 4
          #Upload document
          document = params["document"]
          if !document[:upload].nil?
            barongDocument = Barong::Document.new(document[:doc_type], document[:doc_number], document[:doc_expire], document[:upload])
            result = upload_document(barongDocument)
            Rails.logger.debug("Upload Document Result: " + result.inspect)
          else
            result.message = 'A File must be uploaded'
          end
        elsif @@step == 5
          @@first_call = true
          result.redirect = true
        end
        if result.success
          @@step += 1
          if @@step > 5
            @@first_call = true
            result.redirect = true
          end
        else
          flash[:alert] = result.message
        end
        next_step_redirect(result)
      end

      def next_step_redirect(redirect)
        if redirect.redirect
          redirect_to settings_path
        else
          redirect_to settings_edit_profile_path
        end
      end

      def previous_step
        @@step -= 1
        Rails.logger.debug("Step: " + @@step.to_s)
        if @@step < (@@barongAccount.level + 1) || (@@barongAccountProfile.success == true)
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

      def read_barong_profile
        result = OpenStruct.new
        result.success = false
        result.profile = Barong::Profile.new
        if ENV["BARONG_DOMAIN"]
          if !current_user.nil?
            currentUserAuth = Authentication.find_by!(provider: "barong", member_id: current_user.id)
            if !currentUserAuth.token.nil?
              # set variables
              barongBaseURL = ENV.fetch("BARONG_DOMAIN")
              apiURL = "/api/v1/profiles/me"
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
                  result.success = true
                end
              end
            end
          end
        end
        return result
      end

      def read_barong_documents
        result = OpenStruct.new
        result.success = false
        result.document = Barong::Document.new
        if ENV["BARONG_DOMAIN"]
          if !current_user.nil?
            currentUserAuth = Authentication.find_by!(provider: "barong", member_id: current_user.id)
            if !currentUserAuth.token.nil?
              # set variables
              barongBaseURL = ENV.fetch("BARONG_DOMAIN")
              apiURL = "/api/v1/documents"
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
                  barongDocumentsJSON = JSON.parse(response.body)
                  result.success = true
                end
              end
            end
          end
        end
        return result
      end

      def create_profile(_profile)
        result = OpenStruct.new
        result.success = false
        if ENV["BARONG_DOMAIN"]
          if !current_user.nil?
            currentUserAuth = Authentication.find_by!(provider: "barong", member_id: current_user.id)
            if !currentUserAuth.token.nil?
              # set variables
              barongBaseURL = ENV.fetch("BARONG_DOMAIN")
              apiURL = "/api/v1/profiles"
              token = "Bearer " + currentUserAuth.token
              # init connection object
              connection = Faraday.new(:url => barongBaseURL) do |c|
                c.use Faraday::Request::UrlEncoded
                c.use Faraday::Adapter::NetHttp
              end
              # send request
              response = connection.post apiURL do |request|
                request.headers["Authorization"] = token
                request.params["first_name"] = _profile.first_name
                request.params["last_name"] = _profile.last_name
                request.params["dob"] = _profile.dob
                request.params["address"] = _profile.address
                request.params["postcode"] = _profile.postcode
                request.params["city"] = _profile.city
                request.params["country"] = _profile.country
              end
              if !response.nil?
                if response.status >= 200 && response.status <= 299 && valid_json?(response.body)
                  result.success = true
                  result.message = response.reason_phrase
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

      def upload_document(_document)
        result = OpenStruct.new
        result.success = false
        if ENV["BARONG_DOMAIN"]
          if !current_user.nil?
            currentUserAuth = Authentication.find_by!(provider: "barong", member_id: current_user.id)
            if !currentUserAuth.token.nil?
              # set variables
              barongBaseURL = ENV.fetch("BARONG_DOMAIN")
              apiURL = "/api/v1/documents"
              token = "Bearer " + currentUserAuth.token
              # init connection object
              connection = Faraday.new(:url => barongBaseURL) do |c|
                c.use Faraday::Request::Multipart
                c.use Faraday::Request::UrlEncoded
                c.use Faraday::Adapter::NetHttp
              end
              request_data = {
                :doc_type => _document.doc_type,
                :doc_number => _document.doc_number,
                :doc_expire => _document.doc_expire,
                :upload => Faraday::UploadIO.new(_document.upload.path, _document.upload.content_type, _document.upload.original_filename)
              }
              # send request
              response = connection.post apiURL do |request|
                request.headers["Authorization"] = token
                request.body = request_data
              end
              if !response.nil?
                if response.status >= 200 && response.status <= 299 && valid_json?(response.body)
                  result.success = true
                  result.message = response.reason_phrase
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
