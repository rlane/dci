#!/usr/bin/env ruby
require 'rubygems'
require 'rexml/document'
require 'net/http'
include REXML

SERVER_ADDRESS = "localhost"
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

def get_xml(url); REXML::Document.new(Net::HTTP.get_response(URI.parse(url)).body); end

users = get_xml(BASE_URL + "/users")
usernames = []
users.elements.each('users/user/username') { |e| usernames << e.text }

usernames.each do |username|
	filename = FILELIST_DIR + "/#{username}.filelist.xml"
	next if File.exists? filename
	next if BLACKLIST.member? username
	puts "downloading filelist from #{username}"
	begin
		data = get_raw(BASE_URL + "/filelist?username=#{username}")
		fail 'empty file' if data.empty?
		File.open(filename, "w") { |f| f.puts data }
	rescue Exception => e
		puts "download failed: #{e.message}"
		BLACKLIST << username
		sleep 5
	end
end

File.open("blacklist", "w") { |f| BLACKLIST.each { |l| f.puts l } }
