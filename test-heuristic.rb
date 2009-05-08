#!/usr/bin/env ruby
require 'rubygems'
require 'pp'

require 'heuristic-lib'
require 'heuristics'

$heuristic_verbose = true
TEST = %w(extension type_from_extension text_from_path type_from_path)
DATA = {
	"6KJNPPDGUC6RKPIZA3T3JQFYPDMMHEA7BUEQZNQ" => {
		:locations => [
			["Bob", "storage/Music/Damien Rice/9/AlbumArt_{68B7FFD0-80F1-4E97-8802-85EF1FE5A456}_Large.jpg"],
			["Bob", "storage/Music/Damien Rice/9/Folder.jpg"]
		],
		:size => 9012
	}
}

def run_heuristics tth, v
	runner = HeuristicRunner.new tth, v
	$heuristics.each do |name,b|
		next unless TEST.member? name
		puts "running #{name} on #{tth}"
		runner.ie &b
	end
	v[:terms].uniq!
	pp v
end

DATA.each do |tth,v|
	run_heuristics tth, v
end
