class FileInfo
  def self.get_file_type(file_path)
    File.extname(file_path).split('.')[1]
  end
  def self.is_image?(file_path)
    File.extname(file_path) == '.jpg'
  end

  def self.is_pdf?(file_path)
    File.extname(file_path) == '.pdf'
  end
end