require 'proxy/transfer'

module DCProxy

class Download
	attr_reader :tth, :usernames

	def initialize tth, usernames
		@tth = tth
		@usernames = usernames
	end
end

class Downloader
	include Transfer

	def initialize
		@lock = Mutex.new
		@queue = Queue.new
		@downloads = {}
	end

	def enqueue tth, username
		@lock.synchronize do
			if @downloads.member? tth
				@downloads[tth].usernames << username
			else
				@downloads[tth] = Download.new tth, [username]
				@queue << tth
			end
		end
	end

	def unenqueue tth, username
		@lock.synchronize do
			if @downloads.member? tth
				@downloads[tth].usernames.delete username
				if @queue.member?(tth) and @downloads[tth].usernames.empty?
					@queue.remove tth
					@downloads.remove tth
				end
			end
		end
	end

	def run
		while true
			tth = @queue.pop
			dl = @downloads[tth]
			puts "downloading #{tth} for #{dl.usernames}"
			begin
				download tth
				puts "finished #{tth}"
				dl.usernames.each { |x| $bot.cb_download_complete x, tth }
			rescue => e
				puts "failed to download #{tth}: #{e.message}"
				dl.usernames.each { |x| $bot.cb_download_failed x, tth, e.message }
			end
		end
	end

	def download tth
		data = $index.load_by_tth(tth) or fail 'invalid TTH'
		filename = "TTH/#{tth}"
		offset = 0
		size = data[:size]
		usernames = data[:locations].map{ |x,_| x }.uniq
		cache_id = 'tth:' + tth
		cache_fn = 'downloads/' + cache_id
		begin
			out = File.open(cache_fn, 'w')
			while offset < size
				s, len = nil, nil
				while !s
					s, len = connect_to_peer usernames, filename, offset
					sleep 10 unless s
				end
				n = transfer_chunk s, out, len
				offset += n
				puts "transfer aborted by peer at (#{offset}/#{size}), trying to resume" unless offset == size
			end
		rescue => e
			puts "transfer failed: #{e.class} #{e.message}"
			File.delete cache_fn
		ensure
			s.close unless !s || s.closed?
			out.close unless !out || out.closed?
		end
	end
end

end
