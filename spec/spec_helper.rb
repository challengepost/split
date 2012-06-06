ENV['RACK_ENV'] = "test"

require 'rubygems'
require 'bundler/setup'
require 'split'
require 'split/session_store'
require 'ostruct'
require 'complex' if RUBY_VERSION.match(/1\.8/)

RSpec.configure do |config|
  config.before(:each) do
    Split.store = nil
  end
end

def session
  @session ||= {}
end

def params
  @params ||= {}
end

def request(ua = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_6; de-de) AppleWebKit/533.20.25 (KHTML, like Gecko) Version/5.0.4 Safari/533.20.27')
  r = OpenStruct.new
  r.user_agent = ua
  r.ip = '192.168.1.1'
  @request ||= r
end
