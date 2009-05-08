#!/usr/bin/env ruby
require 'rubygems'
require 'common'

DATA_FILENAME = "data"
HEURISTIC_METHODS = %w(extension).map { |x| "heuristic_#{x}".to_sym }

class HeuristicRunner
	attr_reader :tth, :terms, :locations

	def initialize tth, v
		@tth = tth
		@terms = v[:terms]
		@locations = v[:locations]
	end

	def produce type, term
		@terms << [type, term]
		puts "produced #{type}:#{term}"
	end

	def ie &b; instance_eval &b; end
end

$heuristics = []

def run_heuristics tth, v
	runner = HeuristicRunner.new tth, v
	$heuristics.each do |name,b|
		puts "running #{name} on #{tth}"
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

$index = MarshalledGDBM.new DATA_FILENAME

$index.each do |tth,v|
	terms = v[:terms]
	old_terms = terms.dup
	run_heuristics tth, v
	$index[tth] = v if terms != old_terms
end
