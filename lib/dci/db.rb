module DCI

DB_TYPE = :qdbm

if DB_TYPE == :qdbm
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

elsif DB_TYPE == :gdbm
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

else
raise "invalid db type #{DB_TYPE}"
end

end
