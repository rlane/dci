#!/usr/bin/env ruby
require 'rubygems'
require 'libxml'
require 'common'
include LibXML

FILELISTS_DIR = "filelists"
DATA_FILENAME = "data"
OPTIMIZE = false

filelists = Dir.glob(FILELISTS_DIR + "/*")
#filelists = %w(zzazzors).map { |x| FILELISTS_DIR + "/" + x + ".filelist.xml" }

def process_file tth, username, path, size
	fs_path = path * '/'
	text_path = path * ' '
	x = $index[tth] || { :locations => [], :terms => [], :texts => [], :size => nil }
	x[:locations] << [username, fs_path]
	x[:texts] += [text_path]
	x[:size] = size
	$index[tth] = x
end

R = XML::Reader
def process_filelist xml, username
	path = []
	while (xml.read == 1)
		name, node_type = xml.name, xml.node_type
		if name == 'File' && node_type == R::TYPE_ELEMENT
			path.push xml['Name']
			process_file xml['TTH'], username, path, xml['Size'].to_i
			path.pop
		elsif name == 'Directory' && node_type == R::TYPE_ELEMENT
			path.push xml['Name']
		elsif name == 'Directory' && node_type == R::TYPE_END_ELEMENT
			path.pop
		end
	end
end

begin
	$index = MarshalledDB.new DATA_FILENAME

	i = 0
	n = filelists.length
	filelists.sort.each do |filelist|
		i += 1
		fail 'bad filename' unless filelist =~ /^#{FILELISTS_DIR}\/(.*).filelist.xml/
		username = $1
		File.open(filelist, "r") do |f|
			puts "(#{i}/#{n}) processing #{filelist}"
			xml = XML::Reader.io f
			next if xml.nil?
			process_filelist xml, username
		end
	end

	if OPTIMIZE
		puts "optimizing..."
		$index.optimize
	end
ensure
	$index.close if $index
end
