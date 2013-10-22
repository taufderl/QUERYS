require_relative '../../lib/qas-core/CoreNLPServer.rb'

cnlps = Thread.new {CoreNLPServer.new.run}