class AdhearsionLog < ActiveRecord::Base
  attr_accessible :log, :name, :start_time
  has_many :calls
end
