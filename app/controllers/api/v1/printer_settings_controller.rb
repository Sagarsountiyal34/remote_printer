module Api
	module V1
		class PrinterSettingsController < ApplicationApiController
			include ActionController::ImplicitRender
			protect_from_forgery with: :null_session

      def update_printer_setting
        begin
          if @current_company.printer_setting.nil?
            @current_company.create_printer_setting(params[:type]=> params[:name])
            render status: "200", json: {
              # users_emails: users_emails_with_groupCount,
              message: "Success"
            }
          else
            @current_company.printer_setting.update_attributes(params[:type]=> params[:name])
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

			def update_printer_cost
				begin
					# @current_company = Company.last
					if @current_company.printer_setting.nil?
						@current_company.create_printer_setting(params[:cost_type]=> params[:cost])
						render status: "200", json: {
							# users_emails: users_emails_with_groupCount,
							message: "Success"
						}
					else
						@current_company.printer_setting.update_attributes(params[:cost_type]=> params[:cost])
						render status: "200", json: {
							# users_emails: users_emails_with_groupCount,
							message: "Success"
						}
					end
				rescue Exception => e
					forbidden_error(e)
				end
			end

      def get_current_printer_name
        begin

          colored = ""
          bw = ""
          if @current_company.printer_setting.present?
            colored = @current_company.printer_setting.color_printer
            bw = @current_company.printer_setting.bw_printer
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

			def get_current_printer_settings
				begin
					# @current_company = Company.last
					printer_setting = ""
          if @current_company.printer_setting.present?
            printer_setting= @current_company.printer_setting
          end
          render status: "200", json: {
            # users_emails: users_emails_with_groupCount,
            message: "Success",
            printer_setting: printer_setting
          }

        rescue Exception => e
          forbidden_error(e)
        end
			end


    end
  end
end
