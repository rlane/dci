#!/usr/bin/env ruby
require 'rubygems'
require 'common'

IN_DATA_FILENAME = "data"
OUT_DATA_FILENAME = "data-h"
OPTIMIZE = false

require 'heuristic-lib'
require 'heuristics'

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
		puts "analyzed #{i}/#{n}" if (i % 10000) == 0
	end

	if OPTIMIZE
		puts "optimizing..."
		out_index.optimize
	end
ensure
	in_index.close if in_index
	out_index.close if out_index
end
