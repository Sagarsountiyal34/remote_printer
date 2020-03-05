class PdfService
	def self.replace_pdf_with_selected_page(pdf_path, page_arr)
		new_pdf = CombinePDF.new
		i = 1
		CombinePDF.load(pdf_path).pages.each do |page|
			new_pdf << page if page_arr.include?i.to_s
			i = i + 1
		end
		new_pdf.save pdf_path
	end
end