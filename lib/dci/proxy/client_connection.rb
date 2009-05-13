module DCI::Proxy

class ClientConnection < BaseConnection
	BUFFER_SIZE = 32 * 1024
	SUPPORTS = %w(MiniSlots XmlBZList ADCGet TTHL TTHF GetZBlock ZLIG)
	INITIATIVE_ROLL = 100000

	def initialize name, s
		super
		write "$MyNick #{CFG['dc_username']}"
		lock = "EXTENDEDPROTOCOL" + "abcd" * 6
		pk = "df23" * 4
		write "$Lock #{lock} Pk=#{pk}"
		write "$Supports #{SUPPORTS * ' '}  "
		write "$Direction Download #{INITIATIVE_ROLL}"
		m = expect :type => :mynick
		nick = m[:nick]
		m = expect :type => :lock
		write "$Key #{m[:key]}"
		expect :type => :supports
		expect :type => :direction
		expect :type => :key
		log.info "client connection initialized: local=#{s.addr.inspect}, remote=#{s.peeraddr.inspect}"
		$client_logger.log :nick => nick, :ip => s.peeraddr[3], :port => s.peeraddr[1], :hostname => s.peeraddr[2]
	end

	def adcget filename, offset = 0, length = -1
		write "$ADCGET file #{filename} #{offset} #{length}"
	end

	def download filename, io
		adcget filename
		m = readmsg
		log.debug m.inspect
		raise 'error' unless m[:type] == :adcsnd
		count = 0
		while d = s.readpartial(BUFFER_SIZE)
			count += d.size
			log.debug "read #{d.size} (#{count}/#{m[:length]})"
			io.write d
			break if count >= m[:length]
		end
	end
end

end
