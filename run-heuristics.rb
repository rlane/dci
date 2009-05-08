#!/usr/bin/env ruby
require 'rubygems'
require 'common'

IN_DATA_FILENAME = "data"
OUT_DATA_FILENAME = "data-h"
OPTIMIZE = false

class HeuristicRunner
	attr_reader :tth, :terms, :locations

	def initialize tth, v
		@tth = tth
		@terms = v[:terms]
		@locations = v[:locations]
	end

	def produce type, term
		@terms << [type, term]
		#puts "produced #{type}:#{term}"
	end

	def ie &b; instance_eval &b; end
end

$heuristics = []

def run_heuristics tth, v
	runner = HeuristicRunner.new tth, v
	$heuristics.each do |name,b|
		#puts "running #{name} on #{tth}"
		runner.ie &b
	end
	v[:terms].uniq!
end

def heuristic name, &b
	$heuristics << [name,b]
end

heuristic 'extension' do
	locations.each do |_,path|
		next unless path =~ /\.([\w]{1,5})$/
		produce :extension, $1.downcase
	end
end

heuristic 'type' do
	terms.each do |type,term|
		if type == :extension
			if term == 'mp3'
				produce :type, 'music'
			end
		end
	end
end

in_index = out_index = nil
begin
	in_index = MarshalledDB.new IN_DATA_FILENAME
	out_index = MarshalledDB.new OUT_DATA_FILENAME

	i = 0
	n = in_index.size
	in_index.each do |tth,v|
		i += 1
		run_heuristics tth, v
		out_index[tth] = v
		puts "processed #{i}/#{n}" if (i % 10000) == 0
	end

	if OPTIMIZE
		puts "optimizing..."
		out_index.optimize
	end
ensure
	in_index.close if in_index
	out_index.close if out_index
end
