require 'uuidtools'
class Call < Sequel::Model
  many_to_one :adhearsion_log
  one_to_many :call_events

  def before_create
    self.id = UUIDTools::UUID.random_create
    super
  end
end