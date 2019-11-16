module Api
	module V1
		class NotesController < ApplicationController
			include ActionController::ImplicitRender
			protect_from_forgery with: :null_session

		    def save_notes
		        begin
		          	user_id = params["user_id"]
		          	note = params["note_text"]
		          	message = ""
		          	status = false
		          	if user_id.present? and note.present?
		          		user = User.find(user_id)
		          		if user.present?
		          			note = user.notes.new(:note_text => note)
		          			if note.save
		          				message = "Note creates Successfully."
		          				status = true
		          			else
		          				message = "Please Try again."
		          			end
		          		else
		          			message = "Invalid user Id."
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
    	end
  	end
end
