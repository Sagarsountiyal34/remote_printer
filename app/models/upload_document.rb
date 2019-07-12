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

  def get_preview_url
    src_path = self.get_absolute_path
    file_name = File.basename(src_path)
    ext = FileInfo.get_file_type(src_path)
    if ext == 'doc' or ext == 'docx' or ext == 'odt'
      File.join('/uploads/preview', file_name).sub(ext, 'pdf')
    else
      File.join('/uploads/preview', file_name)
    end
  end

  def get_cloned_file_absolute_path(group_otp)
    file_src = self.get_absolute_path
    ext = File.extname(file_src)
    file_src.sub(ext, '_' + group_otp + ext)
  end

  def get_cloned_pdf_file_absolute_path(group_otp)
    file_src = self.get_absolute_path
    ext = File.extname(file_src)
    file_src.sub(ext, '_' + group_otp + '.pdf')
  end

  def add_documents(group)
      cloned_document_data = self.document_data
      file_name = cloned_document_data['metadata']["filename"]
      ext = File.extname(file_name)
      if FileInfo.is_image?(self.document_url)
          cloned_document_data['metadata']['filename'] = file_name.sub(ext, '.jpg')
          cloned_document_data['metadata']['size'] = File.size(self.get_cloned_file_absolute_path(group.otp))
          cloned_document_data['id'] = File.basename(self.get_cloned_file_absolute_path(group.otp))
      else
          cloned_document_data['metadata']['mime_type'] = "application/pdf"
          cloned_document_data['metadata']['filename'] = file_name.sub(ext, '.pdf')
          cloned_document_data['metadata']['size'] = File.size(self.get_cloned_pdf_file_absolute_path(group.otp))
          cloned_document_data['id'] = File.basename(self.get_cloned_pdf_file_absolute_path(group.otp))
      end
      group_document = GroupDocument.new(document_name: self.document_name, upload_document_id: self.id, document_data: cloned_document_data, status: 'pending')
      group.documents << group_document
  end

  def insert_otp_into_document(otp)
    ext = FileInfo.get_file_type(self.document_url)
    if ext == 'jpg'
      add_otp_for_image(otp)
    else
      add_otp_for_pdf(otp)
    end
  end

  def add_otp_for_pdf(group_otp)
    pdf_src = self.get_cloned_pdf_file_absolute_path(group_otp)
    otp_pdf_path = Rails.root.to_s + '/public/uploads/tmp/' + rand(1000..9999).to_s + '.pdf'
    OtpGenerator.as_pdf(otp_pdf_path,group_otp)
    otp_pdf = CombinePDF.load(otp_pdf_path) # otp pdf generated for temp
    pdf = CombinePDF.load(pdf_src)
    pdf.pages.first  << otp_pdf.pages[0] # notice the << operator is on a page and not a PDF object.
    pdf.pages.last << otp_pdf.pages[0]
    pdf.save pdf_src
  end

  def add_otp_for_image(group_otp)
      img_src = self.get_cloned_file_absolute_path(group_otp)
      img = ImageList.new(img_src)
      txt = Draw.new
      img.annotate(txt, 0,0,45,0, group_otp){
        txt.gravity = Magick::SouthEastGravity
        txt.pointsize = 40
        txt.fill = '#56a8d8'
        txt.font_weight = Magick::BoldWeight
      }
      img.format = 'jpg'
      img.write img_src
  end

  def have_to_create_pdf_from_file?
    ext = FileInfo.get_file_type(self.document_url)
    if ext == 'doc' or ext == 'docx' or ext == 'odt'
      return true
    else
      return false
    end
  end

  def create_pdf_from_file(group_otp)
    docx_src = self.get_cloned_file_absolute_path(group_otp)
    ext = File.extname(docx_src)
    pdf_src = docx_src.sub(ext,'.pdf')
    Libreconv.convert(docx_src, pdf_src)
    File.delete(docx_src) if File.exist?(docx_src)
  end

  def generate_deep_copy_in_directory(group_otp)
    src_path = self.get_absolute_path
    ext = File.extname(src_path)
    dest_src = src_path.sub(ext, '_' + group_otp + ext)
    FileUtils.cp(src_path, dest_src)
  end

  def generate_preview_file
    src_path = self.get_absolute_path
    file_name = File.basename(self.document_url)
    ext = FileInfo.get_file_type(src_path)

    if ext == 'doc' or ext == 'docx' or ext == 'odt'
      dest_src = File.join(Rails.root, 'public/uploads/preview', file_name).sub(ext, 'pdf')
      Libreconv.convert(src_path, dest_src)
    else #for image only copy in preview folder
      dest_src = File.join(Rails.root, 'public/uploads/preview', file_name)
      FileUtils.cp(src_path, dest_src)
    end
  end
end