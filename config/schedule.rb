#set :environment, "development"
set :output, "log/cron.log"

every 2.days do
  # command "/usr/bin/some_great_command"
  # runner "MyModel.some_method"
  # rake "some:great:rake:task"
  rake "document:delete_documents"
  rake "document:delete_group_documents"
end



