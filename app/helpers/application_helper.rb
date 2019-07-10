module ApplicationHelper
  def get_file_type(file)
  	FileInfo.get_file_type(file.document_url)
  end
end
