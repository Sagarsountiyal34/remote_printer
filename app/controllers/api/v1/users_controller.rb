module Api
	module V1
		class UsersController < ApplicationController
			include ActionController::ImplicitRender
			protect_from_forgery with: :null_session

			def users_list
		        begin
		          users_emails_with_groupCount = []
		          users_emails_with_groupCount =  User.all.map{|u| [u.email,u.groups.where(status: "ready_for_print").count,u.note.try(:pending_payments).present?,u.confirmable_otp]} if (User.count>0)

		          render status: "200", json: {
		            users_emails: users_emails_with_groupCount,
		            message: "Success"
		          }
		        rescue Exception => e
		          generate_error_response("500",e)

		        end

      		end

			def pending_payments
		        begin
							pending_payments =  false
							user = User.find_by(email: params[:email])
							pending_payments = true if user.note.try(:pending_payments).present?
		          render status: "200", json: {
		            pending_payments: pending_payments,
		            message: "Success"
		          }
		        rescue Exception => fcbg
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

			def check_user_confirmed
				begin
  			 		user = User.find_by(email: params[:user_email])
 				 	is_confirmed = user.otp_confirmed
 				 	otp = user.confirmable_otp if !is_confirmed

					render status: "200", json: {
						 is_confirmed: is_confirmed,
						 otp: otp||"",
						 message: "Success"
					}
				rescue Exception => e
						 forbidden_error(e)
				end
		 	end

		 	def check_company_credential
		 		if params[:company_name] and params[:password].present?
		 			if Company.where(:company_name => params[:company_name], :password => params[:password]).present?
		 				render status: "200", json: {
						status: true,
						message: "Company authorized"
					}
		 			else
		 				render status: "200", json: {
						status: false,
						message: "Company not authorized"
						}
		 			end
		 		else
		 			render status: "200", json: {
						status: false,
						message: "please send company_name and password."
					}
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
