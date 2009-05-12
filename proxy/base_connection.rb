require 'socket'

module DCProxy

class BaseConnection
	attr_reader :s
	attr_reader :logfile

	def initialize name, s
		@s = s
		@name = name
	end

	def write msg
		log.debug "#{@name} > #{msg.inspect}"
		d = "#{msg}|"
		@s.write d
	end

	def read
		msg = @s.gets '|'
		return unless msg
		msg.chomp! '|'
		log.debug "#{@name} < #{msg.inspect}"
		msg
	end

	def expect msg
		l = read
		fail "expected #{msg.inspect}, got #{l.inspect}" unless msg == l
	end

	def disconnect
		@s.close
	end
end

end
