require 'fileutils'
require Rails.root.join("lib", "log_parser.rb")
class AdhearsionLogsController < ApplicationController

  def create
  end

  def parse
    @ahn_log = AdhearsionLog.new
    file = File.new(Rails.root.join('public', 'uploads', "log#{AdhearsionLog.count + 1}.log"), 'w')
    if params[:log_file]
      uploaded_file = File.open(params[:log_file].path)
      FileUtils.cp(uploaded_file, file)
    elsif params[:pasted_text]
      params[:pasted_text].each do |line|
        file.write line + "\n"
      end
    else
      render text: "Error! No Log File submitted!"
      redirect_to :create
    end
    @ahn_log[:log_url] = Rails.root.join 'public', 'uploads', "log#{AdhearsionLog.count + 1}.log"
    LogParser.new(File.open(@ahn_log.log_url, 'r'), @ahn_log).run
    @ahn_log.save
    render "view"
  end
end
