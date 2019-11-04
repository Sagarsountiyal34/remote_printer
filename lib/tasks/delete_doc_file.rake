# namespace :document do
# 	desc "Delete documents"
# 	task :delete_documents => [:environment] do
# 		UploadDocument.all.each do |doc|
# 			if (((Time.now) - doc.created_at) / 1.days).round >= 2
# 				File.delete(doc.get_absolute_path) if File.exist?(doc.get_absolute_path)
# 				File.delete(doc.get_absolute_preview_url) if File.exist?(doc.get_absolute_preview_url)
# 				doc.destroy
# 			end
# 		end
# 	end

# 	desc "Delete Group documents"
# 	task :delete_group_documents => [:environment] do
# 		groups = Group.all
# 	    groups.each do |group|
# 		    group.documents.each do |doc|
# 		    	if (((Time.now) - doc.created_at) / 1.days).round >= 2
# 		        	File.delete(doc.get_absolute_preview_path) if File.exist?(doc.get_absolute_preview_path)
# 		        	doc.destroy
# 		        end
# 		    end
# 		    group.save
# 	    end
# 	end
# end


namespace :document do
	desc "Delete documents"
	task :delete_documents => [:environment] do
		UploadDocument.all.each do |doc|
			if doc.created_at.to_date == Time.now.to_date
				File.delete(doc.get_absolute_path) if File.exist?(doc.get_absolute_path)
				File.delete(doc.get_absolute_preview_url) if File.exist?(doc.get_absolute_preview_url)
				doc.destroy
			end
		end
	end

	desc "Delete Group documents"
	task :delete_group_documents => [:environment] do
		groups = Group.all
	    groups.each do |group|
		    group.documents.each do |doc|
		    	if doc.created_at.to_date == Time.now.to_date
		        	File.delete(doc.get_absolute_preview_path) if File.exist?(doc.get_absolute_preview_path)
		        	doc.destroy
		        end
		    end
		    group.save
	    end
	end
end
