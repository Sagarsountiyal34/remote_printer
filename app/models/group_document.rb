class GroupDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  include DocumentUploader::Attachment.new(:document)
  # Shrine.plugin :keep_files, destroyed: true
  embedded_in :group

  belongs_to :upload_document

  field :document_name,           type: String, default: ""
  field :document_data,   		  type: Hash, default: {}
  field :status, 				  type: String, default: "pending"
  field :total_pages, type: Integer,default: 0
  field :processed_pages, type: Integer,default: 0
  field :active, type: Boolean,default: false


  validates :status, inclusion: { in: ['pending','sent_for_printing', 'processing', 'failed', 'completed'] }
  def get_preview_url
    self.document_url
  end

end
