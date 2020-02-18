class Api::V1::NotesController < ApplicationApiController
	include ActionController::ImplicitRender
	protect_from_forgery with: :null_session

    def save_note
        begin
          	user_email = params["user_email"]
          	note_text = params["note_text"]
          	message = ""
          	status = false
          	if user_email.present?
          		user = User.find_by(email: user_email)
          		if user.present?
          			if !user.note.present?
	          			note = user.create_note(:note_text => note_text)
          				message = "Note creates Successfully."
          				status = true
      				else
      					user.note.update_attribute('note_text', note_text)
      					message = "Note Updated Successfully."
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
          	note_text = ""
						pending_payment_docs=[]
          	message = ""
          	status = false
          	user = User.find_by(email: params["user_email"]) rescue nil
          	if user.present?
      			if user.note.present?
          			note_text = user.note.note_text,
								pending_payment_docs = user.note.pending_payments.map{|n| [n.document_name,n.printed_time]}.to_h
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
				pending_payment_docs: pending_payment_docs,
				message: message,
				status: status
			}
		rescue Exception => e
			forbidden_error(e)
		end
    end
end
