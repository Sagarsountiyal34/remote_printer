class Group

  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :user
  # has_many :upload_documents

  # embeds_many :upload_documents

  field :status, type: String, default: "pending"
  field :document_ids, type: Array

end
