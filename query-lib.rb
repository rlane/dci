require 'xapian'
require 'common'

class DtellaIndexReader
	def initialize filename
		@db = Xapian::Database.new(filename)
		@enquire = Xapian::Enquire.new(@db)
		@qp = Xapian::QueryParser.new()
		NORMAL_PREFIXES.each { |k,v| @qp.add_prefix k.to_s, v }
		BOOLEAN_PREFIXES.each { |k,v| @qp.add_boolean_prefix k.to_s, v }
		@stemmer = Xapian::Stem.new("english")
		@qp.stemmer = @stemmer
		@qp.database = @db
		@qp.stemming_strategy = Xapian::QueryParser::STEM_SOME
		@qp.default_op = Xapian::Query::OP_AND
	end

	def parse_query query_string
		@qp.parse_query(query_string, Xapian::QueryParser::FLAG_PHRASE|Xapian::QueryParser::FLAG_BOOLEAN|Xapian::QueryParser::FLAG_LOVEHATE, PREFIXES[:text])
	end

	def query q, offset, count
		@enquire.query = q
		matchset = @enquire.mset(offset, count)
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
