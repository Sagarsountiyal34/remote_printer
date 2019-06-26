class DocumentsController < ApplicationController
	before_action :authenticate_user!
	protect_from_forgery prepend: true
	# def remove_documents
	# 	document_ids = params[:document_ids]
	# 	current_user.upload_documents.where(:_id.in => document_ids).destroy_all
	# 	group = nil
	# 	if current_user.group.present?
	# 		group = current_user.group
	# 		group.remove_document(document_ids)
	#     	group.save
	#     end

	# 	if group.present?
	# 		total_group_item = group.get_total_group_item
	# 		render  :json => "{#{"total_group_item".to_json}:#{total_group_item.to_json},#{"message".to_json}:#{"Succesfully removed".to_json}}", status: 200
	# 	else
	# 		render json: 'Please try again later'.to_json, status: 500
	# 	end
	# end

	def upload_document
		@upload_document = UploadDocument.new
	end

	def list_documents
		@upload_documents = current_user.upload_documents.order_by(created_at: :desc)
	end

	private

		def document_params
			params.require("upload_document").permit(:document_name, :document)
		end
end