module DCI::Proxy

class HubConnection < BaseConnection
	attr_reader :users

	def initialize name, username, address, port, self_address
		@address = address
		@port = port
		@self_address = self_address
		@username = username
		@location = CFG['location']
		@sharesize = CFG['sharesize']
		@users = {}

		s = TCPSocket.new address, port
		super name, s

		handshake
	end

	def handshake
		log.debug "handshaking"
		m = expect :type => :lock
		write "$Key #{m[:key]}"
		expect :type => :hubname
		write "$ValidateNick #{@username}"
		expect :type => :hello, :who => @username
		write "$GetNickList"
		write "$MyINFO $ALL #{@username} <++ V:0.698,M:A,H:1/0/0,S:3,Dt:1.2.0/L>$ $#{@location}\001$$#{@sharesize}$|"
	end

	def process m
		case m[:type]
		when :chat
			$chat_logger.info "chat: #{m[:from].inspect} > #{m[:text].inspect}"
		when :privmsg
			$chat_logger.info "privmsg: #{m[:from].inspect} > #{m[:text].inspect}"
		when :nick_list
			@users.clear
			m[:nicks].each { |x| @users[x] = true }
		when :hello
			@users[m[:who]] = true
		when :quit
			@users.delete m[:who]
		when :myinfo
			@users[m[:nick]] = m.filter_keys :email, :interest, :speed, :sharesize
		when :active_search, :pasv_search
			m[:time] = Time.now.to_i
			$search_logger.log m
		when :connect_to_me
			log.debug "ignoring CTM #{m.inspect}"
		when :op_list
		when :hubname
		when :junk
		else
			log.warn "unhandled message #{m.inspect}"
		end
	end

	def connect_to_me nick, self_port
		write "$ConnectToMe #{nick} #{@self_address}:#{self_port}"
	end

	def privmsg nick, msg
		write "$To: #{nick} From: #{@username} $<#{@username}> #{msg}"
	end

	def who
		@users.keys
	end
end

end
