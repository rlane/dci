#!/usr/bin/env ruby
require 'rubygems'
require 'xapian'
require 'common'

INDEX_FILENAME = "index"
MAX_RESULTS = 10

queryString = ARGV[0] || ""

$db = Xapian::Database.new(INDEX_FILENAME)
enquire = Xapian::Enquire.new($db)
qp = Xapian::QueryParser.new()
NORMAL_PREFIXES.each { |k,v| qp.add_prefix k.to_s, v }
BOOLEAN_PREFIXES.each { |k,v| qp.add_boolean_prefix k.to_s, v }
stemmer = Xapian::Stem.new("english")
qp.stemmer = stemmer
qp.database = $db
qp.stemming_strategy = Xapian::QueryParser::STEM_SOME
qp.default_op = Xapian::Query::OP_AND
query = qp.parse_query(queryString, Xapian::QueryParser::FLAG_PHRASE|Xapian::QueryParser::FLAG_BOOLEAN|Xapian::QueryParser::FLAG_LOVEHATE, PREFIXES[:text])

puts "Parsed query is: #{query.description()}"

enquire.query = query
matchset = enquire.mset(0, MAX_RESULTS)

puts "#{matchset.matches_estimated()} results found."
puts "Matches 1-#{matchset.size}:"
puts

matchset.matches.each do |m|
	data = Marshal.load(m.document.data)
  puts "#{m.rank + 1}: #{m.percent}% #{m.docid} #{data[:tth]}"
	data[:locations].each do |username,path|
		puts "  #{username} #{path}"
	end
end
