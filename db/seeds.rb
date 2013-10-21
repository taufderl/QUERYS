# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


cfile = File.open('db/country_names').read

cfile.gsub!(/\r\n?/, "\n")

cfile.each_line do |country|
  Country.create(name: country.strip)
end
