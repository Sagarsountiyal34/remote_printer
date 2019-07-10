include Magick

class UploadDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  include DocumentUploader::Attachment.new(:document)

  belongs_to :user
  field :document_name,           type: String, default: ""
  field :document_data,   		  type: Hash, default: {}
  field :total_pages, type: Integer,default: 0
  field :processed_pages, type: Integer,default: 0

  validates :document_data,       presence: true

  def get_document_by_ids(document_ids)
    return self.where(:_id.in => document_ids)
  end

  def get_absolute_path
      Rails.root.to_s + '/public' + self.document_url
  end

  def add_documents(group)
      group_document = GroupDocument.new(document_name: self.document_name, upload_document_id: self.id, document_data: self.document_data, status: 'pending')
      group.documents << group_document
      group.save
  end

  def insert_otp_into_document(otp)
    ext = FileInfo.get_file_type(self.document_url)
    if ext == 'pdf'
      add_otp_for_pdf(otp)
    else
      add_otp_for_image(otp)
    end
  end

  def add_otp_for_pdf(otp)
    pdf_src = self.get_absolute_path
    otp_pdf_path = Rails.root.to_s + '/public/uploads/tmp/' + rand(1000..9999).to_s + '.pdf'
    OtpGenerator.as_pdf(otp_pdf_path,otp)
    otp_pdf = CombinePDF.load(otp_pdf_path) # otp pdf generated for temp
    pdf = CombinePDF.load(pdf_src)
    pdf.pages.first  << otp_pdf.pages[0] # notice the << operator is on a page and not a PDF object.
    pdf.pages.last << otp_pdf.pages[0]
    pdf.save pdf_src
  end

  def add_otp_for_image(otp)
      img_src = self.get_absolute_path
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

  def have_to_convert_into_pdf?
    ext = FileInfo.get_file_type(self.document_url)
    if ext == 'doc' or ext == 'docx'
      return true
    else
      return false
    end
  end

  def convert_into_pdf
    docx_src = self.get_absolute_path
    ext=File.extname(self.document_url)
    pdf_src = docx_src.sub(ext,'.pdf')
    Libreconv.convert(docx_src, pdf_src)
  end

  def change_entry
    ext=File.extname(self.document_url)
    self.document_data['id'] = self.document_data['id'].sub(ext,'.pdf')
    self.document_data['metadata']['filename'] = self.document_data['metadata']['filename'].sub(ext,'.pdf')
    self.document_data['metadata']['mime_type'] = 'application/pdf'
    self.document_data['metadata']['size'] = File.size(self.get_absolute_path)
  end
end