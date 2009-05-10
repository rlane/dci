#!/usr/bin/env ruby
require 'thread'
require 'irb'

require 'proxy/hub_connection'
require 'proxy/client_connection'

include DCProxy

HUB_ADDRESS = 'localhost'
HUB_PORT = 7314
SELF_ADDRESS = '128.237.157.88'
SELF_PORT = 9020

$hub = HubConnection.new 'hub', HUB_ADDRESS, HUB_PORT, SELF_ADDRESS, SELF_PORT

Thread.new do
	$hub.run
	$stderr.puts "hub thread terminated"
end

IRB.setup nil
irb = IRB::Irb.new(IRB::WorkSpace.new($hub))
IRB.conf[:MAIN_CONTEXT] = irb.context
trap('SIGINT') { irb.signal_handle }
catch(:IRB_EXIT) { irb.eval_input }
