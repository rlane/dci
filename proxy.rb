#!/usr/bin/env ruby
require 'socket'
require 'thread'
require 'asami/key_generator'
require 'asami/hub_parser'
require 'asami/client_parser'

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
			m = HubParser.parse_message l
			case m[:type]
			when :chat
				log "chat from #{m[:from].inspect}: #{m[:text].inspect}"
			when :denide
			when :getpass
			when :badpass
			when :lock
			when :hubname
			when :hello
				@users[m[:who]] = true
			when :myinfo
				log "info user #{m[:nick].inspect}: #{m.inspect}"
			when :privmsg
			when :connect_to_me
			when :nick_list
				@users.clear
				m[:nicks].each { |x| @users[x] = true }
			when :passive_search_result
			when :pasv_search
			when :active_search
			when :op_list
			when :quit
				@users.delete m[:who]
			when :searchresult
			when :revconnect
			when :junk
			else
				raise "unknown message type #{m[:type].inspect}"
			end
		end
	end

end

$hub = HubConnection.new HUB_ADDRESS, HUB_PORT


Thread.new do
	$hub.run
	$stderr.puts "hub thread terminated"
end

while (l = $stdin.gets)
	l.chomp!
	$hub.write l
end
