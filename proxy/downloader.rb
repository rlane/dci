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
		usernames = data[:locations].map{ |x,_| x }.uniq
		delay = 1
		s, len = connect_to_peer usernames, filename, offset
		fail 'all peers unavailable' unless s
		cache_id = 'tth:' + tth
		cache_fn = 'downloads/' + cache_id
		out = File.open(cache_fn, 'w')
		begin
			while offset < len
				n = transfer_chunk s, out, len
				if n
					offset += n
				else
					puts "transfer aborted by peer at (#{offset}/#{len}), trying to resume"
					while !s
						raise 'max retries exceeded' if delay > 2**5
						sleep delay
						delay *= 2
						s, len = connect_to_peer usernames, filename, offset
					end
					delay = 1
				end
			end
		rescue => e
			puts "transfer failed: #{e.class} #{e.message}"
		ensure
			s.close unless s.closed?
			out.close unless out.closed?
		end
	end
end

end
