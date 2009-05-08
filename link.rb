#!/usr/bin/env ruby
require 'rubygems'
require 'xapian'
require 'common'

INDEX_FILENAME = "index"
SERVER_ADDRESS = "localhost"
SERVER_PORT = 8314
BASE_URL = "http://#{SERVER_ADDRESS}:#{SERVER_PORT}"

tth = ARGV[0] || fail('TTH argument required')

$db = Xapian::Database.new(INDEX_FILENAME)
enquire = Xapian::Enquire.new($db)
Q = Xapian::Query
query = Q.new(mkterm(:tth, tth))
enquire.query = query
matchset = enquire.mset(0, 1)
fail 'TTH not found in index' if matchset.size == 0
m = matchset.matches[0]
data = Marshal.load(m.document.data)
tth = data[:tth]
data[:locations].each do |username,path|
	puts BASE_URL + "/file?username=#{username}&tth=#{tth}"
end
