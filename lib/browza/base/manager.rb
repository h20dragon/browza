require 'selenium-webdriver'
require 'singleton'
require 'appmodel'

module Browza

class Manager

  include Singleton

  attr_accessor :drv
  attr_accessor :appModels
  attr_accessor  :browserType

  def initialize
    @appModels=[]
  end

  def addModel(_a)
    puts __FILE__ + (__LINE__).to_s + " [addModel]: #{_a}"
    @appModels << Appmodel::Model.new(_a)
  end

  # Set innerWidth and innerHeight
  def setDimension(width=1035, height=768)
    target_size = Selenium::WebDriver::Dimension.new(width, height)
    getDriver().manage.window.size = target_size
  end

  def maximize()
    getDriver().manage.window.maximize
  end

  def createBrowser(_type = :chrome)
    @browserType = _type
    @drv = Selenium::WebDriver.for @browserType
    setDimension
  end

  def getDriver()
    @drv
  end

  def quit()
    getDriver().quit
  end

  def title()
    getDriver().title.to_s
  end

  def isTitle?(regex)
    current_title = getDriver().title
    expected_title = Regexp.new(regex)
    !expected_title.match(current_title).nil? || regex==current_title
  end

  def goto(url)
    getDriver().navigate.to url
  end

  def navigate(url)
    goto(url)
  end

  def _parseLocator(_locator)

    locator = _locator
    _by = :xpath

    if _locator.is_a?(String)

      if _locator.match(/^\s*(\/|\.)/i)
        locator = { :xpath => _locator }
      elsif _locator.match(/^\s*\#/i)
        locator = { :css => _locator }
      elsif _locator.match(/^\s*css\s*=\s*(.*)\s*$/)
        locator = { :css => _locator.match(/^\s*css\s*=\s*(.*)$/)[1].to_s }
        puts "LOCATOR.CSS => #{locator}"

      end
    end

    locator

  end

  def getElements(_locator, drv=nil, _timeout=30)
    rc=nil
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
      puts __FILE__ + (__LINE__).to_s + " NoSuchElementError : #{_locator}"

    rescue => ex
      puts "Error during processing: #{$!}"
      puts "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
    end

    rc
  end



  def getElement(_locator, drv=nil, _timeout=30)

    puts __FILE__ + (__LINE__).to_s + " getElement(#{_locator})"
    rc=nil
    begin
      locator = _parseLocator(_locator)


      if drv.nil?
        drv=getDriver()
      end

      Selenium::WebDriver::Wait.new(timeout: _timeout).until {
        _obj = drv.find_element(locator)
        if _obj.displayed?
          rc = _obj
        end

        !rc.nil?
      }

    rescue Selenium::WebDriver::Error::NoSuchElementError
      puts __FILE__ + (__LINE__).to_s + " NoSuchElementError : #{locator}"

    rescue => ex
      puts "Error during processing: #{$!}"
      puts "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
    end

    rc
  end

  def isChrome?(drv=nil)
    if drv.nil?
      drv=@drv
    end

    !drv.browser.to_s.match(/chrome/i).nil?
  end

  def switch_into_frame(id)
    drv = @drv
    puts __FILE__ + (__LINE__).to_s + "== switch_into_frame(#{id})"
    _fcnId=" [switch_into_frame]"
    puts __FILE__ + (__LINE__).to_s + "#{_fcnId}: (#{id})"

    hit=nil

    if TestUtils.instance.isChrome?(drv)

      puts  __FILE__ + (__LINE__).to_s + "#{_fcnId}: switch on Chrome browser"
      bframes = drv.find_elements(:xpath, '//iframe')

      puts __FILE__ + (__LINE__).to_s + "#{_fcnId}: //iframe : size #{bframes.size}"

      if bframes.size == 0
        bframes = drv.find_elements(:xpath, '//frame')

        puts __FILE__ + (__LINE__).to_s + "#{_fcnId}: //frame : #{bframes.size}"
      end

      for i in 0 .. bframes.size - 1
        begin

          _tag = bframes[i].attribute('name')

          if !_tag.nil? && _tag.empty?
            _tag = bframes[i].attribute('id')
          end


          puts __FILE__ + (__LINE__).to_s + "[switch_into_frame.chrome]: <tag, id> :: <#{_tag}, #{id} >"

          if !_tag.empty? && id==_tag

            hit = bframes[i]
            drv.switch_to.frame hit

            puts __FILE__ + (__LINE__).to_s + "#{_fcnId}: swtichframe to #{i} - #{_tag}"
            break
          end

        rescue => ex
          puts  "Error during processing: #{$!}"
          puts "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
        end

      end

    else
      # Firefox, IE
      puts __FILE__ + (__LINE__).to_s + "#{_fcnId}: drv.switch_to.frame(#{id.to_s}";

      hit = drv.switch_to.frame(id.to_s.strip)
    end

    puts __FILE__ + (__LINE__).to_s + " switch_into_frame(#{id}) => #{hit}"
    hit
  end


  def switch_frame(e)

    drv = @drv
    puts __FILE__ + (__LINE__).to_s + "\n\n== self.switch_frame(#{e}) =="
    frames=nil
    if e.is_a?(Hash) && e.has_key?('page') && e['page'].has_key?('frames')
      puts __FILE__ + (__LINE__).to_s + " frames => #{e['page']['frames']}";

      frames=e['page']['frames']
    elsif e.is_a?(String)
      frames=e
    end


    if !frames.nil?
      puts __FILE__ + (__LINE__).to_s + " [self.switch_frame]: frames => #{frames}";

      #   frame_list=frames.split(/(frame\(.*\))\.(?=[\w])/)
      frame_list=frames.split(/\.(?=frame)/)

      drv.switch_to.default_content

      frame_list.each do |_f|
        puts __FILE__ + (__LINE__).to_s + " processing #{_f}"

        if !_f.empty?
          _id = _f.match(/frame\((.*)\)/)[1]

          puts __FILE__ + (__LINE__).to_s + " [self.switch_frame]: switch_to.frame #{_id}"

          # Swtich based on browser type

          if TestUtils.instance.isChrome?(drv)
            if switch_into_frame(_id).nil?
              puts __FILE__ + (__LINE__).to_s + " Frame with name/id #{_id} not found"
              break
            else
              puts __FILE__ + (__LINE__).to_s + " Sucessfully switched frame into #{_id}"
            end
          else
            puts __FILE__ + (__LINE__).to_s + " [firefox]: switch_to.frame #{_id}"
            drv.switch_to.frame _id
          end

          if false

            if drv.browser.to_s.match(/firefox/i)
              puts __FILE__ + (__LINE__).to_s + " [firefox]: switch_to.frame #{_id}"
              drv.switch_to.frame _id
            else

              if switch_into_frame(_id).nil?
                puts __FILE__ + (__LINE__).to_s + " Frame with name/id #{_id} not found"
                break
              else
                puts __FILE__ + (__LINE__).to_s + " Sucessfully switched frame into #{_id}"
              end
            end

          end


        end

      end

    end
  end

  def findLocator(_locator)
    puts __FILE__ + (__LINE__).to_s + " [findLocator]: #{_locator}   sz: #{@appModels.length}"
    obj = nil
    _hit = nil
    if Appmodel::Model.isPageObject?(_locator) && @appModels.length > 0

      i=0
      @appModels.each do |m|
        puts __FILE__ + (__LINE__).to_s + " >> #{i}. #{m.class} =>  #{_locator}"
        begin
          ##
          # FRAMES
          ##
          pageObject = m.getPageElement(_locator)

          puts __FILE__ + (__LINE__).to_s + " pageObject => #{pageObject}"

          unless pageObject.nil?
            _hit = {}
            if pageObject.has_key?('frame')
              _hit['frame'] = pageObject['frame']
            end

            if pageObject.has_key?('locator')
              _hit['locator'] = Appmodel::Model.toBy(pageObject['locator'], m)
            end

            break
          end

        rescue => ex
          puts "Error during processing: #{$!}"
          puts "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"
        end
      end
    end

    if _hit.is_a?(Hash)
      if _hit.has_key?('frame')
        puts __FILE__ + (__LINE__).to_s + "swtich_to_frame : #{_hit['frame']}"
        switch_frame(_hit['frame'])
      end

      if _hit.has_key?('locator')
        obj = getElement(_hit['locator'], @drv, 30)
      end

    else
      obj = getElement(Appmodel::Model.toBy(_locator), @drv, 30)
    end

    puts __FILE__ + (__LINE__).to_s + " [return findLocator(#{_locator})] : #{_hit}"
    _hit.nil? ? _locator : _hit

    obj
  end


  ##
  # TestUtils.instance.click('page(sideNav).get(desktop)')
  ##
  def click(_locator, _drv=nil, _timeout=30)
    rc = false

#    obj = getElement(findLocator(_locator), _drv, _timeout)
    obj = findLocator(_locator)
    if !obj.nil?
      obj.click
      rc=true
    end

    rc
  end

  def type(_locator, _text, _timeout=30)
    rc = false

#    obj = getElement(findLocator(_locator), _drv, _timeout)
    obj = findLocator(_locator)
    if !obj.nil?
      obj.send_keys(_text)
      rc=true
    end

    rc
  end

  def displayed?(_locator, _drv=nil, _timeout=30)
    rc=false

#    obj=getElement(findLocator(_locator), _drv, _timeout)
    obj = findLocator(_locator)
    if !obj.nil?
      rc=obj.displayed?
    end
    rc
  end

  def focusedText()
    activeElt = @drv.switch_to.active_element
    activeElt.attribute('text')
  end

  def focusedValue()
    activeElt = @drv.switch_to.active_element
    activeElt.attribute('value')
  end

  def press(k, n=1)

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
      elsif k.match(/\s*^down/i)
        activeElt = @drv.switch_to.active_element
        activeElt.send_keys(:arrow_down)
      elsif k.match(/\s*^up/i)
        activeElt = @drv.switch_to.active_element
        activeElt.send_keys(:arrow_up)
      else
        break
      end
    }
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


end


end

