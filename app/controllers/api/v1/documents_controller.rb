module Api
	module V1
		class DocumentsController < ApplicationController
			protect_from_forgery with: :null_session


			def update_document_status
				begin
					status = params["document"]["status"]
					if !params[:id].present?
						render status: "422", json: {
	            message: "Document id is empty"
	          }
					elsif params[:id].present?
						if status.present?
							document = UploadDocument.find(params[:id])
							if document.update_attribute("status", status)
								render status: "201", json: {
									message: "Status updated successfully"
								}
							else
								render status: "500", json: {
			            message: "Internal Server Error. Please try after some time."
			          }
							end
						else
							render status: "422", json: {
		            message: "Please send valid status"
		          }
						end
					end
				rescue Exception => e
					render status: "500", json: {
            message: "Internal Server Error. Please try after some time."
          }
				end
			end

			def get_all_documents
				response = {}
				status = 'pending'
				User.all.each do |user|
					if user.group.present? and user.group.status == status
						group = user.group
						response[group.id.to_s] = []
						documents = group.documents
						documents.all.each do |document|
							if document.status == status
								document_hash = {}
								document_hash['id'] = document.upload_document_id.to_s
								document_hash['path'] = request.base_url + document.document_url
								document_hash['name'] = document.document_name
								document_hash['status'] = document.status
								response[group.id.to_s] << document_hash
							end
						end
					end
				end
				debugger
				render status: "200", json: {
						groups: response,
						message: "Success"
				}
			end
		end
	end
end
