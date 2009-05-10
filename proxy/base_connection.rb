require 'socket'

module DCProxy

class BaseConnection
	attr_reader :s
	attr_reader :logfile

	def initialize name, s
		@s = s
		@name = name
		@logfile = File.open("log/#{name}", "w")
	end

	def write msg
		d = "#{msg}|"
		@s.write d
		@logfile.puts "> #{d.inspect}"
		@logfile.flush
	end

	def read
		msg = @s.gets '|'
		return unless msg
		msg.chomp! '|'
		@logfile.puts "< #{msg.inspect}"
		@logfile.flush
		msg
	end

	def expect msg
		l = read
		fail "expected #{msg.inspect}, got #{l.inspect}" unless msg == l
	end

	def log msg
		@logfile.puts "! #{msg}"
		@logfile.flush
	end

	def disconnect
		@s.close
	end
end

end
