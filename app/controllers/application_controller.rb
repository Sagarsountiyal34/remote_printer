class ApplicationController < ActionController::Base
	layout :is_devise

	def is_devise
		if devise_controller?
			"devise_layout"
		end
	end

	protected
	def forbidden_error(e=nil)
		render status: "500", json: {
			message: "Internal Server Error. Please try after some time." + e.to_s
        }
	end

	protected
	def show_message(message=nil)
		render status: "500", json: {
			message: message
        }
	end
end
