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

	def self.load_entries filename
		[].tap { |r| File.open(filename) { |f| YAML.load_documents(f) { |x| r << x } } }
	end

	def load_entries
		klass.load_entries @f.path
	end
end

class SavingHash < Hash
	def initialize *a
		super(*a) { |h,k| h[k] = yield }
	end
end
