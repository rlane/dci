#!/usr/bin/env ruby
require 'rubygems'
require 'thread'
require 'irb'

require 'proxy/hub_connection'
require 'proxy/client_connection'
require 'proxy/http'
require 'query-lib'
require 'bot'

include DCProxy

HUB_ADDRESS = 'localhost'
HUB_PORT = 7314
SELF_ADDRESS = ARGV[0] || '128.237.157.88'
HTTP_PORT = 8314
INDEX_FILENAME = "index"
JABBER_USERNAME = "dtella@club.cc.cmu.edu/#{`hostname`.chomp}"
JABBER_PASSWORD = 'loo7Pho3'
BASE_URL = "http://#{SELF_ADDRESS}:#{HTTP_PORT}"

$index = DtellaIndexReader.new INDEX_FILENAME
$hub = HubConnection.new 'hub', HUB_ADDRESS, HUB_PORT, SELF_ADDRESS
$http = DCProxy::HttpServer.new("0.0.0.0", HTTP_PORT)

Thread.new do
	$hub.run
	$stderr.puts "hub thread terminated"
end

Thread.new do
	$http.run
	$stderr.puts "http thread terminated"
end

$bot = DtellaBot.new JABBER_USERNAME, JABBER_PASSWORD

IRB.setup nil
irb = IRB::Irb.new(IRB::WorkSpace.new($hub))
IRB.conf[:MAIN_CONTEXT] = irb.context
trap('SIGINT') { irb.signal_handle }
catch(:IRB_EXIT) { irb.eval_input }
