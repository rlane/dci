#!/usr/bin/env ruby
require 'rubygems'
require 'xapian'
require 'common'

DATA_FILENAME = "data-h"
INDEX_FILENAME = "index"

$db = Xapian::WritableDatabase.new(INDEX_FILENAME, Xapian::DB_CREATE_OR_OVERWRITE)
$term_generator = Xapian::TermGenerator.new()
$term_generator.stemmer = Xapian::Stem.new("english")

def index tth, locations, texts, terms, size
	doc = Xapian::Document.new
	doc.add_term mkterm(:tth, tth)
	terms.each { |type,term| doc.add_term mkterm(type,term) }
	usernames = locations.map { |x,_| x }.uniq
	usernames.each { |x| doc.add_term mkterm(:username, x) }
	$term_generator.document = doc
	texts.each { |text| $term_generator.index_text text, 1, PREFIXES[:text] }
	doc.add_value SIZE_VALUENO, size.to_s
	#puts doc.terms.map { |t| t.term }.join(' ')
	doc.data = Marshal.dump({:tth => tth, :locations => locations, :size => size})
	$db.add_document doc
end

data = MarshalledDB.new DATA_FILENAME
n = data.size
i = 0
data.each do |tth,v|
	#puts "indexing #{tth}"
	i += 1
	index tth, v[:locations], v[:texts], v[:terms], v[:size]
	puts "indexed #{i}/#{n}" if (i % 1000) == 0
end
data.close
