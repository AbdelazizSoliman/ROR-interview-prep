require "json"

module Interview
  module AI
    class OpenAIClient
      class Error < StandardError; end

      SCHEMA = {
        type: "object",
        additionalProperties: false,
        required: %w[score summary stronger_answer matched_concept_keys missing_concept_keys misconceptions],
        properties: {
          score: { type: "integer", minimum: 0, maximum: 5 },
          summary: { type: "string" },
          stronger_answer: { type: "string" },
          matched_concept_keys: { type: "array", items: { type: "string" } },
          missing_concept_keys: { type: "array", items: { type: "string" } },
          misconceptions: {
            type: "array",
            items: {
              type: "object", additionalProperties: false, required: %w[statement explanation],
              properties: { statement: { type: "string" }, explanation: { type: "string" } }
            }
          }
        }
      }.freeze

      def initialize(client: nil, api_key: Configuration.openai_api_key, model: Configuration.openai_model, timeout: Configuration.openai_timeout)
        raise Error, "OPENAI_API_KEY is required when INTERVIEW_EVALUATOR=ai" if api_key.to_s.empty?

        @client = client || OpenAI::Client.new(api_key: api_key)
        @model = model
        @timeout = timeout
      end

      attr_reader :model

      def evaluate(prompt:)
        response = @client.responses.create(
          model:,
          input: prompt,
          text: { format: { type: "json_schema", name: "answer_evaluation", strict: true, schema: SCHEMA } },
          request_options: { timeout: @timeout }
        )
        JSON.parse(response.output_text)
      rescue JSON::ParserError => error
        raise Error, "OpenAI returned malformed structured output: #{error.message}"
      rescue OpenAI::Errors::APIError => error
        raise Error, "OpenAI evaluation request failed (#{error.class.name})"
      rescue Timeout::Error, IOError, SystemCallError => error
        raise Error, "OpenAI evaluation request failed (#{error.class.name})"
      end
    end
  end
end
