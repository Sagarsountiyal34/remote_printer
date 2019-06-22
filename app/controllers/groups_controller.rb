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
		group.add_documents(document_ids)
		if group.save
			total_group_item = current_user.group.get_total_group_item
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
		group.remove_document(document_ids)
		if group.save
			total_group_item = current_user.group.get_total_group_item
			render  :json => "{#{"total_group_item".to_json}:#{total_group_item.to_json},#{"message".to_json}:#{"Succesfully removed".to_json}}", status: 200
		else
			render json: 'Please try again later'.to_json, status: 500
		end
	end

	def start_payment
	end
end