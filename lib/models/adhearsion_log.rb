require 'uuidtools'
class AdhearsionLog < Sequel::Model
  plugin :timestamps, update_on_create: true
  one_to_many :calls

  def before_create
    self.id = UUIDTools::UUID.random_create
    super
  end
end