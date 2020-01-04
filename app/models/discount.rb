class Discount
  include Mongoid::Document
  include Mongoid::Timestamps

  field :desc, type: String
  field :discount_value, type: String, default: ""
  field :status, type: Boolean
end
