require 'xmpp4r/client'
require 'xmpp4r/roster'
require 'dci'

module DCI::Proxy

class JabberBot
	def initialize username, password
		@username = username
		@client = Jabber::Client::new(Jabber::JID::new(@username))
		@client.connect
		@client.auth(password)
		@client.send(Jabber::Presence.new)
		@roster = Jabber::Roster::Helper.new(@client)
		@z = $index
		@users = SavingHash.new { { :results => [], :offset => 0 } }
		@options = {
			:verbose => false,
			:num_results => 100,
			:page_results => 10,
			:max_locations => 5,
		}
		@result_hashes = {}
		@client.add_message_callback { |m| on_message m }
		@roster.add_subscription_request_callback(0, nil) { |item,pres| on_subscription_request item, pres }
	end

	def legal_user? u
		CFG['users'].member? u.strip.to_s
	end

	def on_subscription_request item, pres
		(log.warn "subscription request from illegal user #{pres.from}"; return) unless legal_user? pres.from
		@roster.accept_subscription(pres.from)
		log.info "accepted subscription request from #{pres.from}"
	end

	def tx to, body
		m = Jabber::Message::new(to, body)
		m.type = :chat
		@client.send m
	end

	def on_message m
		begin
			return if m.body.nil?
			log.info "got message from #{m.from}: #{m.body.inspect}"
			(log.warn "message from illegal user #{m.from}"; return) unless legal_user? m.from
			cmd, arg = m.body.split(nil, 2)
			cmd ||= ""
			arg ||= ""
			case cmd
			when 'explain', 'e'
				cmd_explain m.from, arg
			when 'query', 'q'
				cmd_query m.from, arg
			when 'query_online', 'qo'
				cmd_query_online m.from, arg
			when 'current_page', 'c'
				cmd_current_page m.from
			when 'next_page', 'n'
				cmd_next_page m.from
			when 'previous_page', 'p'
				cmd_previous_page m.from
			when 'link', 'l'
				cmd_link m.from, arg
			when 'info', 'i'
				cmd_info m.from, arg
			when 'download', 'd'
				cmd_download m.from, arg
			when 'download_remove', 'dr'
				cmd_download_remove m.from, arg
			when 'download_status', 'ds'
				cmd_download_status m.from, arg
			when 'help', 'h', '?'
				cmd_help m.from, arg
			else
				tx m.from, "Invalid command #{cmd.inspect}; type 'help' if you need it."
			end
		rescue => e
			log.error "Jabber bot got exception #{e.message} processing #{m.inspect}"
		end
	end

	def cmd_explain from, query_string
		q = @z.parse_query query_string
		tx from, q.description
	end

	def query from, q
		ms, estimate = @z.query q, 0, @options[:num_results]
		@users[from][:offset] = 0
		@users[from][:results] = ms
		@users[from][:estimate] = estimate
		true
	end

	def cmd_query from, query_string
		q = @z.parse_query query_string
		query from, q
		send_results from
	end

	Q = Xapian::Query
	def cmd_query_online from, query_string
		q = @z.parse_query query_string
		q = Q.new(Q::OP_FILTER, q, Q.new(Q::OP_OR, $hub.users.keys.map{|x| DCI::Index.mkterm(:username, x)}))
		query from, q
		send_results from
	end

	def send_results from
		ms = @users[from][:results]
		offset = @users[from][:offset]
		estimate = @users[from][:estimate]
		ms = ms[offset...(offset+@options[:page_results])]
		if !ms || ms.empty?
			tx from, "No results found."
		else
			tx from, "Results #{offset+1} - #{offset+ms.size} of #{estimate}:"
			ms.each do |m|
				result_id = m[:rank].to_i + 1
				@result_hashes["#{from}\000#{result_id}"] = m[:tth]
				usernames = m[:locations].map{|x,_| x}.sort
				#online_usernames = usernames.select{|x| $hub.users.member? x}
				users_str = usernames.map{|x| ($hub.users.member?(x) ? '+' : '') + x}.uniq * ', '
				filename = File.basename m[:locations].first[1]
				tx from, "#{result_id}: #{filename} (#{users_str})"
			end
		end
	end

	def cmd_current_page from
		send_results from
	end

	def cmd_next_page from
		new_offset = @users[from][:offset] + @options[:page_results]
		if new_offset < @users[from][:results].size
			@users[from][:offset] = new_offset
			send_results from
		else
			tx from, "No more results"
		end
	end

	def cmd_previous_page from
		new_offset = @users[from][:offset] - @options[:page_results]
		if new_offset >= 0
			@users[from][:offset] = new_offset
			send_results from
		else
			tx from, "No more results"
		end
	end

	def cmd_link from, result_id
		tth = get_tth from, result_id
		if !tth
			tx from, "invalid result id"
			return
		end
		ms, e = @z.query Xapian::Query.new(DCI::Index.mkterm(:tth, tth)), 0, 1
		if ms.empty?
			tx from, "result not found in index"
			return
		end
		m = ms[0]
		usernames = m[:locations].map{|x,_| x}.sort
		online_usernames = usernames.select{|x| $hub.users.member? x}
		encoded_docid = DCI::Index.encode_docid m[:docid]
		tx from, "(#{online_usernames.size}/#{usernames.size}) " + BASE_URL + "/=#{encoded_docid}"
	end

	def cmd_info from, result_id
		tth = get_tth from, result_id
		if !tth
			tx from, "invalid result id"
			return
		end
		tx from, "TTH: #{tth}"
		ms, e = @z.query Xapian::Query.new(DCI::Index.mkterm(:tth, tth)), 0, 1
		if ms.empty?
			tx from, "result not found in index"
			return
		end
		m = ms[0]
		tx from, "Size: #{m[:size]}"
		#tx from, "Users: #{m[:locations].map{ |x,_| ($hub.users.member?(x) ? '+' : '') + x}.uniq * ', '}"
		m[:locations][0...20].each do |username,path|
			tx from, "#{$hub.users.member?(username) ? '+' : ' '}#{username}:#{path}"
		end
		encoded_docid = DCI::Index.encode_docid m[:docid]
		tx from, "Link: " + BASE_URL + "/=#{encoded_docid}"
	end

	def cmd_download from, result_id
		tth = get_tth from, result_id
		if !tth
			tx from, "invalid result id"
			return
		end
		tx from, "TTH: #{tth}"
		$downloader.enqueue tth, from
		tx from, "download added to queue"
	end

	def cmd_download_remove from, result_id
		tth = get_tth from, result_id
		if !tth
			tx from, "invalid result id"
			return
		end
		$downloader.unenqueue tth, from
		tx from, "download removed from queue"
	end

	def cmd_download_status from, arg
	end

	def cb_download_complete from, tth
		tx from, "download of #{tth} complete"
	end

	def cb_download_failed from, tth, msg
		tx from, "download of #{tth} failed: #{msg}"
	end

	def cmd_help from, arg
		helpmsg = <<-EOS
Commands:
  q[uery] query_string: Search for a file matching the given query string.
  query_online (qo): Same as query, but only show results that have an online source.
  n[ext_page]: Show next page of search results
  p[revious_page]: Show previous page of search results
  l[ink] result_id: Given a result id from the output of query, output an HTTP url to the file.
  i[nfo] result_id: Show more details about a search result.
  e[xplain] query_string: Display description of the parsed query string.
EOS
		tx from, helpmsg
	end

	def get_tth from, x
		case x
		when /^(\d+)$/ #result id
			@result_hashes["#{from}\000#{$1}"]
		when /^([A-Z0-9]{39,39})$/ #TTH
			$1
		when /^=([A-Za-z0-9\/\+]{6,6})$/ #encoded docid
			$index.load(DCI::Index.decode_docid $1)[:tth]
		else
			nil
		end
	end
end

end
