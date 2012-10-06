require File.join(File.join(File.dirname(__FILE__), 'token.rb'))
require File.join(File.join(File.dirname(__FILE__), 'tokeniser.rb'))

module VPNP
  class TokenSource
    attr_reader :source

    # Create with an IO object source and a tokeniser.
    def initialize(source, tokeniser)
      @source = source
      @tokeniser = tokeniser
      @buffer = ""
    end

    def next
      # TODO: use tokeniser and buffering to split on the io object
      fill_buffer if @tokeniser.sufficient_buffer? buffer
      @tokeniser.first_pos_token(buffer)
    end

    private
    def fill_buffer
      # TODO: read from io object until tokeniser says it's read enough
      #  - might be wise to use an array of segments as a buffer, but then
      #  that doesn't alloow for merging things like lines.
      buffer += @tokeniser.read_segment(io)
    end
  end

  def SimpleTokenSource
    def initialize(string)
      super(string)
    end

  end
end
