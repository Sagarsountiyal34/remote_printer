class LoggerService
  def self.my_logger
    @@my_logger ||= Logger.new("#{Rails.root}/log/my.log")
  end

  def self.create_log(message)
    my_logger.info(message)
  end
end