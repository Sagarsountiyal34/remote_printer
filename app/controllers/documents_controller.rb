class DocumentsController < ApplicationController
	def remove_documents
		document_ids = params[:document_ids]
		current_user.upload_documents.where(:_id.in => document_ids).destroy_all
		group = nil
		if current_user.group.present?
			group = current_user.group
			group.remove_document(document_ids)
	    	group.save
	    end

		if group.present?	
			total_group_item = group.get_total_group_item
			render  :json => "{#{"total_group_item".to_json}:#{total_group_item.to_json},#{"message".to_json}:#{"Succesfully removed".to_json}}", status: 200
		else
			render json: 'Please try again later'.to_json, status: 500
		end
	end
end