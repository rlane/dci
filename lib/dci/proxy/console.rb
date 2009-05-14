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

	def searches
		$search_logger.load_entries
	end

	def peers
		$client_logger.load_entries
	end

	def ip_peers
		SavingHash.new { [] }.tap { |h| peers.each { |x| h[x[:ip]] << x[:nick] } }
	end

	def peer_searches hide_tth=false
		a = ip_peers
		b = SavingHash.new { [] }
		searches.each do |x|
			nicks = a[x[:ip]]
			nicks.each do |nick|
				s = x[:pattern].gsub('$', ' ')
				b[nick] << s if (!hide_tth || !s.start_with?('TTH:')) && (!block_given? || (yield nick, s))
			end
		end
		b
	end

	def search_peers hide_tth=false
		SavingHash.new { [] }.tap { |h| peer_searches(hide_tth).each { |k,vs| vs.each { |v| v.split.each { |w| r[w] << k } } } }
	end

	def reload
		old_verbose = $VERBOSE
		$VERBOSE = nil
		fs = $".grep(/^dci\//)
		fs.each { |f| $".delete f }
		fs.each { |f| require f }
		$VERBOSE = old_verbose
		true
	end
end
