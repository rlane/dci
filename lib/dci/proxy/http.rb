require 'mongrel'
require 'timeout'

module DCI::Proxy

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
			log.warn "HTTP parse error, malformed request (#{params[Mongrel::Const::HTTP_X_FORWARDED_FOR] || client.peeraddr.last}): #{e.inspect}"
			log.warn "REQUEST DATA: #{data.inspect}\n---\nPARAMS: #{params.inspect}\n---\n"
		rescue Object => e
			log.warn "Read error: #{e.inspect}"
			log.warn e.backtrace.join("\n")
		ensure
			begin
				client.close
			rescue IOError
				# Already closed
			rescue Object => e
				log.warn "Client error: #{e.inspect}"
				log.warn e.backtrace.join("\n")
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
	include Transfer

	def parse_args params
		Mongrel::HttpRequest.query_parse params['QUERY_STRING']
	end

	def handle_request client, params
		log.info "handling #{params['REQUEST_PATH'].inspect}"
		case params['REQUEST_PATH']
		when '/filelist'
			args = parse_args params
			username = args['username']
			fail unless username
			handle_filelist client, username
		when '/users'
			handle_users client
		when /^\/=([\w\d\/\+]+)$/
			handle_stream_docid client, DCI::Index.decode_docid($1)
		when /^\/\+([0-9A-Z]+)$/
			handle_stream_tth client, $1
		when /^\/\+(.*):([0-9A-Z]+)$/
			handle_stream_manual client, $1, $2
		else
			client.write(Mongrel::Const::ERROR_404_RESPONSE)
		end
	end

	def handle_stream_docid out, docid
		return write_status out, 404, 'invalid id' unless docid
		data = $index.load docid
		return write_status out, 404, 'nonexistent id' unless data
		tth = data[:tth]
		usernames = data[:locations].map{ |x,_| x }.uniq
		mimetype = data[:mimetype] || 'application/octet-stream'
		offset = 0
		length = data[:size]
		log.info "streaming #{docid} = #{tth} from #{usernames * ','}"
		stream out, "TTH/#{tth}", usernames, mimetype, "tth:#{tth}", offset, length
	end
	
	def handle_stream_tth out, tth
		data = $index.load_by_tth tth
		return write_status out, 404, 'bad tth' unless data
		usernames = data[:locations].map{ |x,_| x }.uniq
		mimetype = data[:mimetype] || 'application/octet-stream'
		offset = 0
		length = data[:size]
		log.info "streaming #{tth} from #{usernames * ','}"
		stream out, "TTH/#{tth}", usernames, mimetype, "tth:#{tth}", offset, length
	end

	def handle_stream_manual out, username, tth
		mimetype = 'application/octet-stream'
		offset = 0
		length = nil
		log.info "manually streaming #{tth} from #{username}"
		stream out, "TTH/#{tth}", [username], mimetype, "tth:#{tth}", offset, length
	end

	def stream out, filename, usernames, mimetype='application/octet-stream', cache_id=nil, offset=0, length=nil
		stream_internal out, filename, usernames, cache_id, offset, length do |status|
			case status
			when :unavailable
				write_status out, 404, 'all peers unavailable'
			when :started
				write_status out, 200, 'OK'
				write_headers out, 'content-type' => mimetype
				write_headers out, 'content-length' => length if length
				write_separator out
			end
		end
	end

	def stream_internal out, filename, usernames, cache_id, offset, length
		delay = 1

		cache_fn = CFG['cache_dir'] + '/' + cache_id if cache_id
		log.info "cache filename: #{cache_fn}"
		s, len = if cache_id && File.exists?(cache_fn)
			[File.open(cache_fn, "r"), File.size(cache_fn)]
		else
			connect_to_peer usernames, filename, offset
		end
		return yield :unavailable unless s
		length = len unless length

		begin
			yield :started
			while offset < length
				n = transfer_chunk s, out, (length-offset)
				if n > 0
					offset += n
				else
					log.warn "transfer aborted by peer at (#{offset}/#{length}), trying to failover"
					yield :peer_aborted
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
			s.close unless s.closed?
		end
	end

	def handle_filelist out, username
		stream out, 'files.xml', [username], 'text/xml'
	end

	def handle_users out
		write_status out, 200, 'OK'
		write_headers out, 'content-type' => 'text/plain'
		write_separator out
		$hub.users.keys.each { |x| out.puts x }
	end
end

end
