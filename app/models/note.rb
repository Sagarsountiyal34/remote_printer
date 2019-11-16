class Note
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  field :note_text, type: String, default: ""
end
