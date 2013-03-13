module LogViz
  class Config
    def initialize

    end

    def method_missing(key)
      @config[key]
    end
  end
end
