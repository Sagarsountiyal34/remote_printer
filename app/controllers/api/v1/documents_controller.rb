module Api
	module V1
		class DocumentsController < ApplicationController
			include ActionController::ImplicitRender
			protect_from_forgery with: :null_session

			def update_document_status
				begin
					group_id = params["group_id"]
					document_id = params["document_id"]
					status = params["status"]
					if !group_id.present? or !document_id.present? or !status.present?
						render status: "422", json: {
	           				 message: "Group id and/or Document id and/or Status is empty."
	          			}
					else
						if status.present?
							group = Group.find(group_id)
							document = group.documents.find(document_id)
							document.status = status
							if group.documents.map{|g| g.status}.include?('pending')
								group.status = 'processing'
							else
								group.status = 'completed'
							end
							if document.save and group.save
								render status: "201", json: {
									message: "Status updated successfully"
								}
							else
								render status: "500", json: {
			            			message: "Please Enter Valid Status"
			          			}
							end
						else
							render status: "422", json: {
		            			message: "Please send status of document"
		          			}
						end
					end
				rescue Exception => e
					forbidden_error(e)
				end
			end

			def get_all_documents
				begin
					payment_type = params["payment_type"]
					response = {}
					message = "Try Again"
					if payment_type == 'online'
						if Group.any_online_payment_group_sent_for_printing? == false
							group = Group.not_in(:status => 'completed', :status => 'ready_for_payment').where(payment_type: payment_type).first
							if group.present? and group.documents.present?
								documents_hash = group.get_documents_for_api(request)
								if group.update_attributes(:status => 'sent_for_printing') and documents_hash.present?
									response[group.id.to_s] = documents_hash
									message = "Success"
								end
							else
								message = "Group not present for sent."
							end
						else
							message = "A Group with online payment already sent for printing."
						end
					else
						Group.not_in(status: 'completed', :status => 'ready_for_payment').each do |group|
							if group.documents.present?
								documents_hash = group.get_documents_for_api(request)
								if group.update_attributes(:status => 'sent_for_printing') and documents_hash.present?
									response[group.id.to_s] = documents_hash
									message = "Success"
								end
							end
						end
					end
					if response.present?
						render status: "200", json: {
							groups: response,
							message: message
						}
					else
						show_message(message)
					end
				rescue Exception => e
					forbidden_error(e)
				end
			end

			def update_group_status
				begin
					group_id = params["group_id"]
					status = params["status"]
					if !group_id.present? or !status.present?
						render status: "422", json: {
	           				 message: "Group id or status is empty."
	          			}
					else
						group = Group.find(group_id)
						if group.present?
							group.status = status
							if group.save
								render status: "201", json: {
									message: "Status updated successfully"
								}
							else
								render status: "500", json: {
			            			message: "Please Enter Valid Status"
			          			}
							end
						else
							render status: "422", json: {
		            			message: "Group not found with given ID"
		          			}
						end
					end
				rescue Exception => e
					forbidden_error(e)
				end
			end

			def get_groups_with_status
				begin
					groups = Group.all
					render status: "200", json: {
						groups: groups,
						message: "Success"
					}
				rescue Exception => e
					forbidden_error(e)
				end
			end

			def send_error_to_admin
				begin
					if params[:error].present?
						error = params["error"]
						if ExampleMailer.sample_email(error).deliver_now
							render status: "200", json: {
	        					message: 'Mail Sent'
				        	}
				        else
				        	render status: "500", json: {
	        					message: 'Please Try Again Letter'
				        	}
				        end
					else
						render status: "500", json: {
        					message: 'Please send the error'
			        	}
					end
				rescue Exception => e
					render status: "500", json: {
        				message: e.message
			        }
				end
			end

			def print_document
				begin
					group = Group.find(params["groupID"])
					document = group.documents.find(params["documentID"])
					if document.present?
						document.status = "sent_for_printing"
							if document.save
								render status: "201", json: {
									document: document,
									message: "Status updated successfully"
								}
							else
								render status: "500", json: {
												message: "Please Enter Valid Status"
											}
							end
					else
						render status: "422", json: {
										message: "Group not found with given ID"
									}
					end

				rescue Exception => e
					render status: "500", json: {
        				message: e.message
			        }
				end

			end

			def print_document2
				begin
					group = Group.find(params["groupID"])
					document = group.documents.find(params["documentID"])
					if document.present?
						document.processed_pages = params[:pcount]
							if (params[:pcount].to_i== document.total_pages )
								document.active = false
								document.status = "completed"
							end
							if document.save
								render status: "201", json: {
									document: document,
									page_number_updated: true,
									message: "page number updated"
								}
							else
								render status: "500", json: {
												message: "Something Went Wrong!"
											}
							end
					else
						render status: "422", json: {
										message: "Group not found with given ID"
									}
					end

				rescue Exception => e
					render status: "500", json: {
        				message: e.message
			        }
				end

			end

			def mark_document_as_printed
				begin
					group = Group.find(params["groupID"])
					document = group.documents.find(params["documentID"])

					document.status = "completed"
					document.processed_pages = document.total_pages

					if document.save
						render status: "200", json: {
							document: document,
							message: "document set to pending"
						}
					else
						render status: "500", json: {
										message: document.errors.full_messages
									}
					end

				rescue Exception => e
					render status: "500", json: {
								message: e.message
							}
				end
			end

			def fetch_in_printing_doc_to_print
				begin
					doc_to_print = ""
					active_group = Group.all_of({:'documents.active' => true }).map{|grp| grp.attributes.merge(documents: grp.documents.where(active: true),user_email: grp.user.email)}
					# check if any group with active document is there

					if active_group.present?
						# return first active document
						doc_to_print= active_group.first[:documents].first

						render status: "201", json: {
							document: doc_to_print,
							groupID: active_group.first[:_id].to_str,
							continue_printing: true
						}
					else
						groups = Group.all_of({:'documents.status' => "sent_for_printing" }).map{|grp| grp.attributes.merge(documents: grp.documents.where(status: "sent_for_printing"),user_email: grp.user.email)}
						if groups.present?
							doc_to_print = groups.first[:documents].first

							if doc_to_print.update(active: true)

									render status: "200", json: {
										document: doc_to_print,
										groupID: groups.first[:_id].to_str,
										continue_printing: true
									}
							else
									# bacho
							end
						else
							render status: "201", json: {
								continue_printing: false
							}

						end
					end


				rescue Exception => e
					forbidden_error(e)
				end
			end


		end


	end
end
