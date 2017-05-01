#require 'browza/version'

module Browza
  ROOT_DIR = File.join(File.dirname(File.expand_path(__FILE__)), 'browza').freeze

  Dir["#{ROOT_DIR}/*.rb"].each { |f| require f }
  Dir["#{ROOT_DIR}/**/*.rb"].each { |f| require f }
end

