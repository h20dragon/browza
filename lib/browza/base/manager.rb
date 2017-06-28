require 'selenium-webdriver'
require 'singleton'
require 'appmodel'
require 'logging'
require 'sauce_whisk'

module Browza

class Manager

  include Singleton

  attr_accessor :drv
  attr_accessor :appModels
  attr_accessor :browserType
  attr_accessor :defaultTimeout
  attr_accessor :driverList
  attr_accessor :browserMgr
  attr_accessor :debug

  def initialize(_logLevel = :warn)
    @debug = false
    @driverList = []
    @logger = Logging.logger(STDOUT)
    @logger.level = _logLevel
    @defaultTimeout = 30
    @appModels=[]
    @browserMgr = Browza::BrowzaMgr.new()
  end

  def _addDriver(d)
    @logger.debug __FILE__ + (__LINE__).to_s + " _addDriver(#{d})" if @debug
    @browserMgr.add(d)

    if !d.is_a?(Hash)
      @driverList << { :is_sauce => false, :drv => d }
    else
      @driverList << d
    end

    @driverList.last
  end

  def browserName
    @driverList[0][:drv].browser.to_s
  end

  def count
    @driverList.length
  end

  def setSauceStatus(id, status)
    rc = false
    @logger.debug __FILE__ + (__LINE__).to_s + " setSauceStatus(#{id}, #{status})" if @debug


    if (ENV['SELENIUM_RUN'] && ENV['SELENIUM_RUN'].match(/local/i)) || (ENV['SELENIUM_PLATFORM'] && ENV['SELENIUM_PLATFORM'].match(/local/i))
      @logger.debug __FILE__ + (__LINE__).to_s + " setSauceStatus() - ignored (running locally)"
      return nil
    end

    begin
      drv = @browserMgr.getDriver(id)

      unless drv.nil?
        job_id = drv.session_id
        SauceWhisk::Jobs.change_status job_id, status
        rc = true
      end

    rescue => ex
      @logger.fatal __FILE__ + (__LINE__).to_s + " #{ex.class}"
      @logger.fatal "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
    end

    rc
  end


  def connectSauce(id, _caps=nil)
    @logger.debug __FILE__ + (__LINE__).to_s + " connectSauce(#{id}, #{_caps})" if @debug
    runLocal = false

    if _caps.is_a?(String) && File.exist?(caps)
      caps = JSON.parse(File.read(caps), :symbolize_names => true)
    else
      caps = _caps.dup
    end

    if caps.has_key?('platform')
      tmpCaps = caps.clone


      if !ENV['SELENIUM_NAME'].nil? && (ENV['SELENIUM_NAME'].is_a?(String) && !ENV['SELENIUM_NAME'].empty?)
        tmpCaps['name'] = ENV['SELENIUM_NAME'].to_s
      elsif !tmpCaps.has_key?('name')
        tmpCaps['name'] = Time.now.strftime("%m%d%y_#{caps['browserType'].to_s}")
      end

      if caps['platform'].match(/\s*(linux|macOS|osx|os x|windows)/i)

        if caps.has_key?('browserType')
          browserType = caps['browserType']

          if browserType.match(/edge/i)
            caps = Selenium::WebDriver::Remote::Capabilities.edge()
          elsif browserType.match(/chrome/i)
            caps = Selenium::WebDriver::Remote::Capabilities.chrome()
          elsif browserType.match(/firefox/i)
            caps = Selenium::WebDriver::Remote::Capabilities.firefox()
          elsif browserType.match(/ie/i)
            caps = Selenium::WebDriver::Remote::Capabilities.internet_explorer()
          elsif browserType.match(/safari/)
            caps = Selenium::WebDriver::Remote::Capabilities.safari()
          else
            raise "Browza::UnexpectedBrowser::#{browserType}"
          end

        end
      else
        runLocal = true
        browserType = caps['browserType'] || ENV['SELENIUM_BROWSER'] || 'safari'
      end

      tmpCaps.each_pair do |k, v|
        caps[k.to_s] = v
      end

      @logger.debug __FILE__ + (__LINE__).to_s + " caps => #{caps}" if @debug

      begin

        if runLocal
          @drv=Selenium::WebDriver.for browserType.to_s.to_sym, :desired_capabilities => caps
        else
          sauce_endpoint = "http://#{ENV['SAUCE_USERNAME']}:#{ENV['SAUCE_ACCESS_KEY']}@ondemand.saucelabs.com:80/wd/hub"

          @drv=Selenium::WebDriver.for :remote, :url => sauce_endpoint, :desired_capabilities => caps
          # The following print to STDOUT is useful when running on JENKINS with SauceLabs plugin
          # Reference:
          #   https://wiki.saucelabs.com/display/DOCS/Setting+Up+Reporting+between+Sauce+Labs+and+Jenkins
          puts "SauceOnDemandSessionID=#{@drv.session_id} job-name=#{caps[:name]}"
        end

        _addDriver( { :id => id, :drv => @drv, :is_sauce => !runLocal })
      rescue => ex
        @logger.fatal __FILE__ + (__LINE__).to_s + " #{ex.class}"
        @logger.fatal "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
      end

      caps

    end

  end

  def setLogLevel(l)
    @logger.debug __FILE__ + (__LINE__).to_s + " setLogLevel(#{l})"
    @logger.level = l
  end

  def setTimeout(s)
    @defaultTimeout = s
  end

  def addModel(_a)
    @logger.debug __FILE__ + (__LINE__).to_s + " [addModel]: #{_a}" if @debug
    @appModels << Appmodel::Model.new(_a)
  end

  # Set innerWidth and innerHeight
  # Ref.: /selenium-webdriver/lib/selenium/webdriver/common/window.rb
  # o resize_to(width, height)
  #
  def setDimension(width = 1035, height = 768)
    @logger.debug __FILE__ + (__LINE__).to_s + " setDimension(#{width}, #{height})  count:#{@driverList.length}" if @debug
    begin
      i=0
      @driverList.each do |b|
        target_size = Selenium::WebDriver::Dimension.new(width.to_i, height.to_i)
        if b[:drv] && (b[:drv].is_a?(Selenium::WebDriver) || b[:drv].is_a?(Selenium::WebDriver::Driver))
          b[:drv].manage.window.size = target_size
        else
          @logger.warn __FILE__ + (__LINE__).to_s + " Attempt to access driver failed.  (#{b})"
        end

      end
    rescue => ex
      @logger.warn __FILE__ + (__LINE__).to_s + " browser[#{i}]: #{ex.class}"
      @logger.warn __FILE__ + (__LINE__).to_s + " Error during processing: #{$!}"
      @logger.warn " Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
    end
  end

  def maximize()
    getDriver().manage.window.maximize
  end

  def _getBrowserType(browserType)
    t = browserType

    if browserType.match(/chrome/i)
      t = :chrome
    elsif browserType.match(/firefox/i)
      t = :firefox
    elsif browserType.match(/ie/i)
      t = :ie
    elsif browserType.match(/edge/i)
      t = :edge
    end

    t
  end


  def start(*p)
    if (ENV['SELENIUM_RUN'] && ENV['SELENIUM_RUN'].match(/local/i)) || ENV['SELENIUM_PLATFORM'].match(/local/i)
      return createBrowser(p)
    else
      @logger.debug __FILE__ + (__LINE__).to_s + " connectSauce() => #{p}  #{p.class}  #{p.size}" if @debug

      if p.size == 0
        caps = {}
        caps['name']     = ENV['SELENIUM_NAME']
        caps['platform'] = ENV['SELENIUM_PLATFORM']
        caps['browserType'] = ENV['SELENIUM_BROWSER']
        caps['screenResolution'] = ENV['SELENIUM_RESOLUTION']
        caps['version'] = ENV['SELENIUM_VERSION']
        ENV['SELENIUM_RUN']='sauce'

        connectSauce(caps['name'], caps)
      end

    end
  end

  def createBrowser(*p)

    if ENV['SELENIUM_RESOLUTION']
      @logger.debug " SELENIUM_RESOLUTION=#{ENV['SELENIUM_RESOLUTION']}"  if @debug
      _width  = ENV['SELENIUM_RESOLUTION'].match(/\s*(\d+)\s*x\s*(\d+)\s*$/)[1].to_s
      _height = ENV['SELENIUM_RESOLUTION'].match(/\s*(\d+)\s*x\s*(\d+)\s*$/)[2].to_s
    else
      _width = 1035
      _height = 768
    end

    @logger.debug __FILE__ + (__LINE__).to_s + " createBrowser() : width x height : #{_width}, #{_height}" if @debug

    _id = Time.now.to_i.to_s

    @logger.debug __FILE__ + (__LINE__).to_s + " SELENIUM_BROWSER : #{ENV['SELENIUM_BROWSER']}"  if @debug
    @browserType = ENV['SELENIUM_BROWSER'] || 'chrome'
    @browserType = _getBrowserType(@browserType)

    if @debug
      @logger.debug __FILE__ + (__LINE__).to_s + " createBrowser(#{@browserType})   (isSymbol: #{@browserType.is_a?(Symbol)} : #{p.class.to_s}"
    end

    if p.is_a?(Array) && p.length > 0

      if @debug
        @logger.debug __FILE__ + (__LINE__).to_s + "  createBrowser() size: #{p.size}  p[0]=#{p[0]} p[0].class=#{p[0].class}  p[0].size=#{p[0].size} isSymbol(#{p[0].is_a?(Symbol)})"
      end

      if p.size == 1

        if p[0].is_a?(Array) && p[0].size==1 && ( p[0][0].is_a?(Symbol) || p[0][0].is_a?(String) )
          @browserType = p[0][0].to_s.to_sym
        elsif p[0].is_a?(Array) && p[0].size==1 && p[0][0].is_a?(Hash)
          @logger.debug __FILE__ + (__LINE__).to_s + " #{p[0]}"

          h = p[0][0]

          if h.has_key?(:browserType)
            @browserType = h[:browserType]
          end

          if h.has_key?(:width) && h.has_key?(:height)
            _width = h[:width]
            _height = h[:height]
          end

          if h.has_key?(:id)
            _id = h[:id]
          end
        elsif p[0].is_a?(Symbol) || p[0].is_a?(String)
          @browserType = p[0].to_s.to_sym
        elsif p[0].is_a?(Hash) && !p[0].empty?
          @logger.debug __FILE__ + (__LINE__).to_s + " #{p[0]}"

          h = p[0]

          if h.has_key?(:browserType)
            @logger.debug __FILE__ + (__LINE__).to_s + " UPDTE"
            @browserType = h[:browserType]
          end

          if h.has_key?(:width) && h.has_key?(:height)
            _width = h[:width]
            _height = h[:height]
          end

          if h.has_key?(:id)
            _id = h[:id]
          end

        end

      end

    else
      @logger.debug __FILE__ + (__LINE__).to_s + " createBrowser without parms (width/height: #{_width}, #{_height})"
    end

    @logger.debug "Selenium::WebDriver.for #{@browserType}  (isSymbol: #{@browserType.is_a?(Symbol)})" if @debug

    begin
      @drv = Selenium::WebDriver.for @browserType
    rescue  TypeError
      @logger.warn __FILE__ + (__LINE__).to_s +   " See https://github.com/mozilla/geckodriver/issues/676" if @browserType == :firefox
    end

    _addDriver( { :drv => @drv, :is_sauce => false, :id => _id })

    setDimension(_width, _height)
  end

  def _getDriverIndex(id)
    i = 0

    @driverList.each do |b|
      if b.has_key?(:id) && b[:id] == id
        return i
      end
      i += 1
    end

    return nil
  end


  def deleteDriver(id)
    i = _getDriverIndex(id)
    unless i.nil?
      @driverList.delete_at(i)
    end
  end

  def getDriver(id=nil)
    if id.nil?
      return @driverList[0][:drv]
    end

    i = _getDriverIndex(id)

    unless i.nil?
      return @driverList[i][:drv]
    end

    nil
  end


  def quit(id=nil)

    if id.nil?
      @browserMgr.getBrowsers().each do |b|

        begin
          if b[:is_sauce]
            job_id = b[:drv].session_id

            if b.has_key?(:status)
              SauceWhisk::Jobs.change_status job_id, b[:status]
            end

          end

          @logger.debug __FILE__ + (__LINE__).to_s + "  quit : #{b[:id]}"
          @logger.debug __FILE__ + (__LINE__).to_s + "  b.methods => #{b[:drv].methods.sort}"

          b[:drv].quit
        rescue => ex
          @logger.fatal __FILE__ + (__LINE__).to_s + " #{ex.class}  #{ex.message}"
          @logger.warn "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
        end

      end

      @browserMgr.clear()

      @driverList=[]
    else
      @logger.debug __FILE__ + (__LINE__).to_s + " quit(#{id}"
      getDriver(id).quit
      deleteDriver(id)
    end

  end

  def title()
    getDriver().title.to_s
  end

  def isTitle?(regex)
    current_title = getDriver().title
    expected_title = Regexp.new(regex)
    !expected_title.match(current_title).nil? || regex==current_title
  end

  def goto(url, id=nil)

    rc = false

    if id.nil?
      @driverList.each do |b|
        @logger.debug __FILE__ + (__LINE__).to_s + " => #{b}"
        b[:drv].navigate.to url
        rc = true
      end
    else
      getDriver(id).navigate.to url
      rc = true
    #getDriver().navigate.to url
    end

    rc
  end

