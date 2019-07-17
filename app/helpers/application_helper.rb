module ApplicationHelper
  def get_file_type(file)
  	FileInfo.get_file_media_type(file.document_url)
  end

  def have_to_show_iframe(file)
  	if FileInfo.get_file_media_type(file.get_preview_url) == 'image'
  		return false
  	else
  		return true
  	end
  end
end
