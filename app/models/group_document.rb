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

  validates :status, inclusion: { in: ['pending', 'completed'] }

end
