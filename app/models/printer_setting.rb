class PrinterSetting
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :company

  field :color_printer, type: String, default: ""
  field :bw_printer, type: String, default: ""
  field :bw_price, type: Float, default: 1
  field :color_price, type: Float, default: 1

end
