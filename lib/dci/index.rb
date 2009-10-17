require 'xapian'

class DCI::Index
	attr_reader :db

	NORMAL_PREFIXES = {
		:text => 'B',
	}

	BOOLEAN_PREFIXES = {
		:type => 'T',
		:username => 'U',
		:tth => 'H',
		:extension => 'E',
	}

	PREFIXES = NORMAL_PREFIXES.merge BOOLEAN_PREFIXES

	TTH_VALUENO = 0
	SIZE_VALUENO = 1

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
		make_result docid
	end

	def load_by_tth tth
		ms, e = query Xapian::Query.new(klass.mkterm(:tth, tth)), 0, 1
		ms.first
	end

	def parse_query query_string
		@qp.parse_query(query_string, QUERY_PARSER_FLAGS, PREFIXES[:text])
	end

	def query q, offset, count
		enquire = Xapian::Enquire.new(@db)
		enquire.collapse_key = TTH_VALUENO
		enquire.query = q
		matchset = enquire.mset(offset, count)
		results = []
		matchset.matches.each do |m|
			result = make_result m.docid
			result[:rank] = m.rank
			result[:percent] = m.percent
			results << result
		end
		[results, matchset.matches_estimated]
	end

	def self.mkterm(type, value)
		prefix = PREFIXES[type] or raise "Invalid term type #{type.inspect}"
		"#{prefix}#{value}"
	end

	def reopen
		@db.reopen
	end

#private

	def make_result docid
		hit_doc = @db.document(docid)
		hit_data = Marshal.load hit_doc.data
		tth = hit_data[:tth]
		doc_datas = @db.postlist(self.class.mkterm(:tth,tth)).map { |x| @db.document x.docid }.map { |doc| Marshal.load doc.data }
		{
			:docid => docid,
			:tth => tth,
			:locations => doc_datas.map { |data| data[:location] },
			:size => hit_data[:size],
			:mimetype => hit_data[:mimetype],
		}
	end
end
