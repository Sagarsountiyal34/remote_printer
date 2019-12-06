class GroupDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  include DocumentUploader::Attachment.new(:document)
  # Shrine.plugin :keep_files, destroyed: true
  embedded_in :group

  belongs_to :upload_document

  field :document_name,           type: String, default: ""
  field :document_data,   		  type: Hash, default: {}
  field :status, 				  type: String, default: "pending"
  field :total_pages, type: Integer,default: 0
  field :processed_pages, type: Integer,default: 0
  field :active, type: Boolean, default: false
  field :is_approved, type: Boolean, default: false


  validates :status, inclusion: { in: ['pending','sent_for_printing', 'processing', 'failed', 'completed_&_paid','completed_&_unpaid'] }
  after_save :create_note_entry

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

end
