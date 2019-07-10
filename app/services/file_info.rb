class FileInfo
  def self.get_file_type(file_path)
    File.extname(file_path).split('.')[1]
  end
end