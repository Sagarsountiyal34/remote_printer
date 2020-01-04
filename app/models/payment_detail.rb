class PaymentDetail
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :group

  field :amount,   type: Float, default: ""
  field :transaction_id, type: String
  field :payment_mode, type: String
  field :currency, type: String
  field :status, type: String
  field :response_code, type: Integer
  field :response_message, type: String
  field :gateway_name, type: String
  field :bank_tx_id, type: Integer
  field :bank_name, type: String
  field :final_amount, type: Float
  field :discount, type: Float
end
