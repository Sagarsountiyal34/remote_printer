class ExampleMailer < ApplicationMailer
	default from: "ashish@codegaragetech.com"

	def sample_email(error)
		@error = error
    	mail(to: 'sagarsountiyal34@gmail.com', subject: 'Error Info')
	end
end
