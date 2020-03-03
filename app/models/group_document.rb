class GroupDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  include DocumentUploader::Attachment.new(:document)
  # Shrine.plugin :keep_files, destroyed: true
  embedded_in :group

  # belongs_to :upload_document

  field :document_name,           type: String, default: ""
  field :document_data,   		  type: Hash, default: {}
  field :status, 				  type: String, default: "pending"
  field :total_pages, type: Integer,default: 0
  field :upload_document_id, type: String
  field :processed_pages, type: Integer,default: 0
  field :active, type: Boolean, default: false
  field :is_approved, type: Boolean, default: false
  field :print_type, type: String, default: 'black_white'
  field :cost, type: Float

  # before_update :active_next_document

  validates :status, inclusion: { in: ['pending','interrupted','sent_for_printing', 'processing', 'failed', 'completed'] }
  before_save :calculate_cost
  validates :print_type, inclusion: { in: ['black_white', 'color'] }

  def calculate_cost
    setting  = group.company.printer_setting
    if setting.present?
      count  = total_pages
      self.cost =(print_type== "black_white"?(count*setting.bw_price):(count*setting.color_price))
    else
      self.cost = get_doc_cost
    end
  end
  def active_next_document
    if (status_changed? && status_was =="sent_for_printing" && (status =="completed_&_paid"||status =="completed_&_unpaid"||status=="interrupted") )
      next_doc_to_print = group.documents.where(status: "sent_for_printing").where(id!= self.id).first
      next_doc_to_print.update(active:true) if next_doc_to_print.present?
    end
  end

  def create_note_entry
    doc_user =  self.group.user
    doc_user.create_note(note_text: "") if  doc_user.note.blank?

    # check if this document has note already
    pending_payments = doc_user.note.pending_payments
    doc_note_entry = pending_payments.find_by(document_id: self.id.to_s)

    if self.status =="completed_&_unpaid"
        if doc_note_entry.blank?
          doc_user.note.pending_payments.create(document_id: self.id.to_s,document_name: self.document_name,printed_time: Time.now())
        end
    elsif self.status =="completed_&_paid"
         doc_note_entry.delete if doc_note_entry.present?
    end
 end

  def get_preview_url
    self.document_url
  end

  def get_absolute_preview_path
    Rails.root.to_s + '/public' + self.get_preview_url
  end

  def is_document_deleted?
    !File.exist?(self.get_absolute_preview_path)
  end

  def get_total_pages
    self.total_pages
  end

  def get_doc_cost
    if FileInfo.get_file_media_type(self.document_url) == 'PDF'
      if self.print_type == 'black_white'
        return 1 * total_pages
      else
        return 10 * total_pages
      end
    else
      if self.print_type == 'black_white'
        return 5
      else
        return 10
      end
    end
  end
end
