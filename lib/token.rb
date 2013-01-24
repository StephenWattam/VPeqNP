
module VPNP
  class Token
    # Read-write type
    attr_accessor :type, :source, :prev
    # Read string
    attr_reader :string, :word
    attr_writer :next

    def initialize(string, word, type=nil)
      @word     = word
      @string   = string
      @type     = type
    end

    # Retrieve the next token in the stream,
    # or nil if this is the last token.
    #
    # If the next item has not been read, @next will
    # be a TokenSource object, and calling Token#next
    # will automatically load it.
    def next
      if @next.is_a? TokenSource
        @next = @next.next
        return @next 
      end
      @next
    end

    # Access the stem of this token.
    # TODO: currently simply removes case
    def lemma
      # TODO Return @string.stem
      @word.downcase
    end

    # Write to disk as lemma:type
    def to_s
      "[(#{@word}:#{@type})]"
    end
  end
end
