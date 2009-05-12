#a module to parse commands received from a hub
module HubParser
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
  
  # Convert a single message (including the $ or <, but not including
  # the terminating pipe) to a dictionary of parsed data.
  def HubParser.parse_message(text)
    case text
      #when /^\$(.*)$/
      
    when @@commandmatch
      parse_command_message $1
      #when /^<(.*?)> (.*)$/ 
    when @@messagematch
      {:type => :chat,
       :from => $1,
       :text => $2}
    when ''                       # we get empty junk messages some times
      {:type => :junk}
    else
      {:type => :mystery,
       :text => text}
    end
  end

  # Parse a command (i.e., a message starting with $).
  def HubParser.parse_command_message(text)
    case text
    when @@validatedenied
      {:type => :denide}
    when @@getpass
      {:type => :getpass}
    when @@badpass
      {:type => :badpass}
    when @@lock
      {:type => :lock,
       :lock => $1,
       :key  => KeyGenerator.generate_key($1)}
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
    else
      {:type => :mystery,
       :text => text}
    end
  end
end
