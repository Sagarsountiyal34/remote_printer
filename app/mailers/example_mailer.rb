class ExampleMailer < ApplicationMailer
	default from: "ravikumar@codegaragetech.com"
	def sample_email(error)
		@error = error
    	mail(to: 'sagarsountiyal34@gmail.com', subject: 'Error Info')
	end

	def contact_us_email(email, message, subject, user_name)
		@email = email
		@message = message
		@name = user_name
		mail(from: email, subject: subject, to:'ravikumar@codegaragetech.com')
	end
end
