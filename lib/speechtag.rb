

train = File.open('../resources/pos.train.txt', 'r')
assoc = Hash.new

while (line = train.gets)
  example = line.split
  word = assoc[example[0]] || word = Hash.new
  #puts "refound #{example[0]} #{word}" if word[example[1]] != nil
  (word[example[1]])  ? (word[example[1]] += 1) :  (word[example[1]] = 1)
  assoc[example[0]] = word
end

train.close

test = File.open('../resources/pos.test.txt', 'r')

while (line = test.gets)
  example = line.split
  data = assoc[example[0]]
  puts data
  puts "#{example[0]} is probably #{data.keys.max_by{|k,v| v}} (#{data.values.max}/#{data.values.inject(:+)})" if data
end

test.close
