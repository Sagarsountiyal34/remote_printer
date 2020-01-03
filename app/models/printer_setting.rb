class PrinterSetting
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user

  field :color_printer, type: String, default: ""
  field :bw_printer, type: String, default: ""

end
