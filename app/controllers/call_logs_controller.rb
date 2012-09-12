class CallLogsController < ApplicationController
  def view
    @call_log = CallLog.find(params[:id])
  end
end
