require 'sinatra'
require 'sinatra/sequel'
require 'haml'
require File.dirname(__FILE__) + '/lib/logviz.rb'

set :database, 'sqlite::memory'

require File.dirname(__FILE__) + "/lib/migrations.rb"
Dir[File.dirname(__FILE__) + "/lib/models/*.rb"].each {|f| require f}

helpers do
  include LogViz::Helpers
end

get '/' do
  @logs = AdhearsionLog.all
  haml :index
end

get '/upload' do
  haml :upload
end

get '/view' do
  @ahn_log = AdhearsionLog.first id: params[:id]
  @calls = Call.where(adhearsion_log: @ahn_log, is_master: true)
  haml :view
end

get '/view_call' do
  call_view_data Call.first(id: params[:id])
  @events_array.each do |event|
    event.map! {|e| e.nil? ? 'null' : e }
  end
  haml :view_call
end

post '/create' do
  create_log params
  redirect '/'
end