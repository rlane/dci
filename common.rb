
NORMAL_PREFIXES = {
	:text => 'B',
}

BOOLEAN_PREFIXES = {
	:type => 'T',
	:username => 'U',
	:tth => 'H',
	:extension => 'E',
}

PREFIXES = NORMAL_PREFIXES.merge BOOLEAN_PREFIXES

SIZE_VALUENO = 0

def mkterm(type, value)
	prefix = PREFIXES[type] or raise "Invalid term type #{type.inspect}"
	"#{prefix}#{value}"
end

if true
# 35s 22M
require 'depot'
class MarshalledDB < Depot
	def initialize filename
		super(filename, Depot::OWRITER | Depot::OCREAT)
	end

  def []= k, v
    super k, Marshal.dump(v)
  end

  def [] k
    v = super k
    v ? Marshal.load(v) : nil
  end

	def each
		super { |k,v| yield k, Marshal.load(v) }
	end
end
end

if false
# 40s 133m
require 'gdbm'
class MarshalledDB < GDBM
  def []= k, v
    super k, Marshal.dump(v)
  end

  def [] k
    v = super k
    v ? Marshal.load(v) : nil
  end

	def each
		super { |k,v| yield k, Marshal.load(v) }
	end

	def optimize
		reorganize
	end
end
end
