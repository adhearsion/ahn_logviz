require 'fileutils'
include LogParseHelper
class AdhearsionLogsController < ApplicationController

  def create
    render :create
  end

  def process
    @ahn_log = AdhearsionLog.new
    uploaded_file = File.open(params[:log_file].path)
    file = File.new(Rails.root.join('public', 'uploads', "log#{AdhearsionLog.count + 1}.log"), 'w')
    FileUtils.cp(uploaded_file, file)
    @ahn_log[:log_url] = Rails.root.join 'public', 'uploads', "log#{AdhearsionLog.count + 1}.log"
    @ahn_log.save
    new_parser file, @ahn_log
    until file.eof? do
      new_call_log
      read_call
    end
    file.close
    render text: "Processing Complete!"
  end
end
