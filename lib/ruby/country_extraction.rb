
  "<http://dbpedia.org/resource/Albania>" =~ (/[.]*\/([A-Za-z]*)(.)$/)
  puts $1



 

countries = []
f = File.open('./country_tags').read
f.gsub!(/\r\n?/, "\n")



f.each_line do |line|
  #puts line
  #r = line.to_s.match(/[.]*\/([A-Za-z]*)>$/)
  line =~ (/[.]*\/([^\/]*)>$/)
  #puts r.inspect
  countries << $1 
end

puts countries[1..10].join("|")
puts countries.length
countries.uniq!
puts countries.length

out = File.write 'country_names',  countries.join("\n")

     
       #   result[0][:o].to_s =~ (/[.]*\/([A-Za-z]*)\z/)
       #   @answer =  $1
  