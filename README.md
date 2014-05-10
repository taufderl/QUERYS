# About
QUERYS is an automatic Question/Answering System that processes questions 
given in natural langauge and referring to countries. It processes the 
questions using the Stanford CoreNLP to derive the target country and relation, 
and compile a SPARQLE query to access info stored in DBpedia.

In detail, QUERYS uses WordNet to map content words found in the question
to the covered relationships, exploiting is-a relationships (semantic similarity).
The system covers 15 relationships among those that exist for countries in
DBpedia, thus it can provide answers about official names, mottos, anthems, 
area, capitals, currencies, year of foundation and dissolution, form of 
government, language, largest city, leaders' names and offices, and 
population estimates. Everything that don't concern these aspects is 
out of QUERYS' scope. After asking a question, you can provide us with a 
very useful feed-back by telling us if the answer that QUERYS gave 
you was correct or not.

If you want to ask more questions about the same country you can select 
the option Remember Country, that allows you to omit the name of the country in the following questions.

# Contact
QUERYS has been implemented by Tim auf der Landwehr and Giovanni Cassani 
at the University of Groningen for the course 'Semantic Web Technology'. 
For any further information, mail to: 
g.cassani at student dot rug dot nl
t.auf.der.landwehr at student dot rug dot nl

# Run it yourself
The system is based on Ruby on Rails. The Gemfile contains all necessary gems to run it. 

License
-------

QUERYS is licensed under the MIT license. See [LICENSE](LICENSE) for details.
