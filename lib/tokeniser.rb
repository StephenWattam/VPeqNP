require File.join(File.join(File.dirname(__FILE__), 'token.rb'))

module VPNP
  class Tokeniser
    def first_token(string)
      # TODO: return first token
    end

    def read_segment(io)
      # Read until some kind of segment end, like a sentence.
    end
  end

  class RegexTokeniser
    WORD_RX       = /(\w+)\s+(\w+)/   # for word TYPE 
    SEGMENT_RX    = /([\w\s]+)/           # for sentence or word breaks.
    READ_CHUNK    = 100                   # tuned to SEGMENT_RX

    attr_reader :word, :segment

    def initialize(word = WORD_RX, segment = SEGMENT_RX, read_chunk = READ_CHUNK)
      @word     = word
      @segment  = segment
    end

    # Return a token, or nil
    def first_token(string)
      str = string.match(@word)

      return nil if not str
      return Token.new(string[str.begin(1)..str.end(2)], str[1], str[2])
    end

    # Read until there is at least one segment in the buffer.
    # Throws EOF error on EOF.
    def read_segment(io)
      segment = ""
      
      while( not segment =~ @segment )do
        return nil if (segment += io.read(@read_chunk)) == '' 
      end

      return segment
      # TODO: ensure we don't miss off the final filesize%chunk bytes.
    end
  end
end

# This is probably not necessary.
# def String
#   def first_pos_token
#     Tokeniser.first_pos_token(self)
#   end
# end
