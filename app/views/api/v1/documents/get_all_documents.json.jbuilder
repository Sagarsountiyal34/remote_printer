# begin
# 	# if Group.find_by(:status.in => ['sent_for_printing', 'processing', 'failed']).present?
# 	# 	json.set! :groups, {}
# 	# 	json.set! :message, "Some Groups already sent for print.can't send more."
# 	# else
# 	debugger
# 		json.set! 'groups' do
# 			@groups.each do |group|
# 				if group.documents.present?
# 					json.set! group.id do
# 						json.array! group.documents do |document|
# 				  			json.id document.upload_document_id.to_s
# 				  			json.name document.document_name
# 				  			json.document_url request.base_url + document.document_url
# 				  			document.status = 'sent_for_printing'
# 						end
# 					end
# 				end

# 			end
# 		end
# 		if @groups.present?
# 			json.set! :message, 'Success'
# 		else
# 			json.set! :message, 'No group present'
# 		end
# 	# end
# rescue Exception => e
# 	json.set! 'message', 'Something went wrong. Please try again after some time.'
# 	json :status => 500
# end