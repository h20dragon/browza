
require 'logging'

module Browza



  class BrowzaMgr
    attr_accessor :driverList


    def initialize
      @logger = Logging.logger(STDOUT)
      @logger.level = :debug
      @driverList = []
    end

    def clear
      @driverList=[]
    end

    def getBrowsers()
      @driverList
    end

    def add(device)

      if !device.is_a?(Hash)
        @driverList << { :is_sauce => false, :drv => device }
      else
        @driverList << device
      end

      @driverList.last
    end

    def set(id, prop, val)
      get(id)[prop] = val

    end

    def get(id)
      @driverList.each do |elt|
        if elt.has_key?(:id) && elt[:id] == id
          return elt
        end
      end

      nil
    end

    def getDriver(id=nil)

      if id.nil? && @driverList.length > 0
        return @driverList.first
      elsif @driverList.length > 0
        @driverList.each do |b|
          if b.has_key?(:id) && b[:id] == id
            return b[:drv]
          end
        end
      end

      nil
    end


    def setSauceStatus(id, status)
      @driverList.each do |b|
        if b.has_key?(:id) && b[:id]==id
          b[:status] = status
        end
      end
    end


    # Set innerWidth and innerHeight
    def setDimension(width = 1035, height = 768)

      begin
        @driverList.each do |b|
          target_size = Selenium::WebDriver::Dimension.new(width, height)
          b[:drv].manage.window.size = target_size
        end
      rescue => ex
        @logger.warn __FILE__ + (__LINE__).to_s + " #{ex.class}"
        @logger.warn "Error during processing: #{$!}"
        @logger.warn "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
      end
    end

    def maximize()
      begin
        @driverList.each do |b|
          target_size = Selenium::WebDriver::Dimension.new(width, height)
          b[:drv].manage.window.maximize
        end
      rescue => ex
        @logger.warn __FILE__ + (__LINE__).to_s + " #{ex.class}"
        @logger.warn "Error during processing: #{$!}"
        @logger.warn "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
      end

    end

  end



end
