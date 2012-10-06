

module VPNP
  class OutputFormatter
    # Output a, er, thing.
    def output(token)
    end
  end

  class SimpleOutputFormatter

    def initialize
      @buffer = ""
    end

    def output(token)
      @buffer += "#{token.string}_#{token.type}"
    end
  end
end
