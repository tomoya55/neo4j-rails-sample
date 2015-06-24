class Band < ActiveRecord::Base
  include NeoResource

  def as_graph_json
    {_id: id, name: name}
  end
end
