class Group

  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :user
  # has_many :upload_documents

  # embeds_many :upload_documents

  field :status, type: String, default: "pending"
  field :document_ids, type: Array, default: []

  def get_total_cart_item
    total_item = ''
    if self.document_ids.present?
      total_item = self.document_ids.length
    end
    return total_item
  end

end
