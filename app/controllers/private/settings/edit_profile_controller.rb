# frozen_string_literal: true
module Private
  module Settings
    class EditProfileController < BaseRequestProcessController

      def index
        barongAccountJSON = session[:barongAccount]
        Rails.logger.debug("Barong Account inspect: " + barongAccountJSON.inspect)
        @barongAccount = OpenStruct.new
        @barongAccount.uid = barongAccountJSON["uid"]
        @barongAccount.email = barongAccountJSON["email"]
        @barongAccount.role = barongAccountJSON["role"]
        @barongAccount.level = barongAccountJSON["level"]
        @barongAccount.otp_enabled = barongAccountJSON["otp_enabled"]
        @barongAccount.state = barongAccountJSON["state"]
=begin  
        redirect_to new_phone_path if @barongAccount.level == 1
        redirect_to new_profile_path if @barongAccount.level == 2 #&& @barongAccount.documents.blank?
        redirect_to new_profile_path if @barongAccount.level == 2
=end
      end
    end
  end
end