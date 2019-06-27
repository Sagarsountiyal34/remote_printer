module Api
	module V1
		class DocumentsController < ApplicationController
			include ActionController::ImplicitRender
			protect_from_forgery with: :null_session

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

			def get_all_documents
				@groups = Group.where(:status =>'ready_for_payment' )
			end

		end
	end
end


