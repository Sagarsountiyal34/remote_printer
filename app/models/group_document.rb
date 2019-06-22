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

  def is_document_added_to_group?
  	flag = false
  	if user.group.present? and user.group.document_ids.include?(self.id.to_s)
  		flag = true
  	end
  	return flag
  end

end
