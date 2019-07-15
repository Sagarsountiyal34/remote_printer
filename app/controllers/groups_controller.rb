require 'twilio-ruby'
class GroupsController < ApplicationController
	before_action :authenticate_user!
	protect_from_forgery prepend: true

	def new
		ready_to_print_group = current_user.check_if_any_group_ready_for_payment
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
			group.otp = group.generate_otp
			@upload_document.generate_deep_copy_in_directory(group.otp)
			if @upload_document.have_to_create_pdf_from_file?
				@upload_document.create_pdf_from_file(group.otp)
			end
			@upload_document.insert_otp_into_document(group.otp)
			@upload_document.generate_preview_file
			@upload_document.add_documents(group) # addding into group
			if group.save
				redirect_to action: 'edit', :id =>  group.id
			else
				render 'new'
			end
		else
			# if the upload document not updated
			render 'new'
		end
	end

	def update
		if document_params['document'].present?
			upload_document = current_user.upload_documents.new(document_params)
			group = current_user.groups.find(params[:id])
			if upload_document.save and group.present?
				upload_document.generate_deep_copy_in_directory(group.otp)
				if upload_document.have_to_create_pdf_from_file?
					upload_document.create_pdf_from_file(group.otp)
				end
				upload_document.insert_otp_into_document(group.otp)
				upload_document.generate_preview_file
				upload_document.add_documents(group) # addding into group
				if group.save
					redirect_to action: 'edit', :id =>  group.id
				else
					render json: {  document_error: 'Internal Server Error.Please Try Again'}, status: :unprocessable_entity
				end
			else
				render json: {  document_error: upload_document.errors.full_messages_for(:document)   }, status: :unprocessable_entity
			end
		else
			render json: {  document_error: 'Please Upload a Document'}, status: :unprocessable_entity
		end
	end

	def edit
		get_details_for_group_page
		if @group.present? == false
			redirect_to action: 'new'
		end
	end

	def list
		@printed_groups = current_user.groups.where(:status => 'completed').order_by(updated_at: :desc)
	end

	def recently_printed_groups
		@recently_printed = current_user.groups.where(status: 'completed').where(updated_at: (Time.now - 24.hours)..Time.now).order_by(updated_at: :desc)
	end

	def progress_groups
		@progress_groups = current_user.groups.where(:status.in => ['ready_for_print', 'sent_for_printing', 'processing','failed']).order_by(updated_at: :desc)
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
				redirect_to  upload_doc_path
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

	def proceed_to_payment
		group = current_user.groups.find(params[:group_id])
		if params[:type] == 'cash' or params[:type] == 'online'
			if group.update_attributes(:status => 'ready_for_print', :payment_type => params[:type])
				redirect_to action: 'edit', :id =>  group.id
			else
				render json: {  error: 'Please try again later.'}, status: :unprocessable_entity
			end
		end
	end

	def selected_page_print
		# page_array =  [3,4,5]
		# pdf_src_path = "/home/code/Downloads/11.pdf"
		# pdf_output_path = "/home/code/Downloads/22.pdf"
		# Prawn::Document.generate(pdf_output_path, :skip_page_creation => true) do
		# 	page_array.each do |page_number|
  #   			start_new_page(:template => pdf_src_path, :template_page => page_number)
		# 	end
		# end
	end

	def trying_online_payment
		current_user.groups.find(params[:group_id]).update_attributes(:status => 'ready_for_print', :payment_type => 'cash')
		@order_id =  rand(10000000..99999999).to_s
		@params = {merchant_id: '222989', order_id: @order_id, amount: '1', currency: 'INR', redirect_url: request.base_url, cancel_url: request.base_url, language: 'EN' }
		render partial: "groups/partial/payment"
		#old method
		# @ccavenue = Ccavenue::Payment.new(222989,'B76E436312C20E042F082D07F7CEBD0B', request.base_url + '/printed_groups')
		# @CCAVENUE_MERCHANT_ID = 222989
		# @access_code = 'AVKD86GG43AS18DKSA'
		# CCAvenue requires a new order id for each request
	    # so if transaction fails we can use #same ones again accross our website.
	 	# order_id =  rand(10000000..99999999).to_s
	 	# @encRequest = @ccavenue.request(order_id,100,'sagar','Gumaniwala','Shyampur','Rishikesh','249204', 'Uttarakhand','India',current_user.email,'8394848527')
	end

	def payment_confirm
	    # parameter to response is encrypted reponse we get from CCavenue
	    authDesc,verify,data = ccavenue.response(params['encResponse'])

	    # Return parameters:
	    #   Auth Description: <String: Payment Failed/Success>
	    #   Checksum Verification <Bool: True/False>
	    #   Response Data: <HASH/Array: Order_id, amount etc>
	    order_Id = data["Order_Id"][0]
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