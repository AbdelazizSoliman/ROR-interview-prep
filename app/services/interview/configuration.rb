module Interview
  module Configuration
    module_function

    def evaluator
      ENV.fetch("INTERVIEW_EVALUATOR", "deterministic").to_sym
    end

    def openai_api_key
      ENV["OPENAI_API_KEY"]
    end

    def openai_model
      ENV.fetch("OPENAI_EVALUATION_MODEL", "gpt-5.6-luna")
    end

    def openai_timeout
      Float(ENV.fetch("OPENAI_EVALUATION_TIMEOUT", "30"))
    rescue ArgumentError
      30.0
    end
  end
end
