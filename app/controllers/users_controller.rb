class UsersController < ApplicationController
	before_action :authenticate_user!
	protect_from_forgery prepend: true
	def upload_document
		@upload_document = UploadDocument.new
	end

	def save_document
		@upload_document = current_user.upload_documents.new(document_params)
		if @upload_document.save
			redirect_to list_documents_path
		else
			render 'upload_document'
		end
	end

	def list_documents
		@upload_documents = current_user.upload_documents.order_by(created_at: :desc)
	end

	private

		def document_params
			params.require("upload_document").permit(:document_name, :document)
		end
end
