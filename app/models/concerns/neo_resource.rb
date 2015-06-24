module NeoResource
  extend ActiveSupport::Concern

  included do
    after_commit :create_neo_node, on: :create
    after_commit :update_neo_node, on: :update
    after_commit :delete_neo_node, on: :destroy

    class_attribute :neo, instance_writer: false
    self.neo = Neography::Rest.new
  end

  module ClassMethods
    def force_unique_constraint
      neo.get_unique_constraint(label_for_model, "_id")
    rescue Neography::NeographyError
      neo.create_unique_constraint(label_for_model, "_id")
    end

    def label_for_model
      name
    end

    def find_neo_by_neo_id(neo_id)
      Neography::Node.load(neo_id, neo)
    end

    def find_neo_by_id(id)
      res = neo.execute_query("MATCH (n:#{label_for_model} {_id: #{id}}) RETURN n")
      if res["data"].any?
        Neography::Node.new(res).tap do |node|
          node.neo_server = neo
        end
      end
    end
  end

  def neo_node
    if persisted?
      @_neo_node ||= begin
        self.class.find_neo_by_id(id) || create_neo_node
      end
    end
  end

  def reload_neo_node
    @_neo_node = self.class.find_neo_by_id(id) if persisted?
  end

  def as_graph_json
    { _id: id }
  end

  def create_neo_node
    Neography::Node.create(as_graph_json).tap do |node|
      node.set_label(label_for_model)
      self.class.force_unique_constraint
    end
  end

  def update_neo_node
    neo.set_node_properties(neo_node, as_graph_json)
  end

  def delete_neo_node
    @_neo_node.try(:del)
  end

  def create_relationship(rel_name, in_out, other)
    case in_out
    when "in"
      Neography::Relationship.create(rel_name, other.neo_node, self.neo_node)
    when "out"
      Neography::Relationship.create(rel_name, self.neo_node, other.neo_node)
    else
      raise ArgumentError, "invalid direction: #{in_out}"
    end
  end

  def incoming(rel_name)
    type = neo_node.incoming(rel_name)[0].labels[0]
    type.constantize.where(id: neo_node.incoming(rel_name).map(&:_id))
  end

  def outgoing(rel_name)
    type = neo_node.outgoing(rel_name)[0].labels[0]
    type.constantize.where(id: neo_node.outgoing(rel_name).map(&:_id))
  end

  private

  def neo
    self.class.neo
  end

  def label_for_model
    self.class.label_for_model
  end
end
