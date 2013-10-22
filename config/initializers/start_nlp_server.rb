require_relative '../../app/qas-core/CoreNLPServer.rb'

cnlps = Thread.new {CoreNLPServer.new.run}