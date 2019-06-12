module Api
	module V1
		class DocumentsController < ApplicationController
			protect_from_forgery with: :null_session
			# before_action :set_document_by_id, only: [:update_document_status]

			def get_all_documents
				begin
					documents = UploadDocument.all
					files = []
					documents.each do |document|
						file = {}
						file['id'] = document.id
						file['name'] = document.document_name
						file['download_url'] = request.base_url + document.document_url

						files << file
						document.update_attribute("status", "pending")
					end
					render status: "200", json: {
						documents: files,
						message: "Success"
					}
				rescue Exception => e
					render status: "500", json: {
            message: "Internal Server Error. Please try after some time."
          }
				end
			end

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

			# private

			# 	def set_document_by_id
			# 		@document = UploadDocument.find(params[:id])
			# 	end
		end
	end
end
