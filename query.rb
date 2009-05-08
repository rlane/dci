#!/usr/bin/env ruby
require 'rubygems'
require 'xapian'
require 'common'
require 'optparse'

INDEX_FILENAME = "index"

options = {
	:verbose => false,
	:num_results => 10,
	:num_locations => 5,
}
OptionParser.new do |opts|
	opts.banner = "Usage: query.rb [options] query"
	opts.on("-v", "--[no-]verbose", "Run verbosely") { |v| options[:verbose] = v }
	opts.on("-n", "--num-results NUM", Integer, "Limit results returned to NUM") { |v| options[:num_results] = v }
	opts.on("-l", "--num-locations NUM", Integer, "Limit locations returned per result to NUM") { |v| options[:num_locations] = v }
end.parse!

queryString = ARGV[0]
(puts "You must specify a query"; exit 1) unless queryString

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

puts "parsed query: #{query.description}" if options[:verbose]

enquire.query = query
matchset = enquire.mset(0, options[:num_results])

if matchset.size == 0
	puts "No results found."
	exit 1
end

puts "Results 1 - #{matchset.size} of #{matchset.matches_estimated}:"

matchset.matches.each do |m|
	data = Marshal.load(m.document.data)
  puts "#{m.rank + 1}: #{m.percent}% #{data[:tth]}"
	data[:locations][0...options[:num_locations]].each do |username,path|
		puts "  #{username}:/#{path}"
	end
	puts "  + #{data[:locations].size - options[:num_locations]} more" if data[:locations].size > options[:num_locations]
end
