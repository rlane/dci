module Enumerable
	def find_value
		each do |x|
			r = yield x
			return r if r
		end
		nil
	end
end

class Nop
	def send sym, *a
	end
end

class Object
	def klass
		self.class
	end

	def log; $logger; end
end

module DCI
end

$logger = Nop.new
