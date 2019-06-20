class GroupsController < ApplicationController
	def list
		@group_doc = nil
		if current_user.group.present? 
			doc_ids = current_user.group.document_ids
   			@group_doc = current_user.upload_documents.where(:_id.in => doc_ids)
		end
		# render 'list'
	end
	def add_document_to_group
		document_ids = params[:document_ids]
		if !current_user.group.present?
			group = Group.new
			group.user = current_user
		end
		group = current_user.group
		document_ids.each { |id|
    		if !group.document_ids.include?(id)
    			group.document_ids.push(id)
    			doc = current_user.upload_documents.where(:_id => id).first
    			doc.status = 'ready_for_payment'
    			doc.save
    		end
    	}
		if group.save
			total_cart_item = current_user.group.get_total_cart_item
			render  :json => "{#{"total_cart_item".to_json}:#{total_cart_item.to_json},#{"message".to_json}:#{"Succesfully added".to_json}}", status: 200
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
end