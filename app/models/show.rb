class Show < ActiveRecord::Base
  include NeoResource

  def as_graph_json
    {_id: id, title: title}
  end
end
