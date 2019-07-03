require 'twilio-ruby'
class GroupsController < ApplicationController
	before_action :authenticate_user!
	protect_from_forgery prepend: true

	def new
		ready_to_print_group = current_user.check_if_any_group_ready_to_print
		if ready_to_print_group.present?
			redirect_to action: 'edit', :id =>  ready_to_print_group.id
		else
			@upload_document = UploadDocument.new
		end
	end

	def create
		@upload_document = current_user.upload_documents.new(document_params)
		if @upload_document.save
			group = current_user.groups.new
			@upload_document.add_documents(group) # addding into group
			if group.save
				redirect_to action: 'edit', :id =>  group.id
			end
		else
			# if the upload document not updated
			render 'new'
		end
	end

	def update
		upload_document = current_user.upload_documents.new(document_params)
		group = current_user.groups.find(params[:id])
		if upload_document.save and group.present?
			upload_document.add_documents(group) # addding into group
			group.save
			redirect_to action: 'edit', :id =>  group.id
		else
			render json: {  document_error: upload_document.errors.full_messages_for(:document)   }, status: :unprocessable_entity
		end
	end

	def edit
		get_details_for_group_page
	end

	def list
		@printed_groups = current_user.groups.where(:status => 'completed')
	end

	def progress_groups
		@progress_groups = current_user.groups.where(:status.in => ['sent_for_printing', 'processing'])
	end

	def remove_document_from_group #via ajax
		document_ids = params[:document_ids]
		group = current_user.groups.find(params[:id])
		group.documents.where(:id.in => document_ids).destroy
		if group.save!
			get_details_for_group_page
			if @group.present?
				render partial: 'groups/partial/group_details'
			else
				render json: {  group_present: false, url: request.base_url   }, status: 500
			end
		else
			render json: 'Please try again later'.to_json, status: 500
		end
	end

	def add_document_to_group #via ajax
		group = current_user.groups.find(params[:id])
		document_ids = params[:document_ids]
		group.add_documents(document_ids)
		if group.save
			get_details_for_group_page
			render partial: 'groups/partial/group_details'
		else
			render json: 'Please try again later'.to_json, status: 500
		end
	end

	def test_whatsapp_twillio_api
		account_sid = "AC8e9c769146578c92b27c86b4e884445f" # Your Account SID from www.twilio.com/console
		auth_token = "c565824da97e24c1f64b8ff01e97c2d2"   # Your Auth Token from www.twilio.com/console
		@client = Twilio::REST::Client.new account_sid, auth_token
		message = @client.messages.create(
							media_url: 'http://139.59.35.254:82/uploads/530cbd3e3ed7eb959b4949dfa0924457.jpg',
                            body: 'Your Twilio code is 12345',
                            from: 'whatsapp:+14155238886',
                            to: 'whatsapp:+918394848527' )

		puts message.sid #save into group ,also generate otp and save into group

	end

	private

	def document_params
		params.require("upload_document").permit(:document_name, :document)
	end

	def get_details_for_group_page
		@group = Group.find(params[:id])
		if @group.present?
			@documents = @group.documents.order_by(created_at: :desc)
			@upload_document = UploadDocument.new

			uploaded_doc_ids = @group.documents.map{|d| d.upload_document_id.to_s}
			@all_documents = current_user.upload_documents.not_in(:_id => uploaded_doc_ids).order_by(created_at: :desc)
		end
	end


end