module Api
	module V1
		class UsersController < ApplicationController
			include ActionController::ImplicitRender
			protect_from_forgery with: :null_session

			def users_list
        begin
          users_emails_with_groupCount = []
          users_emails_with_groupCount =  User.all.map{|u| [u.email,u.groups.where(status: "ready_for_print").count,u.note.try(:note_text).present?]} if (User.count>0)

          render status: "200", json: {
            users_emails: users_emails_with_groupCount,
            message: "Success"
          }
        rescue Exception => e
          generate_error_response("500",e)

        end

      end


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

				def generate_error_response(code,message)
						render status: code, json: {
								message: message
						}
				end
    	end
  	end
end
