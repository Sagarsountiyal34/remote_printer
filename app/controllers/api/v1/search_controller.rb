module Api
	module V1
		class SearchController < ApplicationController
			include ActionController::ImplicitRender
			protect_from_forgery with: :null_session

      def suggestions_for_user_email
        begin
          searchterm = params[:searchTerm]
          users_emails = []
          users = User.any_of({ :email => /.*#{searchterm}.*/i })
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
        	document_names= Group.collection.aggregate([{'$unwind': '$documents'},{'$match':{'documents.document_name': /.*#{searchterm}.*/i}},{'$project': {'documents.document_name': 1,'_id':0 }}]).to_a.map{|a| a["documents"]["document_name"]}
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
					groups = Group.any_of({ :otp => /.*#{searchterm}.*/i })
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
								groups = user.groups.all.map{|g| g.attributes.merge(user_email: g.user.email)} if user.present?
							when "search_with_doc_name"
								groups = Group.all_of({:'documents.document_name' => params[:searchTerm]}).map{|grp| grp.attributes.merge(documents: grp.documents.where(document_name: params[:searchTerm]),user_email: grp.user.email)}

							when "search_with_OTP"
							 	groups=Group.where(otp: params[:searchTerm] )
								groups=groups.map{|g| g.attributes.merge(user_email: g.user.email)}if groups.present?
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

      private
      def generate_error_response(code,message)
          render status: code, json: {
              message: message
          }
      end

    end
  end
end