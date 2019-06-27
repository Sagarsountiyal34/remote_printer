class Group

  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  embeds_many :documents, class_name: "GroupDocument"

  field :status, type: String, default: "pending"
  validates :status, inclusion: { in: ['ready_for_payment', 'ready_for_print','sent_for_printing', 'processing', 'failed', 'completed'] }

  after_initialize :set_default_status
  after_save :remove_group_if_needed

  def set_default_status
    self.status = 'ready_for_payment' # note self.status = 'P' if self.status.nil? might be safer (per @frontendbeauty)
  end

  def remove_group_if_needed
    self.destroy if self.documents.present? == false
  end

  def get_total_group_item
    total_item = ''
    if self.documents.present?
      total_item = self.documents.length
    end
    return total_item
  end

  def add_documents(document_ids)
    uploaded_documents = user.upload_documents.where(:_id.in => document_ids)
    uploaded_documents.each do |document|
      document.add_documents(self)# Uploading Document Into group
    end
  end

end
