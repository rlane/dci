require 'mime/types'

heuristic :extension do
	term! :extension, $1.downcase if path =~ /\.([\w]{1,5})$/
end

EXTENSION_TYPES = {
	:audio => %w(mp3 mp4 wav m4a wma flac aiff aac aif m3u mid midi mpa ra ram),
	:video => %w(mpg mpeg mp4 wmv avi flv mkv 3g2 3gp asf asx mov qt rm vob),
	:text => %w(txt pdf chm doc docx msg tex rtf),
	:image => %w(jpg bmp png tiff pcx psd eps gif indd jpeg mng psp svg tif),
	:code => %w(c cpp rb py h php java scala vb bas cs pl lua hs sml v erb),
	:compressed => %w(7z deb gz pkg rar sea sit sitx zip),
}
EXTENSION_TYPE_MAP = Hash.new { |h,k| h[k] = [] }
EXTENSION_TYPES.each { |k,v| v.each { |e| EXTENSION_TYPE_MAP[e] << k.to_s } }
heuristic :type_from_extension do
	terms.each do |type,term|
		if type == :extension
			EXTENSION_TYPE_MAP[term.downcase].each { |newtype| term! :type, newtype }
		end
	end
end

heuristic :text_from_path do
	path_elements = path.split '/'
	path_elements.each { |x| text! x }
	text! username
end

heuristic :type_from_path do
	term! :type, 'movie' if path.downcase.index 'movie' and term? :type, 'video'
	term! :type, 'tv' if path.downcase.index 'tv' and term? :type, 'video'
end

heuristic :mimetype do
	mimetype! MIME::Types.type_for(path).map{ |x| x.content_type }.uniq.first
end
