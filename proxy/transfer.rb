module DCProxy

module Transfer
	BUFFER_SIZE = 32 * 1024

	def start_transfer username, filename, offset=0, timeout=10
		srv = nil
		while !srv
			#port = 18000 + rand(1000)
			port = 9020
			begin
				srv = TCPServer.new port
			rescue => e
				puts "exception creating client port: #{e.message}"
				sleep 1
			end
		end
		begin
			puts "downloading #{username}:#{filename} at #{port}"
			$hub.connect_to_me username, port
			puts "accepting client connection..."
			s = (Timeout.timeout(timeout) { srv.accept }) rescue nil
		rescue
			puts "timeout waiting for peer"
		ensure
			srv.close
		end
		return unless s
		puts "client accepted"
		client = ClientConnection.new "#{username}:#{filename}", s
	
		client.adcget filename, offset
		m = client.readmsg
		(puts "unexpected msg type #{m[:type].inspect}"; return) unless m[:type] == :adcsnd
		return s, m[:length]
	end

	def transfer_chunk instream, outstream, len
		count = 0
		while d = (instream.readpartial(BUFFER_SIZE) rescue nil)
			count += d.size
			puts "read #{d.size} (#{count}/#{len})"
			outstream.write d
			break if count >= len
		end
		count
	end

	def connect_to_peer usernames, filename, offset
		online = usernames.select { |x| $hub.users.member? x }.shuffle
		puts "all peers offline" if online.empty?
		online.find_value { |username| start_transfer username, filename, offset }
	end
end

end
