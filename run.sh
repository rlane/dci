#!/usr/bin/env zsh
time (
	rm -f data
	time ./merge.rb

	rm -f data.analyzed
	time ./analyze.rb

	rm -rf index
	time ./index.rb
)
