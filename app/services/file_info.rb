class FileInfo
  FILE_TYPES_PATH = File.join(Rails.root, 'config', 'file_media_types.yml')
  FILE_TYPES_HASH = File.exist?(FILE_TYPES_PATH) ? YAML.load(IO.read(FILE_TYPES_PATH)) : { }

  def self.get_file_extension(path_or_extension)
    extension = path_or_extension.gsub(/^.*\./, '').downcase
  end

  def self.is_image?(path_or_extension)
    ext = path_or_extension.gsub(/^.*\./, '').downcase
    get_type(ext) == "image"
  end

  def self.is_document?(file_path)
    ext = path_or_extension.gsub(/^.*\./, '').downcase
    get_type(ext) == "document"
  end

  def self.get_file_media_type(path_or_extension)
    extension = path_or_extension.gsub(/^.*\./, '').downcase
    get_type(extension)
  end

  protected
  def self.get_type(extension)
    media_type = "external"
    if extension.present?
      FILE_TYPES_HASH.each do |key, values|
        types_array = values.gsub(" ", "").split(",")
        if types_array.include?(extension)
          media_type = key
          break
        end
      end
    end
    return media_type
  end
end