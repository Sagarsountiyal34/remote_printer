class ApplicationController < ActionController::Base
	protect_from_forgery with: :null_session
	layout :is_devise
	before_action :is_confirmed?
	before_action :configure_permitted_parameters, if: :devise_controller?
	def is_devise
		if devise_controller?
			"devise_layout"
		end
	end

	def set_csrf_header
	  response.headers['X-CSRF-Token'] = form_authenticity_token
	end

	def redirect_back_or_default(default = root_path, *options)
	    tag_options = {}
	    options.first.each { |k,v| tag_options[k] = v } unless options.empty?
	    redirect_to (request.referer.present? ? :back : default), tag_options
  	end

	private

	def is_confirmed?
		if  params[:controller]!="devise_token_auth/token_validations"
			if user_signed_in? && !current_user.otp_confirmed && !devise_controller? && !current_user.is_admin? && current_user.email.present?
				redirect_to confirm_otp_path
			end
		end
	end


	def after_sign_in_path_for(resource)
		if resource.is_admin?
			admin_path
		else
	  		progress_groups_path || root_path
		end
	end

	protected
	def configure_permitted_parameters
	    added_attrs = [:phone_number, :email, :password, :password_confirmation, :remember_me]
	    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
	    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
	    # devise_parameter_sanitizer.permit keys: added_attrs
	end
	def forbidden_error(e=nil)
		render status: "500", json: {
			message: "Internal Server Error. Please try after some time." + e.to_s
        }
	end

	def show_message(message=nil)
		render status: "500", json: {
			message: message
        }
	end
end

