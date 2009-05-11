#!/usr/bin/env ruby
require 'rubygems'
require 'query-lib'
require 'common'
require 'optparse'
require 'pp'

INDEX_FILENAME = "index"

z = DtellaIndexReader.new INDEX_FILENAME

cmd, *args = *ARGV
data = case cmd
when 'docid', 'd'
	docid = (args[0] && args[0].to_i) or fail 'docid argument required'
	z.load docid
when 'encoded_docid', 'e'
	encoded_docid = args[0] or fail 'encoded docid argument required'
	docid = DtellaIndexReader.decode_docid encoded_docid
	fail 'invalid docid' unless docid
	z.load docid
when 'tth', 'h'
	tth = args[0] or fail 'tth argument required'
	z.load_by_tth tth
else
	puts "unknown command #{cmd.inspect}"
	exit 1
end

pp data
