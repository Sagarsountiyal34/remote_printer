class SearchController < ApplicationController
	def show
		# debugger
		if params[:user_id].present?
			@user = User.find(params[:user_id])
		else
			users = User.where( :role.ne => "admin" ,:email => /#{params[:search]}/i  )
			render "search/_user_search_table",
             locals: { users: users },
             layout: false
		end	
	end

end
