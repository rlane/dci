$heuristic_verbose = false

class HeuristicRunner
	attr_reader :tth

	def terms; @v[:terms]; end
	def texts; @v[:texts]; end
	def locations; @v[:locations]; end
	def mimetype; @v[:mimetype]; end

	def initialize tth, v
		@tth = tth
		@v = v
		@v[:terms] ||= []
		@v[:texts] ||= []
		@v[:locations] ||= []
		@v[:mimetype] ||= nil
	end

	def term! type, term
		@v[:terms] << [type, term]
		puts "term #{type}:#{term}" if $heuristic_verbose
	end

	def term? type, term
		@v[:terms].member? [type, term]
	end

	def text! text
		@v[:texts] << text
		puts "text #{text.inspect}" if $heuristic_verbose
	end

	def mimetype! x
		@v[:mimetype] = x
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
	v[:texts].uniq!
end

def heuristic name, &b
	$heuristics << [name.to_s,b]
end

require 'lib/dci/heuristics/basic'
