class GroupsController < ApplicationController
	def list
		@group_doc = nil
		if current_user.group.present? 
			@group_doc = current_user.group.documents
		end
	end

	def add_document_to_group
		group = current_user.group
		document_ids = params[:document_ids]
		if !group.present?
			group = Group.new
			group.user = current_user
		end
		documents = current_user.upload_documents.where(:_id.in => document_ids)
		documents.each do |document|
			group_document = GroupDocument.new(document_name: document.document_name, upload_document_id: document.id, document_data: document.document_data, status: 'ready_for_payment')
			group.documents << group_document
			group.status = 'ready_for_payment'
		end
		if group.save
			total_group_item = current_user.group.get_total_cart_item
			render  json: {
				total_group_item: total_group_item,
				message: 'Successfully added',
				status: 200
			}
		else
			render json: 'Please try again later'.to_json, status: 500
		end
	end

	def remove_document_from_group
		document_ids = params[:document_ids]
		group = current_user.group
		document_ids.each { |id|
    		if group.document_ids.include?(id)
    			group.document_ids.delete(id)
    			doc = current_user.upload_documents.where(:_id => id).first
    			doc.status = 'pending'
    			doc.save
    		end
    	}
		if group.save
			total_cart_item = current_user.group.get_total_cart_item
			render  :json => "{#{"total_cart_item".to_json}:#{total_cart_item.to_json},#{"message".to_json}:#{"Succesfully removed".to_json}}", status: 200
		else
			render json: 'Please try again later'.to_json, status: 500
		end
	end

	def start_payment
		debugger
	end
end