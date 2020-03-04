class Api::V1::SearchController < ApplicationApiController
	include ActionController::ImplicitRender
	protect_from_forgery with: :null_session
	include GroupHelper

  	def suggestions_for_user_email
	    begin
	      searchterm = params[:searchTerm]
	      users_emails = []
					if params[:condition] == "avoid_blank_grps"
						all_users_ids = Group.where(status:  "ready_for_print").pluck(:user_id)
						users =User.in("id": all_users_ids,"email": /.*#{searchterm}.*/i) if all_users_ids.present?

					elsif params[:condition] == "all"
						users =User.in("email": /.*#{searchterm}.*/i)

					end
	      users_emails = users.map(&:email) if users.present?
	      render status: "200", json: {
	        suggestions: users_emails,
	        message: "Success"
	      }
	    rescue Exception => e
	      generate_error_response("500",e)

	    end
	end

	def suggestions_for_Document_names
        begin
          searchterm = params[:searchTerm]
        	document_names= @current_company.groups.collection.aggregate([{'$unwind': '$documents'},{'$match':{ '$and': [{'status': "ready_for_print"},{'documents.document_name': /.*#{searchterm}.*/i}]} },{'$project': {'documents.document_name': 1,'_id':0 }}]).to_a.map{|a| a["documents"]["document_name"]}

					render status: "200", json: {
            suggestions: document_names,
            message: "Success"
          }
        rescue Exception => e
          generate_error_response("500",e)

        end
    end

	def suggestions_for_otps
        begin
          searchterm = params[:searchTerm]
          otps = []
					groups = @current_company.groups.where(status: "ready_for_print").any_of({ :otp => /.*#{searchterm}.*/i })
          otps = groups.map(&:otp) if groups.present?

          render status: "200", json: {
            suggestions: otps,
            message: "Success"
          }
        rescue Exception => e
          generate_error_response("500",e)

        end
    end

	def search_by_category
		begin
			groups=""
			case params[:category]
					when "search_with_user_email"
						user = User.find_by(email: params[:searchTerm])
						groups = user.groups.where(status: "ready_for_print", company_id: @current_company.id).map{|g| g.attributes.merge(user_email: g.user.email,total_cost: group_total(g),note_text_present: g.user.note.try(:note_text).present?)} if user.present?
					when "search_with_doc_name"
						groups = @current_company.groups.where(status: "ready_for_print").all_of({:'documents.document_name' => params[:searchTerm]}).map{|grp| grp.attributes.merge(documents: grp.documents.where(document_name: params[:searchTerm]),total_cost: group_total(g),user_email: grp.user.email,note_text_present: grp.user.note.try(:note_text).present?)}

					when "search_with_OTP"
					 	groups=@current_company.groups.where(status: "ready_for_print").where(otp: params[:searchTerm] )
						groups=groups.map{|g| g.attributes.merge(user_email: g.user.email,total_cost: group_total(g))}if groups.present?
					when "search_with_phone_number"
						user = User.find_by(phone_number: params[:searchTerm])
						groups = user.groups.where(status: "ready_for_print", company_id: @current_company.id).map{|g| g.attributes.merge(user_email: g.user.email,total_cost: group_total(g),note_text_present: g.user.note.try(:note_text).present?, phone_number: g.user.phone_number) } if user.present?
					else
						return groups
			end

			render status: "200", json: {
				groups: groups,
				message: "Success"
			}
		rescue Exception => e
			generate_error_response("500",e)
		end
	end
	def search_in_user_list
		begin
			groups=""
			user = User.find_by(email: params[:searchTerm])
			email, phone_number = ""
			if user.present?
				email = params[:searchTerm]
			else
				user = User.find_by(phone_number: params[:searchTerm]) if !user.present?
				phone_number = params[:searchTerm]
			end
			note_text = user.note.try(:note_text).present?
			groups = @current_company.groups.where(:user_id => user.id, :status => 'ready_for_payment').map{|g| g.attributes.merge(user_email: g.user.email, phone_number: g.user.phone_number, note_text_present: g.user.note.try(:note_text).present?)} if user.present?

			render status: "200", json: {
				groups: groups,
				user_email: email,
				phone_number: phone_number,
				note_text: note_text,
				message: "Success"
			}
		rescue Exception => e
			generate_error_response("500",e)
		end
	end

    private
      	def generate_error_response(code,message)
            render status: code, json: {
            	message: message
            }
      	end
    end
