class HomeController < ApplicationController
	# layout 'home_layout'
	protect_from_forgery prepend: true
	skip_before_action :verify_authenticity_token, :only => :contact

	def home
	end

	def about_us
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
