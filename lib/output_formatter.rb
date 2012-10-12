

module VPNP
  class OutputFormatter
    # Output a, er, thing.
    def output(token)
    end
  end

  class SimpleOutputFormatter

    def initialize
    end

    def output(token)
      return "#{token.word}_#{token.type} "
    end
  end
end
