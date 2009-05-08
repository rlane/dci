$heuristic_verbose = false

class HeuristicRunner
	attr_reader :tth, :terms, :locations

	def initialize tth, v
		@tth = tth
		@terms = v[:terms]
		@locations = v[:locations]
	end

	def term! type, term
		@terms << [type, term]
		puts "term #{type}:#{term}" if $heuristic_verbose
	end

	def text! text
		@texts << text
		puts "text #{text.inspect}" if $heuristic_verbose
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
