#!/usr/bin/env zsh
time (
	rm -f var/data
	time bin/merge

	rm -f var/data.analyzed
	time bin/analyze

	rm -rf var/index
	time bin/index
)
