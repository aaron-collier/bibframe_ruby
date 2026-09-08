# frozen_string_literal: true

module BibframeRuby
  class GraphBuilder
    BF = "http://id.loc.gov/ontologies/bibframe/"
    BFLC = "http://id.loc.gov/ontologies/bflc/"
    RDF_TYPE = RDF.type.to_s
    RDFS_LABEL = RDF::RDFS.label.to_s

    TYPE_MAP = {
      "#{BF}Hub" => Hub,
      "#{BF}Work" => Work,
      "#{BF}Instance" => Instance,
      "#{BF}Item" => Item,
      "#{BF}Contribution" => Contribution,
      "#{BF}PrimaryContribution" => Contribution,
      "#{BF}Title" => Title,
      "#{BF}Person" => Person,
      "#{BF}Organization" => Organization,
      "#{BF}Subject" => Subject
    }.freeze

    # Maps BIBFRAME predicates to Ruby property names
    PROPERTY_MAP = {
      "#{BF}title" => "title",
      "#{BF}mainTitle" => "main_title",
      "#{BF}subtitle" => "subtitle",
      "#{BFLC}nonSortNum" => "non_sort_num",
      "#{BF}contribution" => "contributions",
      "#{BF}hasInstance" => "instances",
      "#{BF}instanceOf" => "work",
      "#{BF}hasItem" => "items",
      "#{BF}itemOf" => "instance",
      "#{BF}language" => "language",
      "#{BF}summary" => "summary",
      "#{BF}genreForm" => "genre_forms",
      "#{BF}classification" => "classifications",
      "#{BF}relation" => "relations",
      "#{BF}identifiedBy" => "identifiers",
      "#{BF}extent" => "extent",
      "#{BF}carrier" => "carrier",
      "#{BF}media" => "media",
      "#{BF}provisionActivity" => "provision_activity",
      "#{BF}editionStatement" => "edition_statement",
      "#{BF}dimensions" => "dimensions",
      "#{BF}publicationStatement" => "publication_statement",
      "#{BF}responsibilityStatement" => "responsibility_statement",
      "#{BF}issuance" => "issuance",
      "#{BF}agent" => "agent",
      "#{BF}role" => "role",
      "#{BF}heldBy" => "held_by",
      "#{BF}shelfMark" => "shelf_mark",
      "#{BF}content" => "content",
      "#{BF}subject" => "subjects",
      RDFS_LABEL => "label",
      "#{BF}code" => "code",
      "#{BF}source" => "source",
      "#{BF}status" => "status",
      "#{BF}date" => "date",
      "#{BF}seriesEnumeration" => "series_enumeration",
      "#{BF}associatedResource" => "associated_resource",
      "#{BF}relationship" => "relationship",
      "#{BF}adminMetadata" => "admin_metadata",
      "#{BF}derivedFrom" => "derived_from",
      "#{BF}assigner" => "assigner",
      "#{BF}classificationPortion" => "classification_portion",
      "#{BF}itemPortion" => "item_portion",
      "#{BF}edition" => "edition",
      "#{BF}descriptionLevel" => "description_level",
      "#{BF}descriptionLanguage" => "description_language",
      "#{BF}descriptionAuthentication" => "description_authentication",
      "#{BFLC}catalogerId" => "cataloger_id",
      "#{BFLC}aap" => "Authorized Access Point",
      "#{BFLC}aap-normalized" => "aap_normalized",
      "#{BFLC}simpleDate" => "simple_date",
      "#{BFLC}simpleAgent" => "simple_agent",
      "#{BFLC}simplePlace" => "simple_place"
    }.freeze

    # Properties that always hold arrays
    ARRAY_PROPERTIES = %w[
      contributions instances items genre_forms classifications
      relations identifiers subjects admin_metadata
    ].freeze

    # Properties whose blank-node value should be collapsed to its rdfs:label string
    LABEL_COLLAPSE_PROPERTIES = %w[summary extent].freeze

    def initialize(rdf_graph)
      @rdf_graph = rdf_graph
      @resources = {}
      @stubs = {}
    end

    def build
      grouped = group_by_subject
      extract_resources(grouped)
      link_relationships

      {
        resources: @resources,
        works: @resources.values.select { |r| r.is_a?(Work) },
        instances: @resources.values.select { |r| r.is_a?(Instance) },
        items: @resources.values.select { |r| r.is_a?(Item) },
        hubs: @resources.values.select { |r| r.is_a?(Hub) }
      }
    end

    private

    def group_by_subject
      groups = Hash.new { |h, k| h[k] = [] }
      @rdf_graph.each_statement { |s| groups[s.subject] << s }
      groups
    end

    def extract_resources(grouped)
      grouped.each do |subject, statements|
        # Skip blank nodes that will be resolved inline as sub-resources
        next if subject.is_a?(RDF::Node)

        types = extract_types(statements)
        klass = resolve_class(types)
        type_names = types.map { |t| t.to_s.split(%r{[/#]}).last }

        resource = klass.new(
          id: subject.to_s,
          types: type_names
        )

        populate_properties(resource, statements, grouped)
        register_resource(subject, resource)
      end
    end

    def extract_types(statements)
      statements
        .select { |s| s.predicate.to_s == RDF_TYPE }
        .map(&:object)
    end

    def resolve_class(types)
      type_strings = types.map(&:to_s)
      TYPE_MAP.each do |type_uri, klass|
        return klass if type_strings.include?(type_uri)
      end
      Resource
    end

    def populate_properties(resource, statements, grouped)
      statements.each do |stmt|
        next if stmt.predicate.to_s == RDF_TYPE

        prop_name = PROPERTY_MAP[stmt.predicate.to_s] || stmt.predicate.to_s.split(%r{[/#]}).last
        value = resolve_value(stmt.object, grouped, prop_name)
        next if value.nil?

        if ARRAY_PROPERTIES.include?(prop_name)
          resource[prop_name] ||= []
          resource[prop_name] << value
        elsif resource[prop_name].nil?
          resource[prop_name] = value
        elsif resource[prop_name].is_a?(Array)
          resource[prop_name] << value
        else
          resource[prop_name] = [resource[prop_name], value]
        end
      end

      # Mark contribution as primary if PrimaryContribution is in its types
      return unless resource.is_a?(Contribution)

      types_uris = statements
                   .select { |s| s.predicate.to_s == RDF_TYPE }
                   .map { |s| s.object.to_s }
      resource["primary"] = true if types_uris.include?("#{BF}PrimaryContribution")
    end

    def resolve_value(object, grouped, prop_name = nil)
      case object
      when RDF::Node
        resolve_blank_node(object, grouped, prop_name)
      when RDF::URI
        object.to_s
      when RDF::Literal
        object.object.to_s
      else
        object.to_s
      end
    end

    def resolve_blank_node(node, grouped, prop_name = nil)
      return nil unless grouped.key?(node)

      sub_statements = grouped[node]
      types = extract_types(sub_statements)
      klass = resolve_class(types)
      type_names = types.map { |t| t.to_s.split(%r{[/#]}).last }

      sub_resource = klass.new(types: type_names)
      populate_properties(sub_resource, sub_statements, grouped)
      register_resource(node, sub_resource)

      # Collapse label-only resources to their string label
      return sub_resource["label"] if LABEL_COLLAPSE_PROPERTIES.include?(prop_name) && sub_resource["label"]

      sub_resource
    end

    def register_resource(subject, resource)
      key = subject.to_s
      @resources[key] = resource
    end

    def link_relationships
      link_work_instances
      link_instance_items
      replace_uri_stubs
    end

    def link_work_instances
      @resources.values.select { |r| r.is_a?(Work) }.each do |work|
        next unless work["instances"]

        work["instances"] = work["instances"].map do |ref|
          uri = ref.is_a?(String) ? ref : ref.id
          @resources[uri] || stub_for(uri)
        end
      end

      @resources.values.select { |r| r.is_a?(Instance) }.each do |instance|
        next unless instance["work"]

        uri = instance["work"].is_a?(String) ? instance["work"] : instance["work"].id
        instance["work"] = @resources[uri] || stub_for(uri)
      end
    end

    def link_instance_items
      @resources.values.select { |r| r.is_a?(Instance) }.each do |instance|
        next unless instance["items"]

        instance["items"] = instance["items"].map do |ref|
          uri = ref.is_a?(String) ? ref : ref.id
          @resources[uri] || stub_for(uri)
        end
      end

      @resources.values.select { |r| r.is_a?(Item) }.each do |item|
        next unless item["instance"]

        uri = item["instance"].is_a?(String) ? item["instance"] : item["instance"].id
        item["instance"] = @resources[uri] || stub_for(uri)
      end
    end

    def replace_uri_stubs
      # Replace any remaining string URI references in contribution agents
      @resources.values.select { |r| r.is_a?(Contribution) }.each do |contrib|
        next unless contrib["agent"].is_a?(String)

        contrib["agent"] = @resources[contrib["agent"]] || stub_for(contrib["agent"])
      end
    end

    def stub_for(uri)
      @stubs[uri] ||= Resource.new(id: uri)
    end
  end
end
