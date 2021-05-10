AlgoliaSearch.configuration = { application_id: Rails.application.credentials.algolia[:application_id], api_key: Rails.application.credentials.algolia[:api_key], :symbolize_keys => false }

# McproFaq.reindex!