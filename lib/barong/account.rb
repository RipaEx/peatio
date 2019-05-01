# frozen_string_literal: true

# Profile model
module Barong
  class Account

    attr_accessor :uid, :email, :role, :level, :otp_enabled, :state

    def initialize(uid = '', email = '', role = '', level = 1, otp_enabled = false, state = '')
      @uid = uid
      @email = email
      @role = role
      @level = level
      @otp_enabled = otp_enabled
      @state = state
    end
  end
end
