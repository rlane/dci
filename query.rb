#!/usr/bin/env ruby
require 'rubygems'
require 'query-lib'
require 'common'
require 'optparse'

INDEX_FILENAME = "index"

options = {
	:verbose => false,
	:offset => 0,
	:count => 10,
	:max_locations => 5,
}

OptionParser.new do |opts|
	opts.banner = "Usage: query.rb [options] query"
	opts.on("-v", "--[no-]verbose", "Run verbosely") { |v| options[:verbose] = v }
	opts.on("-o", "--offset NUM", Integer, "Start results returned at NUM") { |v| options[:offset] = v }
	opts.on("-c", "--count NUM", Integer, "Limit results returned to NUM") { |v| options[:count] = v }
	opts.on("-l", "--max-locations NUM", Integer, "Limit locations returned per result to NUM") { |v| options[:max_locations] = v }
end.parse!

(puts "You must specify a query"; exit 1) if ARGV.empty?
queryString = ARGV * ' '

z = DtellaIndexReader.new INDEX_FILENAME
q = z.parse_query queryString

puts "parsed query: #{q.description}" if options[:verbose]

ms, estimate = z.query q, options[:offset], options[:count]

if ms.empty?
	puts "No results found."
	exit 1
end

puts "Results 1 - #{ms.size} of #{estimate}:"

ms.each do |m|
  puts "#{m[:rank] + 1}: #{m[:percent]}% #{m[:tth]}"
	m[:locations][0...options[:max_locations]].each do |username,path|
		puts "  #{username}:/#{path}"
	end
	puts "  + #{m[:locations].size - options[:max_locations]} more" if m[:locations].size > options[:max_locations]
end
