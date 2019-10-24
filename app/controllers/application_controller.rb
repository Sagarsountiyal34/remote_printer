class ApplicationController < ActionController::Base
	layout :is_devise
	before_action :is_admin?, unless: -> {request.xhr? }

	def is_devise
		if devise_controller?
			"devise_layout"
		elsif current_user.present?
			"user_layout"
		end
	end

	private

	def is_admin?
		if current_user.present? && current_user.role == 'admin'  && !["admins",'devise/registrations',"devise/sessions"].include?(params[:controller])
			redirect_to admin_path
		end
	end

	def after_sign_in_path_for(resource)
	  progress_groups_path || root_path
	end

	protected
	
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
