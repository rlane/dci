require 'pp'

module DCI::Proxy::Console
	def debug!; $logger.level = Logger::DEBUG; end
	def info!; $logger.level = Logger::INFO; end
	def warn!; $logger.level = Logger::WARN; end
	def error!; $logger.level = Logger::ERROR; end
	def fatal!; $logger.level = Logger::FATAL; end

	def who
		$hub.who
	end

	def who_
		who * ' '
	end

	def privmsg *a
		$hub.privmsg(*a)
	end

	def get x
		case x
		when Integer #docid
			$index.load x
		when /^[A-Z0-9]{39,39}$/ #TTH
			$index.load_by_tth x
		when /^[A-Za-z0-9\/\+]{6,6}$/ #encoded docid
			$index.load(DCI::Index.decode_docid encoded_docid)
		else
			puts "invalid argument"
		end
	end

	def inspect x
		pp(get(x) || return)
	end

	def link x, type=:tth
		data = get(x) || return
		case type
		when :tth
			DCI::Proxy::BASE_URL + "/+#{data[:tth]}"
		when :docid
			DCI::Proxy::BASE_URL + "/=#{DCI::Index.encode_docid data[:docid]}"
		else
			puts "invalid type"
		end
	end
end
