class Note
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  embeds_many :pending_payments, class_name: "PendingPayment", cascade_callbacks: true

  field :note_text, type: String, default: ""

end
