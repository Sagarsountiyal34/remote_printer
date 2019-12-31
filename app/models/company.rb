class Company
  include Mongoid::Document
  include Mongoid::Timestamps

  field :company_name, type: String
  field :password, type: String, default: ""
  
  has_many :groups, dependent: :destroy

end
