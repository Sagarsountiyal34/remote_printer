class ApplicationController < ActionController::Base
	protect_from_forgery with: :null_session
	layout :is_devise
	before_action :is_confirmed?
	before_action :is_admin?, unless: -> {request.xhr? }

	def is_devise
		if devise_controller?
			"devise_layout"
		end
	end
	# def redirect_to(*args)
  #   flash.keep
  #   super
  # end

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
			if user_signed_in? && !current_user.otp_confirmed && !devise_controller?
				redirect_to confirm_otp_path
			end
		# if current_user.present? && !current_user.otp_confirmed &&  request.original_fullpath!="/confirm_otp"
		# 		redirect_to confirm_otp_path
		# end
	end

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
