class Api::V1::GroupsController < ApplicationApiController
	include ActionController::ImplicitRender
	include GroupHelper
	protect_from_forgery with: :null_session

    def get_groups_wd_status
	    begin
	      groups_status= params["GStatus"]
	      if groups_status=="all"
	        groups = @current_company.groups.where(status: "ready_for_print").map{|g| g.attributes.merge(user_email: g.user.email, phone_number: g.user.phone_number, total_cost: group_total(g),note_text_present: g.user.note.try(:note_text).present?, net_cost: get_net_cost_of_groups(g))}
	      else
	        groups= get_groups(groups_status)
	      end
					render json: {
						status: "200",
						groups: groups,
						message: "Success"
					}
		rescue Exception => e
			forbidden_error(e)
		end
    end

    def get_groups_with_document_status
        begin
          	doc_status= params["doc_status"]
          	if !doc_status.present?
            	groups = @current_company.groups
          	else
            	groups= get_groups_with_doc_status(doc_status)
          	end
			render status: "200", json: {
				groups: groups,
				message: "Success"
			}
		rescue Exception => e
			forbidden_error(e)
		end
    end



	def mark_all_as_printed
		begin
			group = @current_company.groups.find(params["groupID"])
			# old_check_for_pending_payments = group.user.note.try(:pending_payments).present?

			if group.present?
				group.documents.find_all { |m| m.update_attributes(status: "completed") }
				# if params[:completedPU]=="completed_&_unpaid"
				# 		new_check_for_pending_payments = true
				# else
				# 		new_check_for_pending_payments = group.user.note.try(:pending_payments).present?
				# end

				# if old_check_for_pending_payments == new_check_for_pending_payments
				# 		pending_payment_status = "DontSet"
				# else
				# 		pending_payment_status = new_check_for_pending_payments
				# end

				render status: "200", json: {
					group: group,
					# any_payment_pending: pending_payment_status,
					message: "Success"
				}
			else
				render status: "422", json: {
						message: "Group not found with given ID"
					}

			end

		rescue Exception => e
			forbidden_error(e)
		end

	end

	def print_group_again
		begin
			group = @current_company.groups.find(params["groupID"])
			if group.present?
				group.documents.update_all(status: "sent_for_printing",processed_pages:0,active: false)
				render status: "200", json: {
					group: group,
					message: "Success"
				}
			else
				render status: "422", json: {
						message: "Group not found with given ID"
					}

			end

		rescue Exception => e
			forbidden_error(e)
		end
	end

	def change_paid_status
		begin
			group = @current_company.groups.find(params["groupID"])
			if group.present?
				group.paid =  true
				if group.save
				group = group.attributes.merge(user_email: group.user.email,total_cost: group_total(group), net_cost: get_net_cost_of_groups(group))
					render status: "200", json: {
						group: group,
						message: "Success"
					}
				else
					render status: "200", json: {
						group: group,
						message: group.errors.full_messages
					}
				end

			else
				render status: "422", json: {
						message: "Group not found with given ID"
					}

			end

		rescue Exception => e
			forbidden_error(e)
		end
	end

	def print_next_doc_from_group
		begin
			group = @current_company.groups.find(params["groupID"])
			if group.present?
				printing_doc = ""
				printing_doc = group.documents.where(status: "sent_for_printing")&. first

				admin = User.where(role: "admin").first
				printer_name=""
				if printing_doc.print_type ==="color"
					printer_name = admin.printer_setting.color_printer if admin.printer_setting.present?
				elsif  printing_doc.print_type ==="black_white"
					printer_name = admin.printer_setting.bw_printer if admin.printer_setting.present?
				end
				#
				render json: { status: "200",
					group: group,
					printing_doc: printing_doc,
					printer_name: printer_name,
					message: "Success"
				}
			else
				render status: "422", json: {
						message: "Group not found with given ID"
					}

			end

		rescue Exception => e
			forbidden_error(e)
		end
	end

    def get_groups(groups_status)
        return  @current_company.groups.where(status: "ready_for_print").all_of({:'documents.status' => groups_status }).map{|grp| grp.attributes.merge(documents: grp.documents.where(status: groups_status),user_email: grp.user.email, phone_number: grp.user.phone_number, total_cost: group_total(grp),note_text_present: grp.user.note.try(:note_text).present?, net_cost: get_net_cost_of_groups(grp))}
    end
    def get_groups_with_doc_status(doc_status)
      	return  @current_company.groups.all_of({:'documents.status' => doc_status })
    end
end
