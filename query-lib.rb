require 'xapian'
require 'common'

class DtellaIndexReader
	QP = Xapian::QueryParser
	QUERY_PARSER_FLAGS = 
	 QP::FLAG_PHRASE |
	 QP::FLAG_BOOLEAN |
	 QP::FLAG_LOVEHATE |
	 QP::FLAG_WILDCARD
	def initialize filename
		@db = Xapian::Database.new(filename)
		@qp = Xapian::QueryParser.new()
		NORMAL_PREFIXES.each { |k,v| @qp.add_prefix k.to_s, v }
		BOOLEAN_PREFIXES.each { |k,v| @qp.add_boolean_prefix k.to_s, v }
		@stemmer = Xapian::Stem.new("english")
		@qp.stemmer = @stemmer
		@qp.database = @db
		@qp.stemming_strategy = Xapian::QueryParser::STEM_SOME
		@qp.default_op = Xapian::Query::OP_AND
	end

	def self.encode_docid x
		[[x].pack('N')].pack('m')[0...-3] rescue nil
	end

	def self.decode_docid s
		(s + "==\n").unpack('m')[0].unpack('N')[0] rescue nil
	end

	def load docid
		doc = @db.document(docid) rescue (return nil)
		Marshal.load(doc.data)
	end

	def load_by_tth tth
		ms, e = query Xapian::Query.new(mkterm(:tth, tth)), 0, 1
		ms.first
	end

	def parse_query query_string
		@qp.parse_query(query_string, QUERY_PARSER_FLAGS, PREFIXES[:text])
	end

	def query q, offset, count
		enquire = Xapian::Enquire.new(@db)
		enquire.query = q
		matchset = enquire.mset(offset, count)
		results = []
		matchset.matches.each do |m|
			result = Marshal.load(m.document.data)
			result[:rank] = m.rank
			result[:percent] = m.percent
			results << result
		end
		[results, matchset.matches_estimated]
	end
end
