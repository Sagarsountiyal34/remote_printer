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
  	if user.group.present? and  user.group.documents.map { |doc| doc.upload_document_id}.include?(self.id)
  		flag = true
  	end
  	return flag
  end

  def get_document_by_ids(document_ids)
    return self.where(:_id.in => document_ids)
  end

  def add_documents(group)
      group_document = GroupDocument.new(document_name: self.document_name, upload_document_id: self.id, document_data: self.document_data, status: 'ready_for_payment')
      group.documents << group_document
      group.status = 'ready_for_payment'
      group.save
  end
end

