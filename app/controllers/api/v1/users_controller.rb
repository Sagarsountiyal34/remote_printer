module Api
	module V1
		class UsersController < ApplicationController
			include ActionController::ImplicitRender
			protect_from_forgery with: :null_session

      		def list
		        begin
		          	users = get_users
		            # groups = Group.where(status: "ready_for_print").map{|g| g.attributes.merge(user_email: g.user.email)}		          
					render status: "200", json: {
						users: users,
						message: "Success"
					}
				rescue Exception => e
					forbidden_error(e)
				end
      		end

      		private
	    	def get_users
	    		return  User.all.to_a
	    	end
    	end
  	end
end
