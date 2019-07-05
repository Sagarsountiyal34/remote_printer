class Group

  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  embeds_many :documents, class_name: "GroupDocument", cascade_callbacks: true

  field :status, type: String, default: "ready_for_payment"
  validates :status, inclusion: { in: ['ready_for_payment', 'ready_for_print','sent_for_printing', 'processing', 'failed', 'completed'] }

  after_save :remove_group_if_needed

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

  def get_documents_for_api(request)
    documents_array = []
    self.documents.each do |document|
        document_hash = {}
        document_hash['id'] = document.id.to_s
        document_hash['name'] = document.document_name
        document_hash['path'] = request.base_url + document.document_url
        documents_array << document_hash
    end
    return documents_array
  end

  def is_progress_group?
    ['sent_for_printing', 'processing'].include?(self.status)
  end

  def is_completed_group?
    self.status == 'completed'
  end

  def is_failed_group?
    self.status == 'failed'
  end

  def is_group_sent_for_printing?
    ['sent_for_printing', 'processing','failed', 'completed'].include?(self.status)
  end

end
