class ApplicationApiController < ActionController::Base
      include DeviseTokenAuth::Concerns::SetUserByToken
	# protect_from_forgery with: :null_session
	# layout :is_devise
	# before_action :is_confirmed?
	before_action :authenticate_with_token!
	

	private

	def get_current_company
		validate_token = false
		company =  Company.find_by(email: params[:uid])
		token_valid = company.valid_token?(params["access-token"],params[:client]) if company.present?
		if token_valid
			return @current_company = company
		else
			return false
		end 
	end
	def company_signed_in?
	   get_current_company.present?
	end

	def authenticate_with_token!
		# debugger
	    unless company_signed_in?
	    	render status: :unauthorized, json: {
				 errors: "Not authenticated"
	        } 
	    end
	end

	protected
	def forbidden_error(e=nil)
		render status: "500", json: {
			message: "Internal Server Error." + e.to_s
        }
	end
	
end

