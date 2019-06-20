class UploadDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  include DocumentUploader::Attachment.new(:document)

  belongs_to :user

  field :document_name,           type: String, default: ""
  field :document_data,   		  type: String, default: ""
  field :status, 				  type: String, default: "pending"
  field :total_pages, type: Integer,default: 0
  field :processed_pages, type: Integer,default: 0

  validates :document_data,       presence: true

  validates :status, inclusion: { in: ['pending', 'ready_for_payment'] }
  def is_document_added_to_group?
  	flag = false
  	if user.group.present? and user.group.document_ids.include?(self.id.to_s)
  		flag = true
  	end
  	return flag
  end
end
