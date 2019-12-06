class AdminsController < ApplicationController
	# layout "admin_layout"

	# before_action :authenticate_user!,:admin?
	# protect_from_forgery prepend: true

	def dashboard
		@users = User.not.where(role: 'admin').order_by(created_at: :desc)
	end

end
