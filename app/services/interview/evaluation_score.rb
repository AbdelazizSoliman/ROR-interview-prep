module Interview
  module EvaluationScore
    LABELS = {
      0 => "No meaningful knowledge",
      1 => "Very weak",
      2 => "Partial",
    3 => "Acceptable mid-level answer",
      4 => "Strong",
      5 => "Excellent / precise / production-aware"
    }.freeze

    THRESHOLDS = [ [ 0.0, 0 ], [ 0.01, 1 ], [ 0.25, 2 ], [ 0.50, 3 ], [ 0.70, 4 ], [ 0.90, 5 ] ].freeze

    module_function

    def from_coverage(matched_weight:, total_weight:)
      return 0 if total_weight.to_f <= 0 || matched_weight.to_f <= 0

      ratio = matched_weight.to_f / total_weight.to_f
      THRESHOLDS.reverse_each { |threshold, score| return score if ratio >= threshold }
      0
    end

    def label(score)
      LABELS.fetch(score)
    end
  end
end
