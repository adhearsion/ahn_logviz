module LogViz
  Dir[File.dirname(__FILE__) + '/logviz/*.rb'].each {|f| require f}
  Dir[File.dirname(__FILE__) + '/logviz/**/*.rb'].each {|f| require f}
end