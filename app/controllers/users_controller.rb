class UsersController < ApplicationController
	before_action :authenticate_user!
	protect_from_forgery prepend: true

	def show
		@user = User.includes(:groups).find(params[:id])
	end


end
