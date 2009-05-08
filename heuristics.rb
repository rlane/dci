heuristic :extension do
	locations.each do |_,path|
		next unless path =~ /\.([\w]{1,5})$/
		term! :extension, $1.downcase
	end
end

EXTENSION_TYPES = {
	:music => %w(mp3 mp4 wav),
	:video => %w(mpg mpeg mp4 wmv avi flv mkv),
	:text => %w(txt pdf chm),
	:image => %w(jpg bmp png),
}
EXTENSION_TYPE_MAP = Hash.new { |h,k| h[k] = [] }
EXTENSION_TYPES.each { |k,v| v.each { |e| EXTENSION_TYPE_MAP[e] << k.to_s } }
heuristic :type_from_extension do
	terms.each do |type,term|
		if type == :extension
			EXTENSION_TYPE_MAP[term].each { |newtype| term! :type, newtype }
		end
	end
end

