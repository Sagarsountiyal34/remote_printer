require 'twilio-ruby'
require 'socket'
class GroupsController < ApplicationController
	include PaytmHelper::EncryptionNewPG
	before_action :authenticate_user!, except: [:new]
	protect_from_forgery prepend: true, except: [:payment_response]

	def new
		if current_user.present?
			ready_to_print_group = current_user.check_if_any_group_ready_for_payment
			if ready_to_print_group.present?
				redirect_to action: 'edit', :id =>  ready_to_print_group.id
			else
				@upload_document = UploadDocument.new
			end
		else
			@upload_document = UploadDocument.new
		end
		@companies= Company.all
	end

		def create
		count = 1
		response = {}
		group = current_user.groups.new
		group.otp = group.generate_otp
		group.company = Company.find(params['company_id'])
		redirect_status = true
		if params[:history_document_ids].present?
			document_ids = params[:history_document_ids].split(',')
			group.add_documents(document_ids)
		end
		success_count = 0
		loop do
			begin
				params_for_document = params.require('upload_document').require(count.to_s).permit(:document_name, :document, :print_type, :page_detail) rescue break
				@upload_document = UploadDocument.new(params.require('upload_document').require(count.to_s).permit(:document_name, :document, :print_type))	
			rescue Exception => e
				break
			end
			response[count-1] = []

			if @upload_document.save
				begin
					page_arr =  params_for_document[:page_detail].split(',')
					if page_arr.present? && page_arr[0] != "all"
						PdfService.replace_pdf_with_selected_page(@upload_document.get_absolute_path, page_arr)
					end
					@upload_document.add_pdf_extension_if_not_present
					@upload_document.generate_deep_copy_in_directory(group.otp)
					if @upload_document.have_to_create_pdf_from_file?
						@upload_document.create_pdf_from_file(group.otp)
					end
					# @upload_document.insert_otp_into_document(group.otp)
					@upload_document.generate_preview_file
					file_type = FileInfo.get_file_media_type(@upload_document.document_url)
					if file_type == 'office' or file_type == 'PDF'
						page_count = PDF::Reader.new(@upload_document.get_absolute_preview_url).page_count rescue ""
						page_count = Pdfinfo.new(@upload_document.get_absolute_preview_url).page_count if !page_count.present?
						@upload_document.total_pages = page_count
					end
				rescue Exception => e
					redirect_status = false
					next
				end

				@upload_document.save
				@upload_document.add_documents(group)
				response[count-1].push(true)
				response[count-1].push("Document Uploaded")
				success_count = success_count + 1
			else
				response[count-1].push(false)
				response[count-1].push(@upload_document.errors.full_messages.first)
				redirect_status = false
			end
			count = count + 1
		end
		if group.documents.length > 0 and group.save
			if redirect_status == true or success_count > 0
				render :js => "window.location = '#{group_page_url(:id => group.id.to_s)}'"
			else
				render json: {status: true, message: response, group_id: group.id.to_s, redirect_url: group_page_url(:id => group.id)}, status: 200
			end
		else
			group.destroy
			render json: {status: false, message: response}.to_json, status: 200
		end
	end

	def update
		if document_params['document'].present?
			upload_document = current_user.upload_documents.new(document_params)
			group = current_user.groups.find(params[:id])
			if upload_document.save and group.present?
				page_arr =  params.require("upload_document").permit(:page_details)[:page_details].split(',')
				if page_arr.present? && page_arr[0] != "all"
					PdfService.replace_pdf_with_selected_page(upload_document.get_absolute_path, page_arr)
				end
				upload_document.add_pdf_extension_if_not_present
				upload_document.generate_deep_copy_in_directory(group.otp)
				if upload_document.have_to_create_pdf_from_file?
					upload_document.create_pdf_from_file(group.otp)
				end
				# upload_document.insert_otp_into_document(group.otp)
				upload_document.generate_preview_file
				file_type = FileInfo.get_file_media_type(upload_document.document_url)
				if file_type == 'office' or file_type == 'PDF'
						page_count = PDF::Reader.new(upload_document.get_absolute_preview_url).page_count rescue ""
						page_count = Pdfinfo.new(upload_document.get_absolute_preview_url).page_count if !page_count.present?
						upload_document.total_pages = page_count	
				end
				upload_document.save
				upload_document.add_documents(group) # addding into group
				if group.save
					redirect_to action: 'edit', :id =>  group.id
					# render json: 'success'.to_json, status: 200
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
		# @recently_printed = current_user.groups.where(status: 'completed').where(updated_at: (Time.now - 24.hours)..Time.now).order_by(updated_at: :desc)
		@recently_printed = Group.order_by(updated_at: :desc).all_of({:'documents.status' => 'completed'}).map{|grp| grp.attributes.merge(documents: grp.documents.where(status: 'completed'),user_email: grp.user.email)}
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
		group = current_user.groups.find(params[:id])
		if params[:type] == 'cash'
			if group.update_attributes(:status => 'ready_for_print', :payment_type => 'cash', :submitted_time => Time.now, :final_amount => group.get_amount_after_discount)
				get_details_for_group_page
				render partial: 'groups/partial/group_details'
			else
				render json: 'Please try again later'.to_json, status: 500
			end
		else
			payment_detail = group.payment_details.new
			new_params = params.merge(payment_detail_id: payment_detail.id.to_s, amount: group.get_amount_after_discount)
			new_params_arr = prepare_payment_params(new_params)
			discount = Discount.where(:status => true).first
			if discount.present?
				payment_detail.amount = new_params_arr[0]['TXN_AMOUNT'] * 100 / (100 - discount.discount_value.to_f)
				payment_detail.discount = discount.discount_value
			else
				payment_detail.amount = new_params_arr[0]['TXN_AMOUNT']
			end
			payment_detail.final_amount  = new_params_arr[0]['TXN_AMOUNT']
			payment_detail.save
			@param_list = new_params_arr[0]
			@checksum_hash =  new_params_arr[1]
			@payment_url = new_params_arr[2]
		end
	end

	def payment_response
		payment_detail = PaymentDetail.find(params['ORDERID'])
		payment_detail.transaction_id = params['TXNID']
		payment_detail.payment_mode = params['PAYMENTMODE']
		payment_detail.currency = params['CURRENCY']
		payment_detail.status = params['STATUS']
		payment_detail.response_code = params['RESPCODE']
		payment_detail.response_message = params['RESPMSG']
		payment_detail.gateway_name = ''
		payment_detail.bank_tx_id = params['BANKTXNID'].to_s
		payment_detail.bank_name = params['BANKNAME']
		payment_detail.save
		if params['RESPCODE'] == "01"
			group = payment_detail.group
			group.update_attributes(:status => 'ready_for_print', :payment_type => 'online', :submitted_time => Time.now, :paid => true)
			flash[:message] = "Transaction Successfull"
		else
			flash[:errors] = params['RESPMSG']
		end
		redirect_to action: 'edit', :id =>  payment_detail.group.id
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

	def get_documents_for_history
		group = current_user.groups.find(params[:group_id])
		if group.present?
			uploaded_doc_ids = group.documents.map{|d| d.upload_document_id.to_s}
			all_documents = current_user.upload_documents.not_in(:_id => uploaded_doc_ids).order_by(created_at: :desc)
		else
			all_documents = current_user.upload_documents.order_by(created_at: :desc)
		end
		total_record = all_documents.length
		if params[:search][:value].present?
			upload_documents =	all_documents.any_of({ :document_name => /.*#{params[:search][:value]}.*/ })
			filter_record = upload_documents.length
		else
			filter_record = total_record
			page_number_index = params[:page_number].to_i
			if  page_number_index > 0
				offset_value = page_number_index * 10
				upload_documents = all_documents.order_by(created_at: :desc).limit(10).offset(offset_value).to_a
			else
				upload_documents = all_documents.order_by(created_at: :desc).to_a.first(10)
			end
		end
		all_doc = []
		upload_documents.each do |doc|
			document = {}
			document[:document_id] = doc.id.to_s
			document[:document_name] = doc.document_name
			document[:type] = FileInfo.get_file_media_type(doc.document_url)
			document[:preview_url] = doc.get_preview_url
			all_doc.push(document)
		end
		respond_to do |f|
    		f.json {render :json => {
    			documents: all_doc,
                draw: params['draw'].to_i,
                recordsTotal: total_record,
                recordsFiltered: filter_record,
    		}
    	}
		end

	end
	def approve_disapprove_group_doc
		begin
			group = Group.find(params[:group_id])
			group_doc = group.documents.find(params[:group_doc_id])
			if group_doc.update_attributes(:is_approved =>  !to_boolean(params[:is_active]), :status => 'sent_for_printing')
				@user = User.includes(:groups).find(group.user_id)
				@groups = @user.groups.order_by(submitted_time: :desc).select{|g| g.status == 'ready_for_print'}
				render partial: 'users/group_list'
			else
				render json: { message: false }.to_json, status: 422
			end	
		rescue Exception => e
			render json: { message: false }.to_json, status: 500
		end
	end

	def create_pdf_with_selected_page
		begin
			group = current_user.groups.find(params[:id])
			group_doc = group.documents.find(params[:group_doc_id])
			pdf_path = group_doc.get_absolute_preview_path
			remove_page_arr = params["pages_to_select"].split(',')
			new_pdf = CombinePDF.new
			i = 1
			CombinePDF.load(pdf_path).pages.each do |page|
				new_pdf << page if remove_page_arr.include?i.to_s
				i = i + 1
			end
			new_pdf.save pdf_path
			group_doc.total_pages = remove_page_arr.length
			group_doc.save
			group.reload
			group.save
			get_details_for_group_page
			render partial: 'groups/partial/group_details'
		rescue Exception => e
			render json: { message: false }.to_json, status: 500
		end
	end

	private

	def to_boolean(str)
  		str == 'true'
	end
	
	def document_params
		params.require("upload_document").permit(:document_name, :document)
	end

	def get_details_for_group_page
		@group = Group.find(params[:id])
		if @group.present?
			@documents = @group.documents.order_by(created_at: :desc)
			@upload_document = UploadDocument.new
			discount = Discount.where(:status => true).first
			@discount_value = discount.present? ? discount.discount_value : ''

			# uploaded_doc_ids = @group.documents.map{|d| d.upload_document_id.to_s}
			# @all_documents = current_user.upload_documents.not_in(:_id => uploaded_doc_ids).order_by(created_at: :desc)
		end
	end


end