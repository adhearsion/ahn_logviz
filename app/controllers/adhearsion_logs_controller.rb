require 'fileutils'
require Rails.root.join("lib", "log_parser.rb")
class AdhearsionLogsController < ApplicationController

  rescue_from NoMethodError, :with => :bad_log

  def bad_log
    flash[:notice] = "Upload a real log next time. Tip: TRACE logs are the only kind that work here."
    redirect_to "/"
  end

  def create
  end

  def parse
    @ahn_log = AdhearsionLog.new
    file = File.new(Rails.root.join('public', 'uploads', "log#{AdhearsionLog.count + 1}.log"), 'w')
    if params[:log_file]
      uploaded_file = File.open(params[:log_file].path)
      FileUtils.cp(uploaded_file, file)
    elsif !params[:pasted_text][0].empty?
      params[:pasted_text].each do |text|
        file.write text.gsub("\r\n", "\n")
      end
    end
    @ahn_log[:log_url] = Rails.root.join 'public', 'uploads', "log#{AdhearsionLog.count + 1}.log"
    LogParser.new(File.open(@ahn_log.log_url, 'r'), @ahn_log).run
    @ahn_log.save
    if @ahn_log.call_logs
      render "view"
    else
      flash[:notice] = "Upload a real log next time. Tip: TRACE logs are the only kind that work here."
      redirect_to "/"
    end
  end
end
