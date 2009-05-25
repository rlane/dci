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
			$index.load(DCI::Index.decode_docid x)
		else
			puts "invalid argument"
		end
	end

	def i x
		pp(get(x) || return)
	end

	def mkquery q
		case q
		when String
			$index.parse_query q
		when Q
			q
		else
			fail "invalid query"
		end
	end

	Q = Xapian::Query
	def query q, options={}
		options = {
			:verbose => false,
			:offset => 0,
			:count => 10,
			:max_locations => 5,
		}.merge options

		q = mkquery q
		ms, estimate = $index.query q, options[:offset], options[:count]

		if ms.empty?
			puts "No results found."
			return false
		end

		puts "Results 1 - #{ms.size} of #{estimate}:"

		ms.each do |m|
			puts "#{m[:rank] + 1}: #{m[:percent]}% #{m[:tth]}"
			m[:locations][0...options[:max_locations]].each do |username,path|
				puts "  #{username}:/#{path}"
			end
			puts "  + #{m[:locations].size - options[:max_locations]} more" if m[:locations].size > options[:max_locations]
		end
		true
	end
	alias q query

	def query_online q, options={}
		q = mkquery q
		q = Q.new(Q::OP_FILTER, q, Q.new(Q::OP_OR, $hub.users.keys.map{|x| DCI::Index.mkterm(:username, x)}))
		query q, options
	end
	alias qo query_online

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
		old_features = $".dup
		begin
			fs = $".grep(/^dci\//)
			fs.each { |f| $".delete f }
			fs.each do |f|
				begin
					require f
				rescue LoadError => e
					raise unless e.message =~ /no such file to load/
				end
			end
		rescue Exception => e
			$".clear
			$".concat old_features
		ensure
			$VERBOSE = old_verbose
		end
		true
	end

	def shared_size
		(1..$index.db.doccount).inject(0) { |total,i| total + $index.load(i)[:size] }
	end

	def shared_size_tb
		shared_size / (2.0**40)
	end
end
