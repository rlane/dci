require 'socket'

module DCI::Proxy

class BaseConnection
	attr_reader :s
	attr_reader :logfile

	def initialize name, s
		@s = s
		@name = name
	end

	def run
		while (m = readmsg)
			begin
				process m
			rescue => e
				log.error "exception processing message #{m.inspect}: #{e.message}"
			end
		end
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

	def readmsg
		DCI::ProtocolParser.parse_message read
	end

	def expect h
		m = readmsg or fail "expected #{h.inspect}, got nil"
		h.each { |k,v| fail "expected #{h.inspect}, got #{m.inspect}" unless m[k] == v }
		m
	end

	def disconnect
		@s.close
	end
end

end
