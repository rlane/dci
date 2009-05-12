#!/usr/bin/env ruby
require 'rubygems'
require 'thread'
require 'irb'

require 'proxy/hub_connection'
require 'proxy/client_connection'
require 'proxy/http'
require 'proxy/downloader'
require 'query-lib'
require 'bot'

include DCProxy

DEV = ENV.member? 'DEV'

HUB_ADDRESS = 'localhost'
HUB_PORT = 7314
SELF_ADDRESS = DEV ? '128.237.157.88' : '128.237.157.110'
HTTP_PORT = 8314
INDEX_FILENAME = "index"
JABBER_USERNAME = "data#{DEV ? '-dev' : ''}@club.cc.cmu.edu/foo"
JABBER_PASSWORD = 'iir5Ahne'
BASE_URL = "http://#{SELF_ADDRESS}:#{HTTP_PORT}"
DC_USERNAME = DEV ? 'nobody' : 'data'

$index = DtellaIndexReader.new INDEX_FILENAME
$hub = HubConnection.new 'hub', DC_USERNAME, HUB_ADDRESS, HUB_PORT, SELF_ADDRESS
$http = DCProxy::HttpServer.new("0.0.0.0", HTTP_PORT)
$downloader = DCProxy::Downloader.new

Thread.new do
	$hub.run
	$stderr.puts "hub thread terminated"
end

Thread.new do
	$http.run
	$stderr.puts "http thread terminated"
end

Thread.new do
	$downloader.run
	$stderr.puts "downloader thread terminated"
end

$bot = DtellaBot.new JABBER_USERNAME, JABBER_PASSWORD

IRB.setup nil
irb = IRB::Irb.new(IRB::WorkSpace.new($hub))
IRB.conf[:MAIN_CONTEXT] = irb.context
trap('SIGINT') { irb.signal_handle }
catch(:IRB_EXIT) { irb.eval_input }
