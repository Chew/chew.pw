class McproFaq < ApplicationRecord
  self.table_name = "mcpro_faq"
  include AlgoliaSearch

  algoliasearch index_name: "mcpro_faq", id: :id do
    attributes :data

    searchableAttributes ['data']
  end

  def id_changed?
    false
  end

  def algolia_id
    id
  end
end
