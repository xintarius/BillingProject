require 'httparty'
# app/services/courier_billing_service.rb
class CourierBillingService
  include HTTParty

  base_uri ENV.fetch("BASE_DELIVERY_URL")
  def initialize(api_key)
    @headers = {
      "Authorization" => "Bearer #{api_key}",
      "Content-Type" => "application/json"
    }
  end

  def courier_earnings(id)
    self.class.get("/earnings/courier/#{id}", headers: @headers)
  end
end
