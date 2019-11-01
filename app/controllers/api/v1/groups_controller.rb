module Api
	module V1
		class GroupsController < ApplicationController
			include ActionController::ImplicitRender
			protect_from_forgery with: :null_session

      def get_groups_wd_status
        begin
          groups_status= params["GStatus"]
          if groups_status=="all"
            groups = Group.where(status: "ready_for_print").map{|g| g.attributes.merge(user_email: g.user.email)}
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

			def mark_all_as_printed
				begin
					group = Group.find(params["groupID"])
					if group.present?
						group.documents.update_all(status: "completed")
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

			def print_group_again
				begin
					group = Group.find(params["groupID"])
					if group.present?
						group.documents.update_all(status: "sent_for_printing")
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

      def get_groups(groups_status)
        return  Group.where(status: "ready_for_print").all_of({:'documents.status' => groups_status }).map{|grp| grp.attributes.merge(documents: grp.documents.where(status: groups_status),user_email: grp.user.email)}
      end
    end
  end
end
