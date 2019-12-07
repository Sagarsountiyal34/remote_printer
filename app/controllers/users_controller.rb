class UsersController < ApplicationController
	before_action :authenticate_user!
	protect_from_forgery prepend: true

	def show
		@user = User.includes(:groups).find(params[:id])
		@groups = @user.groups.order_by(submitted_time: :desc).select{|g| g.status == 'ready_for_print'}
	end
end