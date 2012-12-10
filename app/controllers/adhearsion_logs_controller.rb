require 'fileutils'
require Rails.root.join("lib", "log_parser.rb")
class AdhearsionLogsController < ApplicationController


  def bad_log
    flash[:notice] = "Upload a real log next time. Tip: TRACE logs are the only kind that work here."
    redirect_to "/"
  end

  def create
  end

  def parse
    @ahn_log = AdhearsionLog.new :log => []
    @ahn_log.save
    if params[:log_file]
      Delayed::Job.enqueue AdhearsionLogJob.new(ahn_log_id: @ahn_log.id, file: params[:log_file].path, write_file: true)
    elsif !params[:pasted_text][0].empty?
      logfile = File.new(Rails.root.join("public", "uploads", "#{@ahn_log.id}.log"), 'w')
      params[:pasted_text].each do |text| 
        logfile.write text
      end
      Delayed::Job.enqueue AdhearsionLogJob.new(ahn_log_id: @ahn_log.id, file: logfile, write_file: false)
      logfile.close
    end
    @ahn_log.save
    @ahn_log[:log_url] = "/adhearsion_logs/view_text_log/#{@ahn_log.id}"
    @ahn_log.save
    if @ahn_log.call_logs
      redirect_to "/adhearsion_logs/processing_log/#{@ahn_log.id}"
    else
      flash[:notice] = "Upload a real log next time. Tip: TRACE logs are the only kind that work here."
      redirect_to "/"
    end
  end

  def processing_log
    @ahn_log = AdhearsionLog.find params[:id]
  end

  def view_text_log
    @ahn_log = AdhearsionLog.find params[:id]
    logfile = File.new(Rails.root.join("public", "uploads", "#{params[:id]}.log"), 'w')
    @ahn_log[:log].each do |line|
      logfile.write "#{line}\n"
    end
    logfile.close
    redirect_to "/uploads/#{params[:id]}.log"
  end
end
