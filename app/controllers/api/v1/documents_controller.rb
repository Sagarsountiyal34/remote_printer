module Api
	module V1
		class DocumentsController < ApplicationController
			include ActionController::ImplicitRender
			protect_from_forgery with: :null_session

			#also check..status sshould be correct
			def update_document_and_group_status
				begin
					group_id = params["group_id"]
					document_id = params["document_id"]
					status = params["document_status"]
					if !group_id.present? or !document_id.present? or !status.present?
						render status: "422", json: {
	           				 message: "Group id and/or Document id and/or Status is empty."
	          			}
					else
						#also check status valid
						if status.present?
							group = Group.find(group_id)
							document = group.documents.find_by(:upload_document_id => document_id)
							document.status = status
							group.status = 'processing'
							if document.save and group.save
								render status: "201", json: {
									message: "Status updated successfully"
								}
							else
								render status: "500", json: {
			            			message: "Please Enter Valid Status"
			          			}
							end
						else
							render status: "422", json: {
		            			message: "Please send status of document"
		          			}
						end
					end
				rescue Exception => e
					render status: "500", json: {
            			message: "Internal Server Error. Please try after some time." + e.to_s
          			}
				end
			end

			# def get_all_documents
			# 	response = {}
			# 	status = 'ready_for_payment'
			# 	have_to_send_groups = true
			# 	User.all.each do |user|
			# 		if user.check_user_group_sent_for_print?
			# 			render status: "200", json: {
	  #             			groups: response,
	  #             			message: "Some Groups already sent for print.can't send more."
	  #           		}
	  #           		have_to_send_groups = false
	  #           		break
	  #           	end
			# 	end
			# 	if have_to_send_groups
			# 		User.all.each do |user|
			# 			if user.group.present? and user.group.status == status and user.group.documents.present?
			# 				group = user.group
			# 				documents_hash = group.get_documents_for_api(request,status)
			# 				response[group.id.to_s] = documents_hash
			# 			end
			# 		end
			# 		render status: "200", json: {
			# 			groups: response,
			# 			message: "Success"
			# 		}
			# 	end
			# end

			def get_all_documents
				@group = Group.all
			end

		end
	end
end


