# frozen_string_literal: true

class Performance::Gateway::Elasticsearch
  def initialize(index)
    @index = index
  end

  def write(key, data)
    client = Services.elasticsearch_client

    client.index(
      index: @index,
      id: key,
      body: data,
    )
  end

  def bulk_write(data_array)
    client = Services.elasticsearch_client
    client.bulk(
      index: @index,
      body: data_array.map { |data| { index: { data: } } },
    )
  end
end
