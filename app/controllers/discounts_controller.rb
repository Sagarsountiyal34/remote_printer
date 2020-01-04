
class DiscountsController < ApplicationController
	before_action :authenticate_user!
	protect_from_forgery prepend: true


	def new
		@discount = Discount.new
	end
	
	def create
 		discount = Discount.new(params.require(:discount).permit(:desc, :discount_value))
 		discount.status = true
		Discount.update_all(:status => false)
		if discount.save
			flash[:message] = "Discount Applied"
			redirect_to action: 'index'
		else
			flash[:errors] = "Please Try Again"
		end
	end

	def index
		@discounts = Discount.all
	end

	def apply_disapply_discount
		status =  to_boolean(params[:is_active]) ? false : true
		discount = Discount.find(params[:discount_id])
		Discount.update_all(:status => false)
		if discount.present? and discount.update_attribute('status', status)
				@discounts = Discount.all
				render partial: 'discount_list'
		else
			render json: { message: false }.to_json, status: 200
		end
	end
	
	private
	def to_boolean(str)
  		str == 'true'
	end
end