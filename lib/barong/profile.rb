# frozen_string_literal: true

# Profile model
module Barong
  class Profile

    attr_accessor :first_name, :last_name, :dob, :address, :city, :country, :postcode, :errors

    def initialize(first_name = '', last_name = '', dob = '', address = '', city = '', country = '', postcode = '', errors = [])
      @first_name = first_name
      @last_name = last_name
      @dob = dob
      @address = address
      @city = city
      @country = country
      @postcode = postcode
      @errors = errors
    end

    def full_name
      "#{first_name} #{last_name}"
    end

    def as_json_for_event_api
      {
        account_uid: account.uid,
        first_name: first_name,
        last_name: last_name,
        dob: format_iso8601_time(dob),
        address: address,
        postcode: postcode,
        city: city,
        country: country,
        metadata: metadata,
        created_at: format_iso8601_time(created_at),
        updated_at: format_iso8601_time(updated_at),
      }
    end

    private

    def validate_country_format
      return if ISO3166::Country.find_country_by_alpha2(country) ||
                ISO3166::Country.find_country_by_alpha3(country)

      errors.add(:country, "must have alpha2 or alpha3 format")
    end

    def squish_spaces
      first_name&.squish!
      last_name&.squish!
      city&.squish!
      postcode&.squish!
    end
  end
end

# == Schema Information
# Schema version: 20180430172330
#
# Table name: profiles
#
#  id         :integer          not null, primary key
#  account_id :integer
#  first_name :string(255)
#  last_name  :string(255)
#  dob        :date
#  address    :string(255)
#  postcode   :string(255)
#  city       :string(255)
#  country    :string(255)
#  metadata   :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_profiles_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
