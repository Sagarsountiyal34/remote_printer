module Api
	module V1
		class NotesController < ApplicationController
			include ActionController::ImplicitRender
			protect_from_forgery with: :null_session

		    def save_note
		        begin
		          	user_id = params["user_id"]
		          	note_text = params["note_text"]
		          	message = ""
		          	status = false
		          	if user_id.present? and note_text.present?
		          		user = User.find(user_id)
		          		if user.present? 
		          			if !user.note.present?
			          			note = user.create_note(:note_text => note_text)
		          				message = "Note creates Successfully."
		          				status = true
	          				else
	          					message = "User already have a note."
	          				end
		          		else
		          			message = "Invalid user Id"
		          		end
		          	else
		          		message = "Please send user id and note."
		          	end
					render status: "200", json: {
						message: message,
						status: status
					}
				rescue Exception => e
					forbidden_error(e)
				end
		    end

		    def get_note
		    	begin
		          	user_id = params["user_id"]
		          	note_text = ""
		          	message = ""
		          	status = false
		          	user = User.find(user_id) rescue nil
		          	if user_id.present? and user.present?
	          			if user.note.present?
		          			note_text = user.note.note_text
		          			status = true
		          			message = "success"
		          		else
			          		message = "User does not have any note."
		          		end
		          	else
		          		message = "Invalid user Id."
		          	end
					render status: "200", json: {
						note_text: note_text,
						message: message,
						status: status
					}
				rescue Exception => e
					forbidden_error(e)
				end
		    end
    	end
  	end
end
