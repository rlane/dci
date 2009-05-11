#!/usr/bin/env ruby
require 'rubygems'
require 'rexml/document'
require 'net/http'
require 'cgi'
include REXML

SERVER_ADDRESS = ARGV[0] || "localhost"
SERVER_PORT = 8314
BASE_URL = "http://#{SERVER_ADDRESS}:#{SERVER_PORT}"
BLACKLIST = File.open("blacklist").readlines.map { |l| l.chomp }
FILELIST_DIR = "filelists"

def get_raw(url)
	r = Net::HTTP.get_response(URI.parse(url))
	if r.is_a? Net::HTTPSuccess
		r.body
	else
		raise r.message
	end
end

usernames = nil
if false
	def get_xml(url); REXML::Document.new(Net::HTTP.get_response(URI.parse(url)).body); end
	users = get_xml(BASE_URL + "/users")
	usernames = []
	users.elements.each('users/user/username') { |e| usernames << e.text }
else
	usernames = get_raw(BASE_URL + "/users").split
end

usernames.each do |username|
	filename = FILELIST_DIR + "/#{username.gsub '/', '_'}.filelist.xml"
	next if File.exists? filename
	next if BLACKLIST.member? username
	next if username == ''
	next if username.index('~') == 0
	next if username.index('*') == 0
	puts "downloading filelist from #{username}"
	begin
		data = get_raw(BASE_URL + "/filelist?username=#{CGI.escape username}")
		fail 'empty file' if data.empty?
		File.open(filename, "w") { |f| f.puts data }
	rescue Exception => e
		puts "download failed: #{e.message}"
		BLACKLIST << username
		sleep 2
	end
end

File.open("blacklist", "w") { |f| BLACKLIST.each { |l| f.puts l } }
