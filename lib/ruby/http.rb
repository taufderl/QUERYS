require 'net/http'
require 'nokogiri'
require 'htmlentities'
require 'xmlsimple'


@question = "What language is spoken in Ghana?"


##
uri = URI("http://nlp.stanford.edu:8080/corenlp/process")
params = { 'outputFormat' => 'xml', 'input' => @question }
uri.query = URI.encode_www_form(params)

res = Net::HTTP.get_response(uri)

x = res.body.gsub!("<br>", '')

x = Nokogiri::HTML(x).text

from =  (x =~ /<\?xml /)
to = (x =~ /<\/root>/) +7

x = x[from, to-from]

