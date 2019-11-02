class Group

  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  embeds_many :documents, class_name: "GroupDocument", cascade_callbacks: true

  field :status, type: String, default: "ready_for_payment"
  field :payment_type, type: String, default: "pending"
  field :otp, type: String, default: ""
  field :submitted_time, type: DateTime, default: ""
  validates :status, inclusion: { in: ['ready_for_payment', 'ready_for_print','sent_for_printing', 'processing', 'failed', 'completed'] }
  validates :payment_type, inclusion: { in: ['pending', 'online', 'cash'] }

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
      next if File.exist?(document.get_absolute_path) == false
      document.generate_deep_copy_in_directory(self.otp)
      if document.have_to_create_pdf_from_file?
          document.create_pdf_from_file(self.otp)
      end
      document.insert_otp_into_document(self.otp)
      document.add_documents(self) # addding into group
    end
  end

  def get_documents_for_api(request)
    detail_with_docx_hash = {}
    documents_array = []
    detail = {}

    self.documents.each do |document|
        document_hash = {}
        document_hash['id'] = document.id.to_s
        # document_hash['name'] = document.document_name
        document_hash['name'] = document.document_data["metadata"]["filename"]
        document_hash['path'] = request.base_url + document.document_url
        documents_array << document_hash
    end
    detail['user_id'] = self.user.email
    detail['otp'] = self.otp
    detail_with_docx_hash['details'] = detail
    detail_with_docx_hash['docx'] = documents_array
    return detail_with_docx_hash
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

  def generate_otp
    otp =  rand(10000000..99999999).to_s
    if Group.find_by(:otp => otp).present?
      generate_otp
    else
      return otp
    end
  end

  def self.any_online_payment_group_sent_for_printing?
    Group.where(payment_type: 'online').where(:status.in => ['sent_for_printing', 'processing','failed']).present?
  end

end
