#!/usr/bin/env ruby
require 'rubygems'
require 'rexml/document'
require 'net/http'
include REXML

SERVER_ADDRESS = "localhost"
SERVER_PORT = 8314
BASE_URL = "http://#{SERVER_ADDRESS}:#{SERVER_PORT}"
BLACKLIST = File.open("blacklist").readlines.map { |l| l.chomp }

def get_raw(url); Net::HTTP.get_response(URI.parse(url)).body; end
def get_xml(url); REXML::Document.new(Net::HTTP.get_response(URI.parse(url)).body); end

users = get_xml(BASE_URL + "/users")
usernames = []
users.elements.each('users/user/username') { |e| usernames << e.text }

usernames.each do |username|
	filename = "#{username}.filelist.xml"
	next if File.exists? filename
	next if BLACKLIST.member? username
	puts "downloading filelist from #{username}"
	begin
		data = get_raw(BASE_URL + "/filelist?username=#{username}")
		File.open(filename, "w") { |f| f.puts data }
	rescue Exception => e
		puts "download failed: #{e.message}"
		BLACKLIST << username
		sleep 5
	end
end

File.open("blacklist", "w") { |f| BLACKLIST.each { |l| f.puts l } }
