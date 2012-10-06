require File.join(File.join(File.dirname(__FILE__), 'token.rb'))

module VPNP
  class Tokeniser
    def self.first_token(string)
      # TODO: return first token
    end

    def self.read_segment(io)
      # Read until some kind of segment end, like a sentence.
    end
  end
end

# This is probably not necessary.
# def String
#   def first_pos_token
#     Tokeniser.first_pos_token(self)
#   end
# end
