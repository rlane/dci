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
	def debug!; $logger.level = Logger::DEBUG; end
	def info!; $logger.level = Logger::INFO; end
	def warn!; $logger.level = Logger::WARN; end
	def error!; $logger.level = Logger::ERROR; end
	def fatal!; $logger.level = Logger::FATAL; end
end

class YamlLogger
	def initialize filename
		@f = File.open(filename, 'w+')
	end

	def log h
		@f.puts h.to_yaml
		@f.flush
	end
end
