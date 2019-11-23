include Magick

class UploadDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  include DocumentUploader::Attachment.new(:document)

  belongs_to :user
  field :document_name,           type: String, default: ""
  field :document_data,   		  type: Hash, default: {}
  field :total_pages, type: Integer,default: 1

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
    media_type = FileInfo.get_file_media_type(src_path)
    ext = FileInfo.get_file_extension(src_path)
    if media_type == 'office'
      File.join('/uploads/preview', file_name).sub(ext, 'pdf')
    else
      File.join('/uploads/preview', file_name)
    end
  end
  def get_absolute_preview_url
    Rails.root.to_s + '/public' +self.get_preview_url
  end

  def get_cloned_file_absolute_path(group_otp)
    file_src = self.get_absolute_path
    ext = File.extname(file_src)
    file_src.sub(ext, '_' + group_otp + ext)

    file_name = File.basename(file_src)
    ext = File.extname(file_src)

    file_name_without_ext = File.basename(file_name,ext)
    new_file_name_without_ext = file_name_without_ext+ '_' + group_otp
    new_file_name = new_file_name_without_ext + ext
    file_src.sub(file_name, new_file_name)

  end

  def get_cloned_pdf_file_absolute_path(group_otp)
    file_src = self.get_absolute_path

    file_name = File.basename(file_src)
    ext = File.extname(file_src)

    file_name_without_ext = File.basename(file_name,ext)
    new_file_name_without_ext = file_name_without_ext+ '_' + group_otp
    new_file_name = new_file_name_without_ext + ext
    file_src.sub(file_name, new_file_name)
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
      group_document = GroupDocument.new(document_name: self.document_name, upload_document_id: self.id, document_data: cloned_document_data, status: 'pending', total_pages: self.total_pages)
      group.documents << group_document
  end

  def insert_otp_into_document(otp)
    media_type = FileInfo.get_file_media_type(self.document_url)
    if media_type == 'image'
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
    media_type = FileInfo.get_file_media_type(self.document_url)
    if media_type == 'office'
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
    file_name = File.basename(src_path)
    ext = File.extname(src_path)

    file_name_without_ext = File.basename(file_name,ext)
    new_file_name_without_ext = file_name_without_ext+ '_' + group_otp
    new_file_name = new_file_name_without_ext + ext
    dest_src = src_path.sub(file_name, new_file_name)

    FileUtils.cp(src_path, dest_src)
  end

  def generate_preview_file
    src_path = self.get_absolute_path
    file_name = File.basename(self.document_url)
    media_type = FileInfo.get_file_media_type(src_path)
    ext = File.extname(src_path)
    if media_type == 'office'
      dest_src = File.join(Rails.root, 'public/uploads/preview', file_name).sub(ext, '.pdf')
      Libreconv.convert(src_path, dest_src)
    else #for image only copy in preview folder
      dest_src = File.join(Rails.root, 'public/uploads/preview', file_name)
      FileUtils.cp(src_path, dest_src)
    end
  end

  def is_document_deleted?
    !File.exist?(self.get_absolute_preview_url)
  end
end
