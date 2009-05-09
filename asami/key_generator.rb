#require 'dl'
#require 'dl/import'

module KeyGenerator

  #extend DL::Importable
  # dlload "./keygen.so"

  # Convert a lock to a key.  See
  # <http://wza.digitalbrains.com/DC/doc/Appendix_A.html>.
  #extern "char *generate_key (char *)"
  #create a key for a lock given as challenge
  def generate_key (challenge)
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
  def encodeChar(c)
    if [0,5,36,96,124,126].include? c
      return sprintf("/%%DCN%03d\%%/",c)
    end
    return c.chr
  end               
end
