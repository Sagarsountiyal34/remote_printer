class OtpGenerator
	def self.as_pdf(path,otp)
		Prawn::Document.generate(path) do
	        bounding_box [bounds.left, bounds.bottom + 25], :width  => bounds.width do
	            move_down(5)
	            text otp,:align => :right, :size => 10, :color => 'ccccd8'
	        end
    	end
	end
end