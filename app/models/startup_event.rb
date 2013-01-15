class StartupEvent < ActiveRecord::Base
  attr_accessible :key, :value
  belongs_to :adhearsion_log
end
