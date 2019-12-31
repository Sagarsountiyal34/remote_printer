class AdminsController < ApplicationController
	# layout "admin_layout"

	before_action :authenticate_user!
	protect_from_forgery prepend: true

	def dashboard
		@users = User.not.where(role: 'admin').order_by(created_at: :desc)
	end

	def user_list
		users = User.not.where(role: 'admin').order_by(created_at: :desc)
		total_record = users.length
		if params[:search][:value].present?
			filter_users =	users.any_of({ :email => /.*#{params[:search][:value]}.*/ })
			filter_record = filter_users.length
		else
			filter_users = users
			page_number_index = params[:page_number].to_i
			if  page_number_index > 0
				offset_value = page_number_index * 10
				filter_users = users.order_by(created_at: :desc).limit(10).offset(offset_value).to_a
			else
				filter_users = users.order_by(created_at: :desc).to_a.first(10)
			end
			filter_record = users.length
		end
		user_arr = []
		filter_users.each do |u|
			user = {}
			user[:email] = u.email.present? ? u.email : u.phone_number
			if u.email.present?
				user[:otp] = u.confirmable_otp.present? ? u.confirmable_otp : ''
				user[:is_confirmed] = u.otp_confirmed ? 'yes' : 'no'
			else
				user[:otp] = u.phone_otp
				user[:is_confirmed] = 'NA'
			end
			user[:detail] = u.id
			user_arr.push(user)
		end
		respond_to do |f|
    		f.json {render :json => {
    			users: user_arr,
                draw: params['draw'].to_i,
                recordsTotal: total_record,
                recordsFiltered: filter_record,
    		}
    	}
		end
	end

end
