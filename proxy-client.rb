#!/usr/bin/env ruby
require 'thread'
require 'irb'

require 'proxy/client_connection'

include DCProxy

HUB_ADDRESS = 'localhost'
HUB_PORT = 7314
SELF_ADDRESS = '127.0.0.1'
SELF_PORT = 9020

srv = TCPServer.new SELF_ADDRESS, SELF_PORT
s = srv.accept
$client = ClientConnection.new 'client', s

=begin
Thread.new do
	$hub.run
	$stderr.puts "hub thread terminated"
end
=end

IRB.setup nil
irb = IRB::Irb.new(IRB::WorkSpace.new($client))
IRB.conf[:MAIN_CONTEXT] = irb.context
trap('SIGINT') { irb.signal_handle }
catch(:IRB_EXIT) { irb.eval_input }
