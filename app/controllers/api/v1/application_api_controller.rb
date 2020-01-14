class ApplicationApiController < ActionController::Base
      include DeviseTokenAuth::Concerns::SetUserByToken
	# protect_from_forgery with: :null_session
	# layout :is_devise
	# before_action :is_confirmed?
	before_action :authenticate_with_token!
	

	private

	def get_current_company
		@current_company = Company.find_by(email: params[:uid]).valid_token?(params["access-token"],params[:client])
	end
	def company_signed_in?
	   get_current_company.present?
	end

	def authenticate_with_token!
	    unless company_signed_in?
	    	render status: :unauthorized, json: {
				 errors: "Not authenticated"
	        } 
	    end
	end

	
end

