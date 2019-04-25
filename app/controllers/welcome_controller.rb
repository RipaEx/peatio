# encoding: UTF-8
# frozen_string_literal: true

class WelcomeController < ApplicationController
  layout 'landing'
  include Concerns::DisableCabinetUI

  def index
    if ENV['URL_HOST']
      redirectWelcome = ENV.fetch('URL_SCHEME') + '://' + ENV.fetch('URL_HOST') + '/auth/barong'
      Rails.logger.info('redirectWelcome: ' + redirectWelcome)
      redirect_to redirectWelcome
    end  
  end
end
