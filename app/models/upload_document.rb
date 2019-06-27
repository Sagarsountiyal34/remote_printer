class UploadDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  include DocumentUploader::Attachment.new(:document)

  belongs_to :user
  field :document_name,           type: String, default: ""
  field :document_data,   		  type: String, default: ""
  field :total_pages, type: Integer,default: 0
  field :processed_pages, type: Integer,default: 0

  validates :document_data,       presence: true

  def get_document_by_ids(document_ids)
    return self.where(:_id.in => document_ids)
  end

  def add_documents(group)
      group_document = GroupDocument.new(document_name: self.document_name, upload_document_id: self.id, document_data: self.document_data, status: 'pending')
      group.documents << group_document
      group.save
  end
end