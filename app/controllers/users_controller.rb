class UsersController < ApplicationController
	before_action :authenticate_user!, except: [:create_account_with_group, :send_otp_to_phone_number]
	protect_from_forgery prepend: true

	def show
		@user = User.includes(:groups).find(params[:id])
		@groups = @user.groups.order_by(submitted_time: :desc).select{|g| g.status == 'ready_for_print'}
	end

	def send_otp_to_phone_number
		password = rand(1000000000..9999999999).to_s #also send this password to phone user
		phone_otp = rand(1000000000..9999999999).to_s
		user = User.find_by(:phone_number => params[:phone_number])
		if user.present?
			render json: {status: false, message: "User already exist with this number"}, status:  500
		elsif 
			user = User.new(:phone_number => params[:phone_number], :password => password, :phone_otp => phone_otp)
			if user.save
				render json: {status: true, user_id: user.id.to_s, phone_otp: phone_otp}, status: 200
			else
				render json: {status: false, message: "Please Try again"}, status:  500
			end
		end
	end
end