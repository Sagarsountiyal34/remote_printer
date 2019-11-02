namespace :document do
	desc "Delete documents"
	task :delete_documents => [:environment] do
		UploadDocument.all.each do |doc|
			File.delete(doc.get_absolute_path) if (((Time.now) - doc.created_at) / 1.hours).round > 2 and File.exist?(doc.get_absolute_path)
			File.delete(doc.get_absolute_preview_url) if (((Time.now) - doc.created_at) / 1.hours).round > 2 and File.exist?(doc.get_absolute_preview_url)
		end
	end

	desc "Delete Group documents"
	task :delete_group_documents => [:environment] do
		groups = Group.all
	    groups.each do |group|
		    group.documents.each do |doc|
		        File.delete(doc.get_absolute_preview_path) if (((Time.now) - doc.created_at) / 1.hours).round > 2 and File.exist?(doc.get_absolute_preview_path)
		    end
	    end
	end
end
