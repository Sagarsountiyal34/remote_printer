class GroupsController < ApplicationController
	def new
		if current_user.check_if_any_group_ready_to_print?
			@group = current_user.groups.find_by(:status => 'ready_for_payment')
			redirect_to action: 'edit', :id =>  @group.id
		else
			@upload_document = UploadDocument.new
		end
	end

	def create
		@upload_document = current_user.upload_documents.new(document_params)
		if 	params[:group_id].present?
			@group = Group.find(:id => params[:group_id])
		else
			@group = Group.new
			@group.user = current_user
		end
		@upload_document.save
		@upload_document.add_documents(@group) # addding into group
		if @group.save
			redirect_to action: 'edit', :id =>  @group.id
		else
			redirect_to 'new'
		end
	end
	def edit
		get_details_for_group_page
	end

	def list
		@printed_groups = current_user.groups.where(:status => 'completed')
	end

	def get_details_for_group_page
		@group = Group.find(params[:id])
		@documents = @group.documents
		@upload_document = UploadDocument.new

		uploaded_doc_ids = @group.documents.map{|d| d.upload_document_id.to_s}
		@all_documents = current_user.upload_documents.not_in(:_id => uploaded_doc_ids)
	end

	def remove_document_from_group
		document_ids = params[:document_ids]
		group = Group.find(:id => params[:id])
		group.remove_document(document_ids)
		if group.save
			get_details_for_group_page
			render partial: 'groups/partial/group_details'
		else
			render json: 'Please try again later'.to_json, status: 500
		end
	end

	def add_document_to_group
		group = Group.find(params[:id])
		document_ids = params[:document_ids]
		group.add_documents(document_ids)
		if group.save
			get_details_for_group_page
			render partial: 'groups/partial/group_details'
		else
			render json: 'Please try again later'.to_json, status: 500
		end
	end

	private

	def document_params
		params.require("upload_document").permit(:document_name, :document)
	end


end