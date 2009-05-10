require 'mongrel'

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
		when '/file'
			args = parse_args params
			tth = args['tth']
			username = args['username']
			fail unless args and username
			handle_file client, username, tth
		when '/filelist'
			args = parse_args params
			username = args['username']
			fail unless username
			handle_filelist client, username
		when '/users'
			handle_users client
		else
			client.write(Mongrel::Const::ERROR_404_RESPONSE)
		end
	end

	def handle_file out, username, tth
		#port = 18000 + rand(1000)
		port = 9020
		puts "downloading #{username}:#{tth} at #{port}"
		srv = TCPServer.new port
		$hub.connect_to_me username, port
		puts "accepting client connection..."
		s = srv.accept
		srv.close
		puts "client accepted"
		client = ClientConnection.new "#{username}:#{tth}", s
		client.adcget "TTH/#{tth}"
		m = client.readmsg
		p m
		raise 'error' unless m[:type] == :adcsnd

		write_status out, 200, 'OK'
		write_headers out, 'content-type' => 'application/octet-stream'
		write_separator out

		count = 0
		while d = s.readpartial(BUFFER_SIZE)
			count += d.size
			puts "read #{d.size} (#{count}/#{m[:length]})"
			out.write d
			break if count >= m[:length]
		end

		puts "download complete"
		client.disconnect
	end

	def handle_filelist out, username
		write_status out, 200, 'OK'
		write_headers out, 'content-type' => 'text/plain'
		write_separator out
		out.write 'filelist goes here'
	end

	def handle_users out
		write_status out, 200, 'OK'
		write_headers out, 'content-type' => 'text/plain'
		write_separator out
		$hub.users.keys.each { |x| out.puts x }
	end
end

end
