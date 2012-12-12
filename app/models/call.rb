class Call < ActiveRecord::Base
  attr_accessor :ahn_call_id, :call_name
  belongs_to :call_log
end
