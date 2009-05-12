require 'asami/key_generator'
require 'asami/client_parser'
require 'proxy/base_connection'

module DCProxy

class ClientConnection < BaseConnection
	BUFFER_SIZE = 32 * 1024

	def initialize name, s
		super
		write "$MyNick #{DC_USERNAME}"
		lock = "EXTENDEDPROTOCOL" + "abcd" * 6
		pk = "df23" * 4
		write "$Lock #{lock} Pk=#{pk}"
		write "$Supports MiniSlots XmlBZList ADCGet TTHL TTHF GetZBlock ZLIG "
		write '$Direction Download 100000'
		p readmsg #MyNick
		m = readmsg #Lock
		p m
		write "$Key #{m[:key]}"

		p readmsg #Supports
		p readmsg #Direction
		p readmsg #Key
		log.info "client connection initialized"
	end

	def adcget filename, offset = 0, length = -1
		write "$ADCGET file #{filename} #{offset} #{length}"
	end

	def download filename, io
		adcget filename
		m = readmsg
		p m
		raise 'error' unless m[:type] == :adcsnd
		count = 0
		while d = s.readpartial(BUFFER_SIZE)
			count += d.size
			log.debug "read #{d.size} (#{count}/#{m[:length]})"
			io.write d
			break if count >= m[:length]
		end
	end

	def readmsg
		ClientParser.parse_message read
	end
end

end
