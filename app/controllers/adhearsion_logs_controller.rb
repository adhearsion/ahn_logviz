require 'fileutils'
require Rails.root.join("lib", "log_parser.rb")
class AdhearsionLogsController < ApplicationController

  def create
  end

  def parse
    @ahn_log = AdhearsionLog.new
    uploaded_file = File.open(params[:log_file].path)
    file = File.new(Rails.root.join('public', 'uploads', "log#{AdhearsionLog.count + 1}.log"), 'w')
    FileUtils.cp(uploaded_file, file)
    @ahn_log[:log_url] = Rails.root.join 'public', 'uploads', "log#{AdhearsionLog.count + 1}.log"
    LogParser.new(uploaded_file, @ahn_log).run
    @ahn_log.save
    render "view"
  end
end
