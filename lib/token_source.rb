require File.join(File.join(File.dirname(__FILE__), 'token.rb'))
require File.join(File.join(File.dirname(__FILE__), 'tokeniser.rb'))

module VPNP
  class TokenSource
    attr_reader :source

    # Create with an IO object source and a tokeniser.
    def initialize(sources, tokeniser)
      @sources        = (sources.is_a?(Array) ? sources : [sources])  # accept an array or a single item
      @tokeniser      = tokeniser
      @buffer         = '' 
      @current_file   = 0
      @prev_token     = nil
    end

    # Returns the "next" token from the stream
    def next
      # TODO: use tokeniser and buffering to split on the io object
      #
      token, @buffer = @tokeniser.first_token(@buffer)
      while(not token) do
        token, @buffer = @tokeniser.first_token(@buffer)
        return nil if not fill_buffer
      end

      # Patch up the source entry in token
      # this might be removed later, but could prove handy.
      token.source  = @sources[@current_file]
      token.prev    = @prev_token
      token.next    = self

      if @prev_token then
        @prev_token.next  = token
      end
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
  def SimpleTokenSource
    def initialize(string, tokeniser)
      super(StringIO.new(string), tokeniser)
    end

  end
end
