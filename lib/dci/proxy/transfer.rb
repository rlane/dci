require 'socket'

module DCI::Proxy::Transfer
	BUFFER_SIZE = 64 * 1024

	def start_transfer username, filename, offset=0, timeout=CFG['ctm_timeout']
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

	def transfer_chunk instream, outstream, len
		count = 0
		while d = (instream.readpartial(BUFFER_SIZE) rescue nil)
			count += d.size
			log.debug "read #{d.size} (#{count}/#{len})"
			outstream.write d
			break if count >= len
		end
		count
	end

	def connect_to_peer usernames, filename, offset
		online = usernames.select { |x| $hub.users.member? x }.shuffle
		log.warn "all peers (#{usernames.inspect}) offline" if online.empty?
		online.find_value { |username| start_transfer username, filename, offset }
	end
end
