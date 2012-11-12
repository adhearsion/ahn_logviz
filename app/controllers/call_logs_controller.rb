class CallLogsController < ApplicationController
  def view
    @call_log = CallLog.find(params[:id])
    @ahn_log = @call_log.adhearsion_log
  end
end
