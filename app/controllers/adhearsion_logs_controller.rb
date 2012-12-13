require 'fileutils'
require 'zlib'
require Rails.root.join("lib", "log_parser.rb")
class AdhearsionLogsController < ApplicationController


  def bad_log
    flash[:notice] = "Upload a real log next time. Tip: TRACE logs are the only kind that work here."
    redirect_to "/"
  end

  def create
  end

  def parse
    @ahn_log = AdhearsionLog.create 
    logfile = File.new(Rails.root.join("public", "uploads", "#{@ahn_log.id}.log"), 'w')
    if params[:log_file]
      FileUtils.cp params[:log_file].path, logfile.path
    elsif !params[:pasted_text][0].empty?
      params[:pasted_text].each do |text| 
        logfile.write text
      end
    end
    logfile.close
    @ahn_log.log = Zlib::Deflate.deflate IO.read(Rails.root.join("public", "uploads", "#{@ahn_log.id}.log"))
    LogParser.new(Rails.root.join("public","uploads","#{@ahn_log.id}.log"), @ahn_log).run
    @ahn_log.log_url = "/adhearsion_logs/view_text_log/#{@ahn_log.id}"
    @ahn_log.save
    if @ahn_log.call_logs
      render "view"
    else
      flash[:notice] = "Upload a real log next time. Tip: TRACE logs are the only kind that work here."
      redirect_to "/"
    end
  end

  def view_text_log
    @ahn_log = AdhearsionLog.find params[:id]
    logfile = File.new(Rails.root.join("public", "uploads", "#{params[:id]}.log"), 'w')
    logfile.write Zlib::Inflate.inflate(@ahn_log[:log])
    logfile.close
    redirect_to "/uploads/#{params[:id]}.log"
  end
end
