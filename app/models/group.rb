class Group

  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  embeds_many :documents, class_name: "GroupDocument"


  field :status, type: String, default: "pending"
  field :document_ids, type: Array, default: []
   validates :status, inclusion: { in: ['ready_for_payment', 'ready_for_print', 'progressing', 'failed', 'completed'] }
  def get_total_cart_item
    total_item = ''
    if self.documents.present?
      total_item = self.documents.length
    end
    return total_item
  end

end
