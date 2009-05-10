#a module to give the ability to parse client->client communications
module ClientParser

  @@commandmatch=Regexp.new('^\$(.*)$')
  @@mynick=Regexp.new('^MyNick (.*)$')
  @@lock=Regexp.new('^Lock (.*) Pk=.*$')
  @@key=Regexp.new('^Key (.*)$')
  @@direction=Regexp.new('^Direction (Download|Upload) (\d+)$')
  @@get=Regexp.new('^Get (.*)\$(\d+)$')
	@@adcsnd_tth=Regexp.new('^ADCSND file TTH/([\w\d]+) (\d+) (\d+)$')
	@@adcsnd_filelist=Regexp.new('^ADCSND file (files.*) (\d+) (\d+)$')
  @@send=Regexp.new('^Send$')
  @@filelength=Regexp.new('^FileLength (.*?)$')
  @@getlistlen=Regexp.new('^GetListLen$')
  @@maxedout=Regexp.new('^MaxedOut$')
  @@supports=Regexp.new('^Supports (.*)$')
  @@error=Regexp.new('^Error (.*)$')
  @@ugetblock=Regexp.new('^UGetBlock (.*?) (.*?) (.*)$')
  
  #take input, and parse it if it's a command
  def ClientParser.parse_message(text)
    case text
    when @@commandmatch
      parse_command $1
    else
      {:type => :mystery,
       :text => text}
    end
  end
  
  #parse a command and return an object with relevant details
  def ClientParser.parse_command(text)
    case text
    when @@mynick
      {:type => :mynick,
       :nick => $1}
    when @@lock
      {:type => :lock,
       :lock => $1,
       :key => KeyGenerator.generate_key($1)}
    when @@key
      {:type => :key,
       :key => $1}
    when @@direction
      {:type => :direction,
       :direction => (case $1
                      when 'Download' then :download
                      when 'Upload' then :upload
                      end),
       :number => $3.to_i}
    when @@get
      {:type => :get,
       :path => $1,
       :offset => $2.to_i - 1}
    when @@send
      {:type => :send}
    when @@adcsnd_tth
      {:type => :adcsnd,
			 :file => $1,
			 :offset => $2.to_i,
			 :length => $3.to_i}
    when @@adcsnd_filelist
      {:type => :adcsnd,
			 :file => $1,
			 :offset => $2.to_i,
			 :length => $3.to_i}
    when @@filelength
      {:type => :file_length,
       :length => $1.to_i}
    when @@getlistlen
      {:type => :getlistlen}
    when @@maxedout
      {:type => :noslots}
    when @@supports
      {:type => :supports,
       :extensions => $1}
    when @@error
      {:type => :error,
       :message => $1}
    when @@ugetblock
      {:type => :ugetblock,
       :start => $1.to_i,
       :finish => $2.to_i,
       :path => $3}
    else
      {:type => :mystery,
       :text => text}
    end
  end
end
