require File.join(File.join(File.dirname(__FILE__), 'token.rb'))
require File.join(File.join(File.dirname(__FILE__), 'tokeniser.rb'))
require 'stringio'

module VPNP
  # Statefully read from an io source, producing Tokens.
  # Uses a Tokeniser to define what a token is, and how large readaheads should be.
  class TokenSource
    attr_reader :source

    # Create with an IO object source and a tokeniser.
    def initialize(sources, tokeniser)
      @sources        = (sources.is_a?(Array) ? sources : [sources])  # accept an array or a single item
      @tokeniser      = tokeniser
      reset

      # Check it's possible to actually work with the input...
      # @sources.map{|s| raise "Source #{s} is not of type IO." if not s.is_a? IO }
    end

    # Seeks to the first token, clears all buffers,
    # and resets file pointers to the first item.
    def reset
      @buffer         = '' 
      @current_file   = 0
      @prev_token     = nil
      @sources.map{|io| io.seek(0)}
    end

    # Returns the "next" token from the stream
    def next
      # TODO: use tokeniser and buffering to split on the io object
      #
      token, @buffer = @tokeniser.first_token(@buffer)
      while(not token) do
        token, @buffer = @tokeniser.first_token(@buffer)
        if not token then
          return nil if not fill_buffer
        end
      end

      # Patch up the source entry in token
      # this might be removed later, but could prove handy.
      token.source  = @sources[@current_file]
      token.prev    = @prev_token
      token.next    = self

      # Load token into previous/next 
      @prev_token.next  = token if @prev_token 
      @prev_token       = token

      # and return the complete token
      return token
    end

    private

    # Fills the buffer up to whatever tokeniser's segment
    def fill_buffer
      return nil if @sources.length < (@current_file + 1)
      # Read from the current file
      str = @tokeniser.read_segment(@sources[@current_file])

      # If that file returns nothing, try the next one
      if not str then
        @current_file += 1
        return fill_buffer
      end

      # Return the string
      @buffer += str || ''
    end
  end

  # Constructs a token source from a ruby string object.
  class SimpleTokenSource < TokenSource
    def initialize(string, tokeniser)
      super(StringIO.new(string), tokeniser)
    end
  end


  # Constructs a token source from a globbable path string and bounds.
  class DirTokenSource < TokenSource
    def initialize(path, index, limit, tokeniser)
      f_list = Dir.glob(path)
      f_list.map!{|x| File.open(x)}
      limit = f_list.length   if limit > f_list.length 
      index = 0 if index > limit
      super(f_list[index..limit], tokeniser)
    end
  end
    
end
