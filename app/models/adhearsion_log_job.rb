class AdhearsionLogJob < Struct.new(:options)

  def perform
    ahn_log = AdhearsionLog.find options[:ahn_log_id]
    file = File.open Rails.root.join("public", "uploads", "#{options[:ahn_log_id]}.log", 'w'
    file.write(IO.read(options[:file])) if options[:write_file]
    file.close
    ahn_log[:log] = IO.read(Rails.root.join("public", "uploads", "#{options[:ahn_log_id]}.log")).split "\n"
    ahn_log.parse(file.path)
    ahn_log.save
  end

end