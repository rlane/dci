module DCI
end

module Enumerable
	def find_value
		each do |x|
			r = yield x
			return r if r
		end
		nil
	end
end

class Object
	def klass
		self.class
	end

	def log; $logger; end
end

class YamlLogger
	def initialize filename
		@f = File.open(filename, 'a')
	end

	def log h
		@f.puts h.to_yaml
		@f.flush
	end
end
