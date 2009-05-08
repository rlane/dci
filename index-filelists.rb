#!/usr/bin/env ruby
require 'rubygems'
require 'rexml/document'
require 'common'

FILELISTS_DIR = "filelists"
DATA_FILENAME = "data"

#filelists = Dir.glob(FILELISTS_DIR + "/*")
filelists = %w(zzazzors).map { |x| FILELISTS_DIR + "/" + x + ".filelist.xml" }

def process_directory node, username, ancestor_names
	return unless node
	node.elements.each do |e|
		as = e.attributes
		path = ancestor_names + [as['Name']]
		if e.name == 'File'
			#puts "File " + as['Name']
			tth = as['TTH']
			fs_path = path * '/'
			text_path = path * ' '
			size = as['Size'].to_i
			x = $index[tth] || { :locations => [], :terms => [], :texts => [], :size => nil }
			x[:locations] << [username, fs_path]
			x[:texts] += [text_path]
			x[:size] = size
			$index[tth] = x
		elsif e.name == 'Directory'
			#puts "Directory " + as['Name']
			process_directory e, username, path
		else
			puts "Unknown node type #{e.name}"
		end
	end
end

$index = MarshalledGDBM.new DATA_FILENAME

filelists.each do |filelist|
	fail 'bad filename' unless filelist =~ /^#{FILELISTS_DIR}\/(.*).filelist.xml/
	username = $1
	File.open(filelist, "r") do |f|
		puts "reading #{filelist}"
		xml = REXML::Document.new(f.read)
		next if xml.nil?
		puts "processing #{filelist}"
		process_directory xml.root, username, []
	end
end
