require 'open-uri'
require 'uri'
require 'fileutils'
require 'net/http'
require 'json'

module LogParseHelper
  def new_chart(data, filename)
    response = Net::HTTP.post_form URI.parse("http://www.websequencediagrams.com/index.php"), 'style' => 'modern-blue', 'message' => data
    image_url = "http://www.websequencediagrams.com/" + response.body.split("{img: \"")[1].split("\"")[0]
    file = File.open(Rails.root.join('public', 'assets', 'images', "#{filename}.png"), 'wb')
    file.write Net::HTTP.get(URI.parse(image_url))
    file.close
  end
end
