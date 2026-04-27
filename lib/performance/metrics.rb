# frozen_string_literal: true

module Performance
  module Metrics
    ELASTICSEARCH_INDEX = "govwifi-metrics"

    PERIODS = {
      daily: "day",
      weekly: "week",
      monthly: "month",
    }.freeze
  end
end