#  def navigate(url, id=nil)
  def navigate(*p)
    rc=false

    if p.is_a?(Array)
      if p.length == 1
        rc = goto(p[0].to_s)
      elsif p.length == 2
        rc = goto(p[0], p[1])
      end

    end

    rc
  end

  def _parseLocator(_locator)

    locator = _locator

    if _locator.is_a?(String)

      if _locator.match(/^\s*(\/|\.)/i)
        locator = { :xpath => _locator }
      elsif _locator.match(/^\s*\#/i)
        locator = { :css => _locator }
      elsif _locator.match(/^\s*css\s*=\s*(.*)\s*$/)
        locator = { :css => _locator.match(/^\s*css\s*=\s*(.*)$/)[1].to_s }
      end
    end

    locator

  end

  def getElements(_locator, drv=nil, _timeout=30)
    rc = nil
    begin

      if drv.nil?
        drv=getDriver()
      end

      Selenium::WebDriver::Wait.new(timeout: _timeout).until {
        _obj = drv.find_elements(_parseLocator(_locator))

        if !_obj.nil?
          rc = _obj
        end

        !rc.nil?
      }

    rescue Selenium::WebDriver::Error::NoSuchElementError
      @logger.info __FILE__ + (__LINE__).to_s + " NoSuchElementError : #{_locator}"

    rescue => ex
      @logger.warn "Error during processing: #{$!}"
      @logger.warn "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
    end

    rc
  end



  def getElement(_locator, drv=nil, _timeout=30)
    @logger.debug __FILE__ + (__LINE__).to_s + " getElement(#{_locator})"
    rc = nil
    begin
      locator = _parseLocator(_locator)


      if drv.nil?
        drv=getDriver()
      end

      @logger.debug __FILE__ + (__LINE__).to_s + " getElement() => #{locator}"

      Selenium::WebDriver::Wait.new(timeout: _timeout).until {
        _obj = drv.find_element(locator)
        if _obj.displayed?
          rc = _obj
        end

        !rc.nil?
      }

    rescue Selenium::WebDriver::Error::TimeOutError
      @logger.debug __FILE__ + (__LINE__).to_s + " TimeOutError: #{locator}"

    rescue Selenium::WebDriver::Error::NoSuchElementError
      @logger.warn __FILE__ + (__LINE__).to_s + " NoSuchElementError : #{locator}"

    rescue => ex
      @logger.warn __FILE__ + (__LINE__).to_s + " #{ex.class}"
      @logger.warn "Error during processing: #{$!}"
      @logger.warn "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
    end

    rc
  end

  def _isBrowser?(drv, s)

    @logger.debug __FILE__ + (__LINE__).to_s + " _isBrowser?(#{drv.class}, #{s})"
    if drv.nil?
      drv=@drv
    end

    !drv.browser.to_s.match(s).nil?
  end

  def isChrome?(drv=nil)
    if drv.nil?
      drv=@drv
    end

    !drv.browser.to_s.match(/\s*chrome/i).nil?
  end

  def isEdge(drv=nil)
    if drv.nil?
      drv=@drv
    end

    !drv.browser.to_s.match(/\s*edge/i).nil?
  end

  def isIE(drv=nil)
    if drv.nil?
      drv=@drv
    end

    !drv.browser.to_s.match(/\s*ie/i).nil?
  end

  def isFirefox?(drv=nil)

    if drv.nil?
      drv = @driverList[0][:drv]
    end

    Browza::Manager.instance._isBrowser?(drv, 'firefox')
  end


  def switch_into_frame(drv, id)
    @logger.debug __FILE__ + (__LINE__).to_s + "[enter]: switch_into_frame(#{drv.class}, #{id})"
    _fcnId = '[switch_into_frame]'
    hit = nil

    # _addDriver( { :id => id, :drv => @drv, :is_sauce => true })
    if isChrome?(drv) || !@driverList[0][:is_sauce] # 5150|| isFirefox?(drv)

#     drv.switch_to.default_content

      @logger.debug  __FILE__ + (__LINE__).to_s + "#{_fcnId}: switch on Chrome browser"
      bframes = drv.find_elements(:xpath, '//iframe')

      @logger.debug __FILE__ + (__LINE__).to_s + "#{_fcnId}: //iframe : size #{bframes.size}"

      if bframes.size == 0
        bframes = drv.find_elements(:xpath, '//frame')

        @logger.debug __FILE__ + (__LINE__).to_s + "#{_fcnId}: //frame : #{bframes.size}"
      end


      for i in 0 .. bframes.size - 1
        begin

          _tag = bframes[i].attribute('name')

          if !_tag.nil? && _tag.empty?
            _tag = bframes[i].attribute('id')
          end


          @logger.debug __FILE__ + (__LINE__).to_s + "[switch_into_frame.chrome]: <tag, id> :: <#{_tag}, #{id} >"

          if !_tag.empty? && id==_tag

            hit = bframes[i]
            drv.switch_to.frame hit

            @logger.debug __FILE__ + (__LINE__).to_s + "#{_fcnId}: swtichframe to #{i} - #{_tag}"
            break
          end

        rescue => ex
          @logger.warn  "Error during processing: #{$!}"
          @logger.warn "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
        end

      end

    else
      # Firefox, IE
      @logger.debug __FILE__ + (__LINE__).to_s + "[switch_into_frame]: drv.switch_to.frame(#{id.to_s}";

      hit = drv.switch_to.frame(id.to_s.strip)

      @logger.debug __FILE__ + (__LINE__).to_s + " [switch_into_frame]: #{hit} - #{id}"
    end

    @logger.debug __FILE__ + (__LINE__).to_s + " switch_into_frame(#{id}) => #{hit}"
    hit
  end


  def switch_frame(e, drv=nil)
    rc = true
    drv = @driverList[0][:drv] if drv.nil?
    @logger.debug __FILE__ + (__LINE__).to_s + "\n\n== self.switch_frame(#{e}) =="
    frames=nil
    if e.is_a?(Hash) && e.has_key?('page') && e['page'].has_key?('frames')
      @logger.debug __FILE__ + (__LINE__).to_s + " frames => #{e['page']['frames']}";

      frames=e['page']['frames']
    elsif e.is_a?(String)
      frames=e
    end


    if !frames.nil?
      @logger.debug __FILE__ + (__LINE__).to_s + " [self.switch_frame]: frames => #{frames}";

      #   frame_list=frames.split(/(frame\(.*\))\.(?=[\w])/)
      frame_list=frames.split(/\.(?=frame)/)

      @logger.debug __FILE__+ (__LINE__).to_s + " [switch_frame]: default_content"
      drv.switch_to.default_content

      frame_list.each do |_f|
        @logger.debug __FILE__ + (__LINE__).to_s + " processing #{_f}"

        if !_f.empty?
          _id = _f.match(/frame\((.*)\)/)[1]

          @logger.debug __FILE__ + (__LINE__).to_s + " [self.switch_frame]: switch_to.frame #{_id}"

          # Swtich based on browser type

          if isChrome?(drv) || !@driverList[0][:is_sauce]# 5150|| isFirefox?(drv)
            if switch_into_frame(drv, _id).nil?
              @logger.debug __FILE__ + (__LINE__).to_s + " Frame with name/id #{_id} not found"
              rc = false
              break
            else
              @logger.debug __FILE__ + (__LINE__).to_s + " Sucessfully switched frame into #{_id}"
            end
          else
            @logger.debug __FILE__ + (__LINE__).to_s + " [firefox]: switch_to.frame #{_id}"
            drv.switch_to.frame _id
          end

        end

      end

    end

    rc
  end

  def findLocator(_locator, drv=nil)
    drv = @driverList[0][:drv] if drv.nil?

    @logger.debug __FILE__ + (__LINE__).to_s + " [findLocator]: #{_locator}   sz: #{@appModels.length}"
    obj = nil
    _hit = nil
    if Appmodel::Model.isPageObject?(_locator) && @appModels.length > 0

      i=0
      @appModels.each do |m|
        @logger.debug __FILE__ + (__LINE__).to_s + " >> #{i}. #{m.class} =>  #{_locator}"
        begin
          ##
          # FRAMES
          ##
          pageObject = m.getPageElement(_locator)

          unless pageObject.nil?
            _hit = {}
            if pageObject.has_key?('frame')
              _hit['frame'] = pageObject['frame']
            end

            if pageObject.has_key?('locator')
              _hit['locator'] = Appmodel::Model.toBy(pageObject['locator'], m)
            end

            @logger.debug __FILE__ + (__LINE__).to_s + " pageObject => #{pageObject}"

            break
          end

        rescue => ex
          @logger.warn "Error during processing: #{$!}"
          @logger.warn "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
        end
      end

    elsif _locator.is_a?(String)
      _hit = Appmodel::Model.parseLocator(_locator)
    elsif _locator.is_a?(Hash)
      _hit = { 'locator' => _locator[:css]    } if _locator.has_key?(:css)
      _hit = { 'locator' => _locator['css']   } if _locator.has_key?('css')
      _hit = { 'locator' => _locator[:xpath]  } if _locator.has_key?(:xpath)
      _hit = { 'locator' => _locator['xpath'] } if _locator.has_key?('xpath')

      _hit['frame'] = _locator[:frame]  if _locator.has_key?(:frame)
      _hit['frame'] = _locator['frame'] if _locator.has_key?('frame')
    end

    @logger.debug __FILE__ + (__LINE__).to_s + " hit => #{_hit}"

    if _hit.is_a?(Hash)

      2.times {

        begin
          rcFrame = true

          if _hit.has_key?('frame')
            @logger.debug __FILE__ + (__LINE__).to_s + " [findLocator]: swtich_to_frame : #{_hit['frame']}"
            drv.switch_to.default_content
            rcFrame = switch_frame(_hit['frame'], drv)
          end

          if rcFrame && _hit.has_key?('locator')
            obj = getElement(_hit['locator'], drv, @defaultTimeout)
            if !obj.nil?
              break
            end
          end

          sleep(0.25)

        rescue => e
          @logger.debug __FILE__ + (__LINE__).to_s + " Exception:  #{e.class}"
          ;
        end
      }

    else
      obj = getElement(Appmodel::Model.toBy(_locator), drv, @defaultTimeout)
    end

    @logger.debug __FILE__ + (__LINE__).to_s + " [return findLocator(#{_locator})] : #{_hit}"
    _hit.nil? ? _locator : _hit

    obj
  end

  def getDate()
    return @driverList[0][:drv].execute_script('var s = new Date().toString(); return s')
  end


  def text(_locator, _drv=nil, _timeout=30)
    rc=nil

    @driverList.each do |b|
      begin

        drv=b[:drv]
        obj=nil
        drv.switch_to.default_content
        isDisplayed = Selenium::WebDriver::Wait.new(timeout: _timeout).until {
          obj = findLocator(_locator, drv)
          obj.is_a?(Selenium::WebDriver::Element) && obj.displayed? && obj.enabled?
        }
        if !obj.nil? && isDisplayed && obj.is_a?(Selenium::WebDriver::Element)
          @logger.debug __FILE__ + (__LINE__).to_s + " clicked #{_locator}"
          rc = obj.text
        end
      end
    end

    rc
  end

  ##
  # Browza.instance.click('page(sideNav).get(desktop)')
  ##
  def click(_locator, _drv=nil, _timeout=30)

    @logger.debug __FILE__ + (__LINE__).to_s + " click(#{_locator})"
    rc = false

    @driverList.each do |b|
      begin
        drv = b[:drv]
        obj = nil
        drv.switch_to.default_content

        isDisplayed = Selenium::WebDriver::Wait.new(timeout: _timeout).until {
          obj = findLocator(_locator, drv)
          obj.is_a?(Selenium::WebDriver::Element) && obj.displayed? && obj.enabled?
        }

      #  drv.action.move_to(obj).perform
        scrollElementIntoMiddle = "var viewPortHeight = Math.max(document.documentElement.clientHeight, window.innerHeight || 0);" +
         "var elementTop = arguments[0].getBoundingClientRect().top;" +
         "window.scrollBy(0, elementTop-(viewPortHeight/2));";


      #  drv.execute_script(scrollElementIntoMiddle, obj)
      #  drv.execute_script("arguments[0].scrollIntoView(true);", obj);


        @logger.debug __FILE__ + (__LINE__).to_s + "  [click]: obj => #{obj.class} : #{isDisplayed}"

        if !obj.nil? && isDisplayed && obj.is_a?(Selenium::WebDriver::Element)
          @logger.debug __FILE__ + (__LINE__).to_s + " clicked #{_locator}"
          obj.click
          rc = true
        end
      rescue => ex
        @logger.debug __FILE__ + (__LINE__).to_s + " #{ex.class}"
        @logger.debug "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
      end
    end

    unless rc
      @logger.debug __FILE__ + (__LINE__).to_s + " WARN: unable to click #{_locator}"
    end

    @logger.debug __FILE__ + (__LINE__).to_s + " ==== [click]: #{_locator} = #{rc}  ===="
    rc
  end

  def highlight(_locator, color='red', _drv=nil, _timeout=30)
    rc = false
    rgb=nil

    obj = findLocator(_locator)
    if !obj.nil?
      if color.match(/\s*blue/i)
        rgb='rgb(0, 0, 255)'
      elsif color.match(/\s*red/i)
        rgb='rgb(255, 0, 0)'
      elsif color.match(/\s*yellow/i)
        rgb='rgb(255, 255, 0)'
      elsif color.match(/\s*green/i)
        rgb='rgb(0, 255, 0)'
      elsif color.match(/\s*gray/i)
        rgb='rgb(128, 128, 128)'
      end

      border = 2

      begin
        @drv.execute_script("hlt = function(c) { c.style.border='solid #{border}px #{rgb}'; }; return hlt(arguments[0]);", obj)
        rc=true
      rescue => ex
        @logger.warn __FILE__ + (__LINE__).to_s + " #{ex.class}"
      end

    end

    obj.is_a?(Selenium::WebDriver::Element) && rc
  end

  def hover(_locator)
    rc = false

    obj = findLocator(_locator)
    if !obj.nil?
      begin
        @drv.action.move_to(obj).perform
        rc = true
      rescue => ex
        @logger.warn "Error during processing: #{$!} - #{ex.class}"
        @logger.warn "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
      end

    else
      @logger.debug __FILE__ + (__LINE__).to_s + " hover(#{_locator}) not found."
    end

    @logger.debug __FILE__ + (__LINE__).to_s + " hover(#{_locator}) : #{rc}"
    rc
  end


  def type(_locator, _text, _timeout=30)
    rc = false

#    obj = getElement(findLocator(_locator), _drv, _timeout)

    if _locator.match(/(active|focused)/i)
      obj = @drv.switch_to.active_element
    else
      obj = findLocator(_locator)
    end

    if !obj.nil?

      if _text.match(/\s*__CLEAR__\s*$/i)
       _text = :clear
      elsif _text.match(/\s*__DOWN__\s*$/i)
       _text = :arrow_down
      elsif _text.match(/\s*__ENTER__\s*$/i)
       _text = :enter
      elsif _text.match(/\s*__LEFT__\s*$/i)
       _text = :arrow_left
      elsif _text.match(/\s*__RIGHT__\s*$/i)
       _text = :arrow_right
      elsif _text.match(/\s*__UP__\s*$/i)
       _text = :arrow_up
      elsif _text.match(/\s*__TAB__\s*$/i)
       _text = :tab
      elsif _text.match(/\s*__SHIFT_TAB__\s*$/i)
        @drv.action.key_down(:shift).send_keys(:tab).perform
        @drv.action.key_up(:shift).perform
        rc = true
      end

      unless rc
        obj.send_keys(_text)
        rc=true
      end

    end

    rc
  end


  def isNotDisplayed?(_locator, _timeout=10)
    !displayed?(_locator, getDriver(), _timeout)
  end

  def displayed?(_locator, _drv=nil, _timeout=30)
    obj = findLocator(_locator)
    obj.is_a?(Selenium::WebDriver::Element) && obj.displayed?
  end

  def focusedText()
    activeElt = @drv.switch_to.active_element
    activeElt.attribute('text')
  end

  def focusedValue()
    v = nil
    begin
      activeElt = @drv.switch_to.active_element
      v = activeElt.attribute('value')
    rescue => ex
      @logger.warn __FILE__ + (__LINE__).to_s + " #{ex.class}"
      @logger.warn  "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
    end

    v
  end

  def focusedValue?(s, _timeout=10)
    rc = false

    Selenium::WebDriver::Wait.new(timeout: _timeout).until {
      activeElt = @drv.switch_to.active_element
      _v = activeElt.attribute('value')
      if _v.match(/#{s}/)
        rc = true
      end

      rc
    }
  end

  def isFocused?(_locator)

    rc = false
    activeElt = @drv.switch_to.active_element
    obj = findLocator(_locator)


    if !obj.nil?
      rc = (activeElt == obj)
    end

    rc

  end


  def isVisible?(_locator, expected = true, _timeout = 30)
    obj = nil
    rc = Selenium::WebDriver::Wait.new(timeout: _timeout).until {
      obj = findLocator(_locator, drv)
      obj.is_a?(Selenium::WebDriver::Element) && obj.displayed?
    }

    @logger.debug __FILE__ + (__LINE__).to_s + " isVisible?(#{_locator}) : #{rc}"
    rc == expected
  end


  def isValue?(_locator, regex=nil, _timeout = 30)
    @logger.debug __FILE__ + (__LINE__).to_s + " isValue?(#{_locator}, #{regex})"
    rc = false

    begin
      expected = Regexp.new(regex)
      drv = @driverList[0][:drv]
      obj = nil

      isExists = Selenium::WebDriver::Wait.new(timeout: _timeout).until {
        obj = findLocator(_locator, drv)
        if obj.is_a?(Selenium::WebDriver::Element)
          rc = !expected.match(obj.attribute('value')).nil? || regex==obj.attribute('value')
        end

        rc
      }

      @logger.debug __FILE__ + (__LINE__).to_s + " | obj : #{obj}  => #{isExists}"

      if false && !obj.nil? && isExists
        @logger.debug __FILE__ + (__LINE__).to_s + " | obj.value: #{obj.attribute('value')}"
        expected = Regexp.new(regex)
        rc = !expected.match(obj.attribute('value')).nil? || regex==obj.attribute('value')
      end

    rescue => ex
      @logger.warn __FILE__ + (__LINE__).to_s + " #{ex.class}"
      @logger.warn "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
    end

    @logger.debug __FILE__ + (__LINE__).to_s + " [return]: isValue?(#{_locator}, #{regex}) : #{rc}"
    rc
  end


  def isText?(_locator, regex=nil)
    @logger.debug __FILE__ + (__LINE__).to_s + " isText?(#{_locator}, #{regex})"
    rc = false

    begin
      obj = findLocator(_locator)

      @logger.debug __FILE__ + (__LINE__).to_s + " | obj : #{obj}"

      if !obj.nil?
        @logger.debug __FILE__ + (__LINE__).to_s + " | obj.text: #{obj.text}"
        expected = Regexp.new(regex)
        rc = !expected.match(obj.text).nil? || regex==obj.text
      end

    rescue => ex
      @logger.warn __FILE__ + (__LINE__).to_s + " #{ex.class}"
      @logger.warn "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
    end

    @logger.debug __FILE__ + (__LINE__).to_s + " [return]: isText?(#{_locator}, #{regex}) : #{rc}"
    rc
  end


  ##
  # press('enter')
  # press('tab', 5)
  # press('page(main).get(button)', 'enter')
  ##
  def press(*p)
    rc = nil

    if p.length == 1
      rc = pressKey(p[0], 1)
    elsif p.length == 2

      if p[1].is_a?(Integer) || p[1].to_s.match(/^\s*\d+$/)
        rc = pressKey(p[0], p[1].to_i)
      else
        rc = type(p[0], p[1])
      end

    else
      raise "BROWZA::Press::Unexpected"
    end

    rc
  end

  def pressKey(k, n = 1)

    rc = 0
    begin
      n.times {
        if k.match(/^\s*tab/i)
          activeElt = @drv.switch_to.active_element
          activeElt.send_keys(:tab)
        elsif k.match(/^\s*clear\s*$/)
          activeElt = @drv.switch_to.active_element
          activeElt.clear
        elsif k.match(/\s*^enter/i)
          activeElt = @drv.switch_to.active_element
          activeElt.send_keys(:enter)
        elsif k.match(/\s*^(down|__down__|arrow_down)/i)
          activeElt = @drv.switch_to.active_element
          activeElt.send_keys(:arrow_down)
        elsif k.match(/\s*^up/i)
          activeElt = @drv.switch_to.active_element
          activeElt.send_keys(:arrow_up)
        elsif k.match(/\s*__SHIFT_TAB__\s*$/i)
          @drv.action.key_down(:shift).send_keys(:tab).perform
          @drv.action.key_up(:shift).perform
        else
          break
        end

        rc += 1
      }

    rescue => ex
      ;
    end

    rc
  end

  def selected?(_locator, _drv=nil, _timeout=30)
    rc=false

#    obj=getElement(findLocator(_locator), _drv, _timeout)
    obj = findLocator(_locator)
    if !obj.nil?
      rc=obj.selected?
    end
    rc
  end

  def getCount(_locator, _drv=nil, _timeout=30)
    rc=0
    elts = getElements(_locator, _drv, _timeout)
    if !elts.nil?

      #     hits = elts.select { |obj| obj.displayed? }

      rc = elts.length
    end

    rc.to_i
  end


  def hasStyle?(_locator, tag, expected = nil, _timeout = 30)
    @logger.debug __FILE__ + (__LINE__).to_s + " hasStyle?(#{_locator})"
    rc = nil

    @driverList.each do |b|
      begin
        drv = b[:drv]

        @logger.debug __FILE__ + (__LINE__).to_s + "   [hasStyle]: switch_to.default_content"
        drv.switch_to.default_content
        obj = findLocator(_locator, drv)

        isDisplayed = Selenium::WebDriver::Wait.new(timeout: _timeout).until {
          obj = findLocator(_locator, drv)
          obj.is_a?(Selenium::WebDriver::Element)
        }

        if !obj.nil?
          @logger.debug __FILE__ + (__LINE__).to_s + " style #{_locator}"
          rc = obj.style(tag)
        end
      rescue => ex
        @logger.warn __FILE__ + (__LINE__).to_s + " #{ex.class}"
        @logger.warn "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
      end
    end

    unless expected.nil?
      regex = Regexp.new(expected)
      rc = !regex.match(rc.to_s).nil? || (expected.to_s == rc.to_s)

      @logger.debug __FILE__ + (__LINE__).to_s + " WARN: unable to get style #{tag} for #{_locator}"
    end

    @logger.debug __FILE__ + (__LINE__).to_s + " hasStyle(#{_locator}, #{tag}) : #{rc.to_s}"
    rc
  end


end


end

