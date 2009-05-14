module DCI::Proxy

class ClientConnection < BaseConnection
	BUFFER_SIZE = 64 * 1024
	SUPPORTS = %w(MiniSlots XmlBZList ADCGet TTHL TTHF GetZBlock ZLIG)
	INITIATIVE_ROLL = 100000

	def initialize name, s
		super
		handshake
	end

	def handshake
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
		$client_logger.log :nick => nick, :ip => s.peeraddr[3], :port => s.peeraddr[1], :hostname => s.peeraddr[2], :time => Time.now.to_i
	end

	def adcget filename, offset = 0, length = -1
		write "$ADCGET file #{filename} #{offset} #{length}"
	end

	def self.start_transfer username, filename, offset=0, timeout=CFG['ctm_timeout']
		srv = nil
		while !srv
			port_range_len = CFG['ctm_port_end'] - CFG['ctm_port_start']
			port = CFG['ctm_port_start'] + (port_range_len == 0 ? 0 : rand(port_range_len))
			begin
				srv = TCPServer.new port
			rescue => e
				log.error "exception creating client port: #{e.message}"
				sleep 1
			end
		end
		begin
			log.info "downloading #{username}:#{filename} at #{port}"
			$hub.connect_to_me username, port
			log.info "accepting client connection..."
			s = (Timeout.timeout(timeout) { srv.accept }) rescue nil
		rescue
			log.warn "timeout waiting for peer"
		ensure
			srv.close
		end
		return unless s
		log.info "client accepted"
		client = DCI::Proxy::ClientConnection.new "#{username}:#{filename}", s
	
		client.adcget filename, offset
		m = client.readmsg or return
		(log.error "unexpected msg type #{m[:type].inspect}"; return) unless m[:type] == :adcsnd
		return s, m[:length]
	end

	def self.chunks instream, len
		count = 0
		while d = (instream.readpartial(BUFFER_SIZE) rescue nil)
			count += d.size
			log.debug "read #{d.size} (#{count}/#{len})"
			yield d
			break if count >= len
		end
		count > 0
	end

	def self.connect_to_peer usernames, filename, offset
		online = usernames.select { |x| $hub.users.member? x }.shuffle
		log.warn "all peers (#{usernames.inspect}) offline" if online.empty?
		online.find_value { |username| start_transfer username, filename, offset }
	end

	def self.download filename, usernames, cache_id, offset, length
		delay = 1

		cache_fn = CFG['cache_dir'] + '/' + cache_id if cache_id
		log.info "cache filename: #{cache_fn}"
		s, len = if cache_id && File.exists?(cache_fn)
			[File.open(cache_fn, "r"), File.size(cache_fn)]
		else
			connect_to_peer usernames, filename, offset
		end
		return yield :unavailable unless s
		length = offset + len unless length

		begin
			yield :started
			while offset < length
				chunks s, [(length-offset),len].min do |chunk|
					offset += chunk.size
					yield chunk
				end

				if offset < length
					log.warn "transfer aborted by peer at (#{offset}/#{length}), trying to failover"
					yield :peer_aborted
					s = nil
					while !s
						raise 'max retries exceeded' if delay > 2**5
						log.info "sleeping #{delay}"
						sleep delay
						delay *= 2
						s, len = connect_to_peer usernames, filename, offset
					end
					delay = 1
				end
			end
			log.info "transfer completed"
			yield :complete
		rescue => e
			log.warn "transfer failed: #{e.class} #{e.message}"
			yield :failed
		ensure
			s.close unless !s or s.closed?
		end
	end
end

end
