require 'mongrel'
require 'timeout'

module DCProxy

class BaseHttpServer
	def initialize address, port
		@srv = TCPServer.new address, port
	end

	def run
		while s = @srv.accept
			Thread.new do
				process s
			end
		end
	end

	# Copied from Mongrel
	def process client
		begin
			parser = Mongrel::HttpParser.new
			params = Mongrel::HttpParams.new
			request = nil
			data = client.readpartial(Mongrel::Const::CHUNK_SIZE)
			nparsed = 0

			while nparsed < data.length
				nparsed = parser.execute(params, data, nparsed)

				if parser.finished?
					if not params[Mongrel::Const::REQUEST_PATH]
						# it might be a dumbass full host request header
						uri = URI.parse(params[Const::REQUEST_URI])
						params[Const::REQUEST_PATH] = uri.path
					end

					raise "No REQUEST PATH" if not params[Mongrel::Const::REQUEST_PATH]
					handle_request client, params
				else
					# Parser is not done, queue up more data to read and continue parsing
					chunk = client.readpartial(Mongrel::Const::CHUNK_SIZE)
					break if !chunk or chunk.length == 0  # read failed, stop processing

					data << chunk
					if data.length >= Mongrel::Const::MAX_HEADER
						raise Mongrel::HttpParserError.new("HEADER is longer than allowed, aborting client early.")
					end
				end
			end
		rescue EOFError,Errno::ECONNRESET,Errno::EPIPE,Errno::EINVAL,Errno::EBADF
			client.close rescue nil
		rescue Mongrel::HttpParserError => e
			STDERR.puts "#{Time.now}: HTTP parse error, malformed request (#{params[Mongrel::Const::HTTP_X_FORWARDED_FOR] || client.peeraddr.last}): #{e.inspect}"
			STDERR.puts "#{Time.now}: REQUEST DATA: #{data.inspect}\n---\nPARAMS: #{params.inspect}\n---\n"
		rescue Object => e
			STDERR.puts "#{Time.now}: Read error: #{e.inspect}"
			STDERR.puts e.backtrace.join("\n")
		ensure
			begin
				client.close
			rescue IOError
				# Already closed
			rescue Object => e
				STDERR.puts "#{Time.now}: Client error: #{e.inspect}"
				STDERR.puts e.backtrace.join("\n")
			end
		end
	end

	def handle_request client, params
		client.write(Mongrel::Const::ERROR_404_RESPONSE)
	end

	def write_status client, status, reason
		client.write(Mongrel::Const::STATUS_FORMAT % [status, reason || Mongrel::HTTP_STATUS_CODES[status]])
	end

	def write_headers client, headers
		headers.each { |k,v| client.write "#{k}: #{v}\r\n" }
	end

	def write_separator client
		client.write "\r\n"
	end
end

class HttpServer < BaseHttpServer
	BUFFER_SIZE = 32 * 1024

	def parse_args params
		Mongrel::HttpRequest.query_parse params['QUERY_STRING']
	end

	def handle_request client, params
		puts "handling #{params['REQUEST_PATH'].inspect}"
		case params['REQUEST_PATH']
		when '/filelist'
			args = parse_args params
			username = args['username']
			fail unless username
			handle_filelist client, username
		when '/users'
			handle_users client
		when /^\/=([\w\d\/\+]+)$/
			handle_stream_docid client, DtellaIndexReader.decode_docid($1)
		when /^\/\+([0-9A-Z]+)$/
			handle_stream_tth client, $1
		else
			client.write(Mongrel::Const::ERROR_404_RESPONSE)
		end
	end

	def start_transfer username, filename, offset=0, timeout=10
		srv = nil
		while !srv
			port = 18000 + rand(1000)
			#port = 9020
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
		ensure
			srv.close
		end
		return unless s
		puts "client accepted"
		client = ClientConnection.new "#{username}:#{filename}", s
	
		client.adcget filename, offset
		m = client.readmsg
		p m
		return unless m[:type] == :adcsnd
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

	def handle_stream_docid out, docid
		return write_status out, 404, 'invalid id' unless docid
		data = $index.load docid
		return write_status out, 404, 'nonexistent id' unless data
		tth = data[:tth]
		usernames = data[:locations].map{ |x,_| x }.uniq
		puts "streaming #{docid} = #{tth} from #{usernames * ','}"
		stream out, "TTH/#{tth}", usernames
	end
	
	def handle_stream_tth out, tth
		data = $index.load_by_tth tth
		return write_status out, 404, 'bad tth' unless data
		usernames = data[:locations].map{ |x,_| x }.uniq
		puts "streaming #{tth} from #{usernames * ','}"
		stream out, "TTH/#{tth}", usernames
	end

	def stream out, filename, usernames, offset=0, delay=1
		online = usernames.select { |x| $hub.users.member? x }
		p online
		username = online.shuffle.first
		p username
		return write_status out, 404, 'all peers offline' unless username

		s, len = start_transfer username, filename, offset
		return write_status out, 404, 'remote peer failed to connect' unless s

		begin
			delay = 1
			write_status out, 200, 'OK'
			write_headers out, 'content-type' => 'application/octet-stream'
			write_separator out
			count = transfer_chunk s, out, len
			if count == len
				puts "transfer completed"
			else
				puts "transfer aborted by peer at (#{count}/#{len})"
				sleep delay
				puts "recursing!"
				stream out, filename, usernames, offset+count, delay*2
			end
		rescue => e
			puts "transfer failed: #{e.class} #{e.message}"
		ensure
			s.close unless s.closed?
		end
	end

	def handle_filelist out, username
		stream out, 'files.xml', [username]
	end

	def handle_users out
		write_status out, 200, 'OK'
		write_headers out, 'content-type' => 'text/plain'
		write_separator out
		$hub.users.keys.each { |x| out.puts x }
	end
end

end
