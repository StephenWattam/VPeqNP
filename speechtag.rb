

train = File.open('pos.train.txt', 'r')

assoc = Hash.new

while (line = train.gets)
  example = line.split
  word = assoc[example[0]]
  if word != nil
    puts "refound #{word}"
    word = assoc[example[0]]
  else
    word = Hash.new
    
end

train.close
