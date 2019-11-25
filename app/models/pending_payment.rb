class PendingPayment
  include Mongoid::Document
  include Mongoid::Timestamps
  # Shrine.plugin :keep_files, destroyed: true
  embedded_in :note

  # belongs_to :upload_document

  field :document_id, type: String
  field :document_name, type: String, default: ""
  field :printed_time, type: DateTime, default: ""


end
