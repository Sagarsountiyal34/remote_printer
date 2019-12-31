class DocumentsController < ApplicationController
	before_action :authenticate_user!, except: [:save_doc_without_user]
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

	# def upload_document
	# 	@upload_document = UploadDocument.new
	# end

	def list_documents
		@last_updated = current_user.upload_documents.present? ? current_user.upload_documents.order_by(created_at: :desc).first.updated_at.strftime("%d %B %Y , %l:%M %p") : []
	end



	def save_doc_without_user
		user = User.find_by(:phone_number => params[:phone_number])
		if user.phone_otp == params[:otp]
			redirect_status = true
			count = 1
			response = {}
			group = user.groups.where(:status => 'ready_for_payment').first
			if !group.present?
				group = user.groups.new
				group.otp = group.generate_otp
			end
			group.company = Company.find(params['company_id'])
			response['source'] = 'without_user'
			loop do
				begin
					@upload_document = UploadDocument.new(params.require('upload_document').require(count.to_s).permit(:document_name, :document, :print_type))
				rescue Exception => e
					break
				end
				response[count-1] = []
				if @upload_document.save
					@upload_document.add_pdf_extension_if_not_present
					@upload_document.generate_deep_copy_in_directory(group.otp)
					if @upload_document.have_to_create_pdf_from_file?
						@upload_document.create_pdf_from_file(group.otp)
					end
					# @upload_document.insert_otp_into_document(group.otp)
					@upload_document.generate_preview_file
					file_type = FileInfo.get_file_media_type(@upload_document.document_url)
					if file_type == 'office' or file_type == 'PDF'
						reader = PDF::Reader.new(@upload_document.get_absolute_preview_url)
						@upload_document.total_pages = reader.page_count
					end
					@upload_document.save
					@upload_document.add_documents(group)
					response[count-1].push(true)
					response[count-1].push("Document Uploaded")
				else
					redirect_status = false
					response[count-1].push(false)
					response[count-1].push(@upload_document.errors.full_messages.first)
				end
				count = count + 1
			end
			if group.documents.length > 0 and group.save
				sign_in(user, scope: :user)
				if redirect_status == true or count == 2
					render :js => "window.location = '#{group_page_url(:id => group.id.to_s)}'"
				else
					render json: {status: true, message: response, group_id: group.id.to_s, redirect_url: group_page_url(:id => group.id)}, status: 200
				end
			else
				group.destroy
				render json: {status: false, message: response}.to_json, status: 200
			end
		else
			render json: {status: false, message: "Please Enter valid otp"}.to_json, status: 200
		end
	end
	def get_documents
		total_record = current_user.upload_documents.length
		if params[:search][:value].present?
			upload_documents =	current_user.upload_documents.any_of({ :document_name => /.*#{params[:search][:value]}.*/ })
			filter_record = upload_documents.length
		else
			filter_record = total_record
			page_number_index = params[:page_number].to_i
			if  page_number_index > 0
				offset_value = page_number_index * 10
				upload_documents = current_user.upload_documents.order_by(created_at: :desc).limit(10).offset(offset_value).to_a
			else
				upload_documents = current_user.upload_documents.order_by(created_at: :desc).to_a.first(10)
			end
		end
		all_doc = []
		upload_documents.each do |doc|
			document = {}
			document[:document_name] = doc.document_name
			document[:type] = FileInfo.get_file_media_type(doc.document_url)
			if doc.is_document_deleted?
				document[:preview_url] = false
			else
				document[:preview_url] = doc.get_preview_url
			end
			document[:total_pages] = doc.total_pages
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
end