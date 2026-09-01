require "rails_helper"

RSpec.describe Interview::AI::OpenAIClient do
  Response = Data.define(:output_text)

  class FakeResponses
    attr_reader :arguments

    def initialize
      @arguments = nil
    end

    def create(**arguments)
      @arguments = arguments
      Response.new('{"score":3,"summary":"ok","stronger_answer":"better","matched_concept_keys":[],"missing_concept_keys":[],"misconceptions":[]}')
    end
  end

  class FakeOpenAIClient
    attr_reader :responses

    def initialize
      @responses = FakeResponses.new
    end
  end

  it "uses Responses structured JSON schema and a finite timeout" do
    provider = FakeOpenAIClient.new
    client = described_class.new(client: provider, api_key: "test", model: "gpt-test", timeout: 4.0)

    expect(client.evaluate(prompt: "prompt")).to include("score" => 3)
    expect(provider.responses.arguments[:model]).to eq("gpt-test")
    expect(provider.responses.arguments[:request_options]).to eq(timeout: 4.0)
    expect(provider.responses.arguments.dig(:text, :format, :type)).to eq("json_schema")
    expect(provider.responses.arguments.dig(:text, :format, :schema, :properties, :score, :minimum)).to eq(0)
  end

  it "requires credentials only when instantiated for AI mode" do
    expect { described_class.new(api_key: nil) }.to raise_error(described_class::Error, /OPENAI_API_KEY/)
  end

  it "maps timeout and rate-limit failures without exposing provider details" do
    timeout_provider = Class.new(FakeOpenAIClient) do
      def initialize
        super
        @responses = Object.new
        def @responses.create(**)
          raise Timeout::Error, "secret provider detail"
        end
      end
    end.new
    expect { described_class.new(client: timeout_provider, api_key: "test").evaluate(prompt: "x") }
      .to raise_error(described_class::Error, /Timeout::Error/)

    rate_limited_provider = Class.new(FakeOpenAIClient) do
      def initialize
        super
        @responses = Object.new
        def @responses.create(**)
          raise OpenAI::Errors::RateLimitError.allocate
        end
      end
    end.new
    expect { described_class.new(client: rate_limited_provider, api_key: "test").evaluate(prompt: "x") }
      .to raise_error(described_class::Error, /RateLimitError/)
  end
end
