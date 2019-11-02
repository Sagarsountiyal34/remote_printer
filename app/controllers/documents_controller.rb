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

	# def upload_document
	# 	@upload_document = UploadDocument.new
	# end

	def list_documents
		@last_updated = current_user.upload_documents.present? ? current_user.upload_documents.order_by(created_at: :desc).first.updated_at.strftime("%d %B %Y , %l:%M %p") : []
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