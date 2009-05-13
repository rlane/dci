module DCI::ProtocolParser
  @@commandmatch=Regexp.new('^\$(.*)$')
  @@messagematch=Regexp.new('^<(.*?)> (.*)$')
  
  @@validatedenied=Regexp.new('^ValidateDenide')
  @@getpass=Regexp.new('^GetPass$')
  @@badpass=Regexp.new('^BadPass$')
  @@lock=Regexp.new('^Lock (.*) Pk=.*?$')
  @@hubname=Regexp.new('^HubName (.*)$')
  @@hello=Regexp.new('^Hello (.*)$')
  @@myinfo=Regexp.new('^MyINFO \$ALL (.*?) (.*?)\$ \$(.*?).\$(.*?)\$(.*?)\$$')
  @@myinfo2=Regexp.new('^MyINFO \$ALL (.*?) (.*?)\$$')
  @@to=Regexp.new('^To: (.*?) From: (.*?) \$<.*?> (.*)$')
  @@hubto=Regexp.new('^To: (.*?) From: Hub \$(.*)$')
  @@ctm=Regexp.new('^ConnectToMe .*? (.*?):(.*?)$')
  @@nicklist=Regexp.new('^NickList (.*?)$')
  @@psr=Regexp.new('^SR (.*?) (.*?)\005(.*?) (.*?)\/(.*?)\005(.*?) \((.*?)\)$')
  @@psearch=Regexp.new('^Search Hub:(.*) (.)\?(.)\?(.*)\?(.)\?(.*)$')
  @@search=Regexp.new('^Search (.*):(.*) (.)\?(.)\?(.*)\?(.)\?(.*)$')
  @@oplist=Regexp.new('^OpList (.*?)$')
  @@quit=Regexp.new('^Quit (.*)$')
  @@sr=Regexp.new('^SR (.*?) (.*?)\005(.*?) (.*?)\/(.*?)\005(.*?) (.*?):(.*?)$')
	@@rctm=Regexp.new('^RevConnectToMe (.*?) (.*?)$')
  @@mynick=Regexp.new('^MyNick (.*)$')
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

  # Convert a single message (including the $ or <, but not including
  # the terminating pipe) to a dictionary of parsed data.
  def self.parse_message(text)
    case text
    when @@commandmatch
      parse_command_message $1
    when @@messagematch
      {:type => :chat,
       :from => $1,
       :text => $2}
    when ''
      {:type => :junk}
    else
      {:type => :mystery,
       :text => text}
    end
  end

  # Parse a command (i.e., a message starting with $).
  def self.parse_command_message(text)
    case text
    when @@validatedenied
      {:type => :denied}
    when @@getpass
      {:type => :getpass}
    when @@badpass
      {:type => :badpass}
    when @@lock
      {:type => :lock,
       :lock => $1,
       :key  => DCI::KeyGenerator.generate_key($1)}
    when @@hubname
      {:type => :hubname,
       :name => $1}
    when @@hello
      {:type => :hello,
       :who  => $1}
    when @@myinfo
      {:type => :myinfo,
       :nick => $1,
       :interest => $2,
       :speed => $3,
       :email => $4,
       :sharesize => $5 }
    when @@myinfo2
      {:type=>:myinfo,
       :nick=> $1,
       :interest => $2,
       :speed => nil,
       :email => nil,
       :sharesize=> 0}
    when @@to
      {:type => :privmsg,
       :to => $1,
       :from => $2,
       :text => $3}
    when @@hubto
      {:type => :privmsg,
       :to => $1,
       :from => "Hub",
       :text=>$2}
    when @@ctm
      {:type => :connect_to_me,
       :ip => $1,
       :port => $2.to_i}
    when @@nicklist
      {:type => :nick_list,
       :nicks => $1.split(/\$\$/)}
    when @@psr
      {:type => :passive_search_result,
       :nick => $1, 
       :path => $2, 
       :size => $3, 
       :openslots => $4,
       :totalslots => $5,
       :hub => $6, 
       :ip=>$7}
    when @@psearch
      {:type => :pasv_search,
       :searcher => $1,
       :restrictsize => $2,
       :minsize => $3,
       :size => $4,
       :filetype => $5,
       :pattern => $6}
    when @@search
      {:type => :active_search,
       :ip => $1,
       :port => $2,
       :restrictsize => $3,
       :minsize => $4,
       :size => $5,
       :filetype => $6,
       :pattern => $7}
    when @@oplist
      {:type => :op_list,
       :nicks => $1.split(/\$\$/)}
    when @@quit
      {:type => :quit,
       :who => $1}
    when @@sr
      {:type => :searchresult,
       :who => $2,
       :file => $3,
       :size => $4,
       :open => $5,
       :total => $6,
       :hubname => $7}
    when @@rctm
      {:type=> :revconnect,
       :who => $1}
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

module DCI::KeyGenerator
  # Convert a lock to a key.  See
  # <http://wza.digitalbrains.com/DC/doc/Appendix_A.html>.
  #create a key for a lock given as challenge
  def self.generate_key (challenge)
    clen = challenge.length
    k = ""
    #Convert string to integer array
    b = []
    challenge.each_byte{|byte| b.push byte}
    #First byte
    u = b[0]
    l = b[clen-1]
    o = b[clen-2]
    u = u^l^o^5;
    v = (((u<<8)|u)>>4) & 255
    k += encodeChar(v)
    1.upto(clen-1){|i|
      u = b[i]
      l = b[i-1]
      u = u^l
      v = (((u<<8)|u)>>4) & 255
      k += encodeChar(v)
    }       
    return k
  end

  #encode the special characters to that delightful DCN notation
  def self.encodeChar(c)
    if [0,5,36,96,124,126].include? c
      return sprintf("/%%DCN%03d\%%/",c)
    end
    return c.chr
  end               
end
