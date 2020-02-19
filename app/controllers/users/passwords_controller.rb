# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # GET /resource/password/new
  def new
    super
  end

  # POST /resource/password
  def create
    @resource = resource_class.where(:email => resource_params[:login]).first
    @resource = resource_class.where(:phone_number => resource_params[:login]).first if !@resource.present?
    if @resource
      @resource.send_reset_password_instructions_email_sms(edit_user_password_url)
      errors = @resource.errors
      # errors.empty? ? head(:no_content) : render_create_error(errors)
      flash[:notice] = "Password reset instruction has been sent to #{@resource.email.present? ? "Email" : "Phone number"}"
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      head(:not_found)
      flash[:alert] = "Please try again."
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
