require 'twilio-ruby'
class PhoneMessageSender
	def self.send_otp(phone_number, otp)
		begin
			get_twillio_client			
			message = @client.messages.create(
			    body: get_otp_message(otp),
			    to: "+91#{phone_number}",    # Replace with your phone number
			    from: "+12016858898")  # Use this Magic Number for creating SMS
			puts message.sid
			return true
		rescue Exception => e
			return true
		end
	end

	def self.send_password(user,password)
		begin
			get_twillio_client			
			message = @client.messages.create(
			    body: get_password_message(password),
			    to: "+91#{user.phone_number}",
			    from: "+12016858898")
			return true
		rescue Exception => e
			return false
		end
	end

	def self.send_password_instruction(user,password_reset_url, raw_token)
		begin
			get_twillio_client			
			message = @client.messages.create(
			    body: get_reset_password_message(password_reset_url, raw_token),
			    to: user.phone_number,
			    from: "+12016858898")
			return true
		rescue Exception => e
			return false
		end
	end
	def self.get_twillio_client
		account_sid = ENV['Twillio_account_id']
		auth_token = ENV['Twillio_auth_token']
		@client = Twilio::REST::Client.new account_sid, auth_token
	end

	def self.get_password_message(password)
		return "Your Account Password for Remote Printer is: #{password}"
	end

	def self.get_otp_message(otp)
		return "Your Remote Printer verification code is: #{otp}"
	end

	def self.get_reset_password_message(password_reset_url, raw_token)
		return "Your Remote Printer reset password url is: #{password_reset_url}?reset_password_token=#{raw_token}"
	end
end

