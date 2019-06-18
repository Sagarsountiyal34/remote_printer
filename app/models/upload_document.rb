class UploadDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  include DocumentUploader::Attachment.new(:document)

  belongs_to :user

  field :document_name,           type: String, default: ""
  field :document_data,   		  type: String, default: ""
  field :status, 				  type: String, default: "pending"

  validates :document_data,       presence: true
end
