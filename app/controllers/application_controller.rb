class ApplicationController < ActionController::Base
	before_action :authenticate_user!
	layout :is_devise

	def is_devise
		if devise_controller?
			"devise_layout"
		end
	end
end
