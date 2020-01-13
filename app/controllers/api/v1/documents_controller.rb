module Api
	module V1
		class DocumentsController < ApplicationApiController
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
								document.is_approved =  false
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
					# debugger
					document.status = "completed"
					if document.save
						render status: "200", json: {
							document: document,
							# page_number_updated: true,
							message: "Document Completed"
						}
					else
						render status: "500", json: {
										message: document.errors.full_messages
									}
					end
					# old_check_for_pending_payments = document.group.user.note.try(:pending_payments).present?
					#
					# # document.status = "completed"
					# document.status = params[:completedPU]
					#
					# document.processed_pages = document.total_pages
					#
					# if document.save
					# 	if params[:completedPU]=="completed_&_unpai"
					# 			any_payment_pending = true
					# 	else
					# 			any_payment_pending = document.group.user.note.try(:pending_payments).present?
					# 	end
					#
					# 	if old_check_for_pending_payments == any_payment_pending
					# 			pending_payment_status = "DontSet"
					# 	else
					# 		  pending_payment_status = any_payment_pending
					# 	end
					# 	# groups = document.group.user.groups.where(status: "ready_for_print").map{|g| g.attributes.merge(user_email: g.user.email,note_text_present: g.user.note.try(:note_text).present?)}
						# render status: "200", json: {
						# 	# any_payment_pending: pending_payment_status,
						# 	# groups: groups,
						# 	document: document,
						# 	message: "document set to pending"
						# }
					# else
					# 	render status: "500", json: {
					# 					message: document.errors.full_messages
					# 				}
					# end

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


			def change_document_status

					begin
						group = Group.find(params["groupID"])
						document = ""
						document = group.documents.find(params["documentID"]) if group.present?
						if document.present?
								if document.update_attribute(status: 'sent_for_printing')
									render status: "200", json: {
										document: document,
										message: "Status updated successfully"
									}
								else
									generate_error_response("304","")
								end
						else
							generate_error_response("404","Docment not found with given ID")

						end

					rescue Exception => e
						generate_error_response("500",e.message)
					end

			end

			def change_status_and_active

					begin
						group = Group.find(params["groupID"])
						document = ""
						document = group.documents.find(params["documentID"]) if group.present?
						if document.present?
								if document.update_attributes(status: 'sent_for_printing',active:true)
									admin = User.where(role: "admin").first
									printer_name=""
									if document.print_type ==="color"
										printer_name = admin.printer_setting.color_printer if admin.printer_setting.present?
									elsif  document.print_type ==="black_white"
										printer_name = admin.printer_setting.bw_printer if admin.printer_setting.present?
									end
									document.attributes.merge(printer_name:printer_name)
									render status: "200", json: {
										document: document,
										message: "Status updated successfully"
									}
								else
									render status: "422", json: {
													message: document.errors.full_messages
												}
								end
						else
							generate_error_response("404","Docment not found with given ID")

						end

					rescue Exception => e
						generate_error_response("500",e.message)
					end

			end

			def get_document_details

					begin
						group = Group.find(params["groupID"])
						document = group.documents.find(params["documentID"]) if group.present?
						if document.present?
							admin = User.where(role: "admin").first
							printer_name=""
							if document.print_type ==="color"
								printer_name = admin.printer_setting.color_printer if admin.printer_setting.present?
							elsif  document.print_type ==="black_white"
								printer_name = admin.printer_setting.bw_printer if admin.printer_setting.present?
							end
							render status: "200", json: {
								document: document,
								printer_name: printer_name,
								message: "Status updated successfully"
							}
						else
							generate_error_response("404","Docment not found with given ID")

						end

					rescue Exception => e
						generate_error_response("500",e.message)
					end

			end

			def fetch_document_to_print
				begin
					doc_to_print=""
					printer_name=""
					group = Group.find(params["groupID"])
					admin = User.where(role: "admin").first
					if group.present?
						doc_to_print = group.documents.where(:status=>"sent_for_printing").first
						if doc_to_print.present?
							doc_to_print.update_attributes(active: true)
							if 	doc_to_print.print_type ==="color"
								printer_name = admin.printer_setting.color_printer if admin.printer_setting.present?
							elsif doc_to_print.print_type ==="black_white"
								printer_name = admin.printer_setting.bw_printer if admin.printer_setting.present?
							end
						end
					  doc_to_print = doc_to_print.attributes.merge(printer_name:printer_name)
						render status: "200", json: {
							document: doc_to_print,
							message: "Status updated successfully"
						}
					else
						render status: "422", json: {
								message: "Group not found with given ID"
							}
					end
				rescue Exception => e
					generate_error_response("500",e.message)
				end
			end


			def get_doc_to_print
						begin
								doc_to_print=""; group=""
								active_group = Group.all_of({:'documents.active' => true }).map{|grp| grp.attributes.merge(documents: grp.documents.where(active: true),user_email: grp.user.email)}

								if active_group.present?
									group = active_group.first
								else
									groups_set_for_printing = Group.all_of({:'documents.status' => "sent_for_printing" }).map{|grp| grp.attributes.merge(documents: grp.documents.where(status: "sent_for_printing"),user_email: grp.user.email)}
									group = groups_set_for_printing.first if groups_set_for_printing.present?
								end
								if group.present?
										doc_to_print = group[:documents].first
										group_id = group[:_id].to_str

										if !doc_to_print.active
											doc_to_print.active= true
											if doc_to_print.save
												Rails.logger.info("document-active true done")
											else
												Rails.logger.info("document-active true not done")
												render status: "200", json: {
													continue_printing: false
												} and  return
											end
										end
										admin = User.where(role: "admin").first
										printer_name=""
										if doc_to_print.print_type ==="color"
											printer_name = admin.printer_setting.color_printer if admin.printer_setting.present?
										elsif  doc_to_print.print_type ==="black_white"
											printer_name = admin.printer_setting.bw_printer if admin.printer_setting.present?
										end
										render status: "200", json: {
											document: doc_to_print,
											groupID: group_id,
											printer_name: printer_name,
											continue_printing: true
										}
								else
										render status: "200", json: {
											continue_printing: false
										}
								end
						rescue Exception => e
							render status: "500", json: {
										message: e.message
							}
						end

			end


			def change_progress_page_count

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
								 render status: "200", json: {
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
					 generate_error_response("500",e.message)

				 end

			end

			def update_doc_print_type
        begin
					group = Group.find(params["groupID"])
					document = group.documents.find(params["documentID"])
           if document.present?
            document.print_type=params[:type]
						if document.save
							render status: "200", json: {
								document: document,
								message: "updated"
							}
						else
							render status: "422", json: {
											message: document.errors.full_messages
										}
						end
          else
						render status: "422", json: {
							message: "Document not found with given ID"
						}
          end
				rescue Exception => e
					forbidden_error(e)
				end
        # admin = User.find_by(email: params[:email])
      end

			def re_print_doc
					begin
						group = Group.find(params["groupID"])
						document = group.documents.find(params["documentID"])

						document.processed_pages = 0

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

			def interrupt_cancel_document
					begin
							group = Group.find(params["groupID"])
							document = group.documents.find(params["documentID"])
							if document.active && document.processed_pages >0
								document.status = "interrupted"
								document.active = false
							else
								document.status = "pending"
							end

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

			private
			def generate_error_response(code,message)
				render status: code, json: {
					message: message
				}
			end


		end


	end
end
