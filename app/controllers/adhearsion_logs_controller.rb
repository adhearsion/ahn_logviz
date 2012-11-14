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
    @ahn_log = AdhearsionLog.new
    logfile = File.new(Rails.root.join("public", "uploads", "#{@ahn_log.id}.log"), 'w')
    if params[:log_file]
      logfile.write IO.read(params[:log_file].path)
      @ahn_log[:log] = (IO.read params[:log_file].path).split("\n")
      @ahn_log.save
    elsif !params[:pasted_text][0].empty?
      @ahn_log[:log] = []
      params[:pasted_text].each do |text|
        logfile.write text
        @ahn_log[:log] += text.split("\n")
      end
      @ahn_log.save
    end

    logfile.close
    LogParser.new(File.open(Rails.root.join("public", "uploads", "#{@ahn_log.id}.log"), 'r'), @ahn_log).run
    @ahn_log[:log_url] = "/adhearsion_logs/view_text_log/#{@ahn_log.id}"
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
    @ahn_log[:log].each do |line|
      logfile.write "#{line}\n"
    end
    logfile.close
    redirect_to "/uploads/#{params[:id]}.log"
  end
end
