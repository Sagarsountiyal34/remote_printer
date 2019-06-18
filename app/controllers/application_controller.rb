class ApplicationController < ActionController::Base
	layout :is_devise

	def is_devise
		if devise_controller?
			"devise_layout"
		end
	end
end
