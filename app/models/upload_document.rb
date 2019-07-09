include Magick

class UploadDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  include DocumentUploader::Attachment.new(:document)

  belongs_to :user
  field :document_name,           type: String, default: ""
  field :document_data,   		  type: String, default: ""
  field :total_pages, type: Integer,default: 0
  field :processed_pages, type: Integer,default: 0

  validates :document_data,       presence: true

  def get_document_by_ids(document_ids)
    return self.where(:_id.in => document_ids)
  end

  def add_documents(group)
      group_document = GroupDocument.new(document_name: self.document_name, upload_document_id: self.id, document_data: self.document_data, status: 'pending')
      group.documents << group_document
      group.save
  end

  def insert_otp_into_document(otp)
    ext = File.extname(self.document_url)
    if ext == '.odt' or ext == '.docx' or ext == '.doc'
      add_otp_for_docx_and_odt(otp)
    elsif ext == '.pdf'
      add_otp_for_pdf(otp)
    else ext == '.jpg'
      add_otp_for_image(otp)
    end
  end

  def add_otp_for_docx_and_odt(otp)
    docx_src = Rails.root.to_s + '/public' + self.document_url
    pdf_output_src = Rails.root.to_s + '/public/uploads/tmp/' + rand(1000..9999).to_s + '.pdf'
    Libreconv.convert(docx_src, pdf_output_src)
    otp_pdf_path = Rails.root.to_s + '/public/uploads/tmp/' + rand(1000..9999).to_s + '.pdf'
    OtpGenerator.as_pdf(otp_pdf_path,otp)
    otp_pdf = CombinePDF.load(otp_pdf_path) # otp pdf generated for temp
    content_pdf = CombinePDF.load(pdf_output_src)
    content_pdf.pages.first  << otp_pdf.pages[0] # notice the << operator is on a page and not a PDF object.
    content_pdf.pages.last << otp_pdf.pages[0]
    content_pdf.save pdf_output_src
    Libreconv.convert(pdf_output_src, docx_src)
  end

  def add_otp_for_pdf(otp)
    pdf_src = Rails.root.to_s + '/public' + self.document_url
    otp_pdf_path = Rails.root.to_s + '/public/uploads/tmp/' + rand(1000..9999).to_s + '.pdf'
    OtpGenerator.as_pdf(otp_pdf_path,otp)
    otp_pdf = CombinePDF.load(otp_pdf_path) # otp pdf generated for temp
    pdf = CombinePDF.load(pdf_src)
    pdf.pages.first  << otp_pdf.pages[0] # notice the << operator is on a page and not a PDF object.
    pdf.pages.last << otp_pdf.pages[0]
    pdf.save pdf_src
  end

  def add_otp_for_image(otp)
      img_src = Rails.root.to_s + '/public' + self.document_url
      img = ImageList.new(img_src)
      txt = Draw.new
      img.annotate(txt, 0,0,45,0, otp){
        txt.gravity = Magick::SouthEastGravity
        txt.pointsize = 40
        txt.fill = '#56a8d8'
        txt.font_weight = Magick::BoldWeight
      }
      img.format = 'jpg'
      img.write img_src
  end
end