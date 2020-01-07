class Company
  include Mongoid::Document
  include Mongoid::Timestamps

  field :email, type: String
  field :password, type: String, default: ""
  
  has_many :groups, dependent: :destroy

end
