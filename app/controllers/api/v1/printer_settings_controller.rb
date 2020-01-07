module Api
	module V1
		class PrinterSettingsController < ApplicationApiController
			include ActionController::ImplicitRender
			protect_from_forgery with: :null_session

      def update_printer_setting
        begin
          admin = User.where(role: "admin").first
          if admin.printer_setting.nil?
            admin.create_printer_setting(params[:type]=> params[:name])
            render status: "200", json: {
              # users_emails: users_emails_with_groupCount,
              message: "Success"
            }
          else
            admin.printer_setting.update_attributes(params[:type]=> params[:name])
            render status: "200", json: {
              # users_emails: users_emails_with_groupCount,
              message: "Success"
            }
          end
				rescue Exception => e
					forbidden_error(e)
				end
        # admin = User.find_by(email: params[:email])


      end

      def get_current_printer_name
        begin

          admin = User.where(role: "admin").first
          colored = ""
          bw = ""
          if admin.printer_setting.present?
            colored = admin.printer_setting.color_printer
            bw = admin.printer_setting.bw_printer
          end
          render status: "200", json: {
            # users_emails: users_emails_with_groupCount,
            message: "Success",
            colored: colored,
            bw:bw
          }

        rescue Exception => e
          forbidden_error(e)
        end

      end


    end
  end
end
