Neography.configure do |config|
  config.protocol       = "http://"
  config.server         = "localhost"
  config.port           = "7474"
  config.directory      = ""  # prefix this path with '/'
  config.cypher_path    = "/cypher"
  config.gremlin_path   = "/ext/GremlinPlugin/graphdb/execute_script"
  config.log_file       = "log/neography#{Rails.env.test? ? '_test' : ''}.log"
  config.log_enabled    = true
  config.max_threads    = 20
  config.authentication = "basic"
  config.username       = "neo4j"
  config.password       = "password"
  config.parser         = MultiJsonParser
end
