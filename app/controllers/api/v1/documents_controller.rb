module Api
	module V1
		class DocumentsController < ApplicationController
			include ActionController::ImplicitRender
			protect_from_forgery with: :null_session

			def update_document_status
				begin
					group_id = params["group_id"]
					document_id = params["document_id"]
					status = params["status"]
					if !group_id.present? or !document_id.present? or !status.present?
						render status: "422", json: {
	           				 message: "Group id and/or Document id and/or Status is empty."
	          			}
					else
						if status.present?
							group = Group.find(group_id)
							document = group.documents.find(document_id)
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
					forbidden_error(e)
				end
			end

			def get_all_documents
				begin
					response = {}
					Group.not_in(status: 'completed').each do |group|
							if group.documents.present?
								documents_hash = group.get_documents_for_api(request)
								if group.update_attributes(:status => 'sent_for_printing') and documents_hash.present?
									response[group.id.to_s] = documents_hash
								end
							end
					end
					if response.present?
						render status: "200", json: {
							groups: response,
							message: "Success"
						}
					else
						forbidden_error
					end
				rescue Exception => e
					forbidden_error(e)
				end
			end

			def update_group_status
				begin
					group_id = params["group_id"]
					status = params["status"]
					if !group_id.present? or !status.present?
						render status: "422", json: {
	           				 message: "Group id or status is empty."
	          			}
					else
						group = Group.find(group_id)
						if group.present?
							group.status = status
							if group.save
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
		            			message: "Group not found with given ID"
		          			}
						end
					end
				rescue Exception => e
					forbidden_error(e)
				end
			end

			def get_groups_with_status
				begin
					groups = Group.all
					render status: "200", json: {
						groups: groups,
						message: "Success"
					}
				rescue Exception => e
					forbidden_error(e)
				end
			end

			def send_error_to_admin
				begin
					if params[:error].present?
						error = params["error"]
						if ExampleMailer.sample_email(error).deliver_now
							render status: "200", json: {
	        					message: 'Mail Sent'
				        	}
				        else
				        	render status: "500", json: {
	        					message: 'Please Try Again Letter'
				        	}
				        end
					else
						render status: "500", json: {
        					message: 'Please send the error'
			        	}
					end
				rescue Exception => e
					render status: "500", json: {
        				message: e.message
			        }
				end
			end
		end
	end
end


