module Api
  module V1
    # couriers_billing_controller
    class CourierBillingsController < ApplicationController
      def earnings
        courier = CourierBillingService.new(ENV.fetch('BILLING_API_KEY', nil))
        response = courier.courier_earnings(params[:id])
        if response.code == 200
          render json: JSON.parse(response.body)
        else
          render json: {error: 'Api error'}, status: response.code
        end
      end
    end
  end
end
