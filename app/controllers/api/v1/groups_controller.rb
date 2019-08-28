module Api
	module V1
		class GroupsController < ApplicationController
			include ActionController::ImplicitRender
			protect_from_forgery with: :null_session

      def get_groups_wd_status
        begin
          groups_status= params["GStatus"]
          if groups_status=="all"
            groups = Group.all
          else
            groups= get_groups(groups_status)
          end
					render status: "200", json: {
						groups: groups,
						message: "Success"
					}
				rescue Exception => e
					forbidden_error(e)
				end
      end

      def get_groups(groups_status)
        return Group.all.where("document.status"== groups_status).map{|grp| grp.attributes.merge(documents: grp.documents.where(status: groups_status))}
      end
    end
  end
end
