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

  class RegexTokeniser < Tokeniser
    WORD_TAG_RX       = /(^|\n)?(?<start>)(?<word>\w+)\s+(?<tag>\w+)(?<end>)\s?(\n|$)/   # for word TYPE 
    WORD_RX           = /(?<start>)(?<word>[\w']+)(?<end>)/   # for words, no tag entry
    SEGMENT_RX    = /([\w\s]+)/           # for sentence or word breaks.
    READ_CHUNK    = 512                   # tuned to SEGMENT_RX

    attr_reader :word, :segment

    def initialize(word = WORD_RX, segment = SEGMENT_RX, read_chunk = READ_CHUNK)
      @word     = word
      @segment  = segment
      @read_chunk = read_chunk.to_i
    end

    # Return a token, or nil
    def first_token(string)
      str = string.match(@word)

      # Return if nothing matched.
      return nil, string if not str
    
      # If a create a new item with the data from regex.  :tag is optional.
      if str.names.include?('tag') then
        token = Token.new(string[str.begin(:start)..str.end(:end)], str[:word], str[:tag])
      else
        token  = Token.new(string[str.begin(:start)..str.end(:end)], str[:word])
      end
      # Then return it with a section cut off the original string
      return token, string[str.end(:end)..-1]
    end

    # Read until there is at least one segment in the buffer.
    # Throws EOF error on EOF.
    def read_segment(io)

      segment = ""
      
      while( not segment =~ @segment )do
        return nil if (segment += io.read(@read_chunk) ||'' ) == '' 
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
