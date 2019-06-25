class Group

  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  embeds_many :documents, class_name: "GroupDocument"


  field :status, type: String, default: "pending"
  validates :status, inclusion: { in: ['ready_for_payment', 'ready_for_print','sent_for_printing', 'processing', 'failed', 'completed'] }
  def get_total_group_item
    total_item = ''
    if self.documents.present?
      total_item = self.documents.length
    end
    return total_item
  end

  # removing from group documents
  def remove_document(document_ids)
      self.documents.where(:id.in => document_ids).destroy
      if self.documents.length == 0
        self.destroy
      end
  end

  def add_documents(document_ids)
    documents = user.upload_documents.where(:_id.in => document_ids)
    documents.each do |document|
      document.add_documents(self)
    end
  end

  def get_documents_for_api(request,status)
    documents_array = []
    self.documents.all.each do |document|
      if document.status == status
        document_hash = {}
        document_hash['id'] = document.upload_document_id.to_s
        document_hash['path'] = request.base_url + document.document_url
        document_hash['name'] = document.document_name
        document.status = 'sent_for_printing'
        document.save
        document_hash['status'] = document.status
        documents_array << document_hash
      end
    end
    self.status = 'sent_for_printing' if documents_array.present?
    self.save
    return documents_array
  end

  def get_hash
    json.group @artists do |group|
      json.id group.id
      json.name group.status
    end
  end



end
