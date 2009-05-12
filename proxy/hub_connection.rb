require 'asami/key_generator'
require 'asami/hub_parser'
require 'proxy/base_connection'

module DCProxy

class HubConnection < BaseConnection
	attr_reader :users

	def initialize name, username, address, port, self_address
		@address = address
		@port = port
		@self_address = self_address
		@username = username
		@location = 'B6'
		@sharesize = 106232539641
		@users = {}

		s = TCPSocket.new address, port
		super name, s

		log "handshaking"
		expect "$Lock FOO Pk=BAR"
		write "$Key E01"
		expect "$HubName Dtella@CMU"
		write "$ValidateNick #{@username}"
		expect "$Hello #{@username}"
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

	def connect_to_me nick, self_port
		write "$ConnectToMe #{nick} #{@self_address}:#{self_port}"
	end

	def who
		users.keys
	end
end

end
