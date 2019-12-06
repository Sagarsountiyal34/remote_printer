class HomeController < ApplicationController
	# layout 'home_layout'
	protect_from_forgery prepend: true
	skip_before_action :verify_authenticity_token, :only => [:contact,:save_confirmable_otp]
	skip_before_action :is_confirmed?, :except => [:home]


	def home
	end

	def about_us
	end

	def confirm_otp
		 #render :layout => false
	end

	def save_confirmable_otp
		if  params[:confirmable_otp] === current_user.confirmable_otp
			current_user.otp_confirmed = true
			if current_user.save
				redirect_to root_path
			else
				flash[:notice]= current_user.errors.full_messages
				redirect_back(fallback_location: root_path)

			end
		else
			flash[:notice] = "OTP does not match. Please type again"
			redirect_to action: 'confirm_otp'
			# redirect_back(fallback_location: root_path)

		end
	end

	def contact
		if request.method == 'POST'
			email = current_user.present? ? current_user.email : params[:email]
			begin
				if ExampleMailer.contact_us_email(email, params[:message], params[:subject], params[:name]).deliver_now
					flash[:message] = "Email SuccessFully sent."
				else
					flash[:error] = "Please Try again."
				end
			rescue Exception => e
				flash[:error] = "Please Try again."
			end
		end
	end
end
