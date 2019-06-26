class GroupDocument
  include Mongoid::Document
  include Mongoid::Timestamps

  include DocumentUploader::Attachment.new(:document)

  embedded_in :group
  
  belongs_to :upload_document

  field :document_name,           type: String, default: ""
  field :document_data,   		  type: String, default: ""
  field :status, 				  type: String, default: "pending"
  field :total_pages, type: Integer,default: 0
  field :processed_pages, type: Integer,default: 0

  validates :status, inclusion: { in: ['ready_for_payment','sent_for_printing', 'ready_for_print','processing','failed', 'completed'] }


  def get_file_type
    File.extname(self.document_url).split('.')[1]
  end

  def get_path_with_server_url(server_url)
    return server_url + self.document_url
  end

end
