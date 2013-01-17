class AdhearsionLogsController < ApplicationController

  def index
    @ahn_logs = AdhearsionLog.all
  end

  def upload
  end

  def create
    name = params[:name] == "" ? nil : params[:name]
    @ahn_log = AdhearsionLog.create name: name
  end

  def view
    @ahn_log = AdhearsionLog.find params[:id]
    @master_calls = @ahn_log.calls.where is_master: true
  end

end
