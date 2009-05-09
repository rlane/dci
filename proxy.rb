#!/usr/bin/env ruby
require 'socket'
require 'thread'

HUB_ADDRESS = 'localhost'
HUB_PORT = 7314
SELF_ADDRESS = '127.0.0.1'
SELF_PORT = 9020

class DCConnection
	attr_reader :s

	def initialize address, port
		@address = address
		@port = port
		@s = TCPSocket.new address, port
	end

	def write msg
		d = "#{msg}|"
		@s.write d
		puts "> #{d.inspect}"
	end

	def read
		msg = @s.gets '|'
		return unless msg
		msg.chomp! '|'
		puts "< #{msg.inspect}"
		msg
	end

	def expect msg
		l = read
		fail "expected #{msg.inspect}, got #{l.inspect}" unless msg == l
	end

	def log msg
		$stderr.puts "! #{msg}"
	end

	def disconnect
		@s.close!
	end
end

class HubConnection < DCConnection
	def initialize address, port
		@username = "nobody"
		@location = 'B6'
		@sharesize = 106232539641
		@users = {}

		log "connecting to hub"
		super
		log "handshaking"
		expect "$Lock FOO Pk=BAR"
		write "$Key E01"
		expect "$HubName Dtella@CMU"
		write "$ValidateNick #{@username}"
		expect "$Hello nobody"
		write "$GetNickList"
		write "$MyINFO $ALL #{@username} <++ V:0.698,M:A,H:1/0/0,S:3,Dt:1.2.0/L>$ $#{@location}\001$$#{@sharesize}$|"
	end

	def run
		while (l = read)
			case l
			when /^<(.+)> (.*)$/
				log "chat from #{$1.inspect}: #{$2.inspect}"
			when /^\$Hello (.*)$/
				log "hello user #{$1.inspect}"
				@users[$1] = true
			when /^\$Quit (.*)$/
				log "quit user #{$1.inspect}"
				@users.delete $1
			when /^\$MyINFO \$ALL ([^ ]*) (.*)$/
				log "info user #{$1.inspect}: #{$2.inspect}"
			when /^\$Search .*$/
			when /^\$OpList .*/
			when /^\$NickList (.*)/
				@users.clear
				$1.split('$$').each { |x| @users[x] = true }
			when /^\$HubName .*$/
			when /^\$ConnectToMe ([^ ]+) (\d+\.\d+\.\d+\.\d+):(\d+)/
				log "ConnectToMe from #{1.inspect} at ip #{$2.inspect} port #{$3.inspect}"
			when ""
			else
				raise "unhandled message: #{l.inspect}"
			end
		end
	end

end

$hub = HubConnection.new HUB_ADDRESS, HUB_PORT

#tag = "<++V:0.02,M:A,H:1/0/0,S:1>"
#$hub.write "MyINFO $ALL #{tag} #{username}$ $%s%s$%s$%d$",

Thread.new do
	$hub.run
	$stderr.puts "hub thread terminated"
end

while (l = $stdin.gets)
	l.chomp!
	$hub.write l
end
