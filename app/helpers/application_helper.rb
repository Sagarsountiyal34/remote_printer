module ApplicationHelper
  def get_file_type(file)
    File.extname(file.document_url).split('.')[1]
  end

  def get_path_with_server_url(server_url,file)
    return server_url + file.document_url
  end
end
