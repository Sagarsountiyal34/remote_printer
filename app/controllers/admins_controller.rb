class AdminsController < ApplicationController
	layout "admin_layout"

	before_action :authenticate_user!,:admin?
	# protect_from_forgery prepend: true

	def dashbord
		@users_count = User.not.where(role: 'admin').size
		@documents_count = Group.all.map{|a| a.documents.size}.sum
	end

	def users
		@users = User.not.where(role: 'admin')
	end

	private
	def admin?
		if !(current_user.role == 'admin')
			redirect_to root_path
		end
	end
end
