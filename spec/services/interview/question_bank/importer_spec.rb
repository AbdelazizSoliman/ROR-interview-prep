require "rails_helper"
require "fileutils"
require "tmpdir"
require "yaml"

RSpec.describe Interview::QuestionBank::Importer do
  around do |example|
    Dir.mktmpdir("question-bank-spec") do |directory|
      @bank_path = Pathname(directory)
      example.run
    end
  end

  it "imports a fresh bank with topics, questions, concepts, and follow-ups" do
    write_document(valid_document)

    result = described_class.call(path: @bank_path)

    expect([ Topic.count, Question.count, QuestionConcept.count, QuestionFollowUp.count ]).to eq([ 1, 2, 3, 1 ])
    expect(result.to_h).to include(topics_created: 1, questions_created: 2, concepts_created: 3, follow_ups_created: 1)
  end

  it "is idempotent when source files are unchanged" do
    write_document(valid_document)
    described_class.call(path: @bank_path)
    record_ids = [ Topic.pluck(:id), Question.order(:stable_key).pluck(:id), QuestionConcept.order(:id).pluck(:id) ]

    result = described_class.call(path: @bank_path)

    expect(result.to_h.values).to all(be_zero)
    expect([ Topic.pluck(:id), Question.order(:stable_key).pluck(:id), QuestionConcept.order(:id).pluck(:id) ]).to eq(record_ids)
  end

  it "updates an existing stable key and synchronizes concepts by position" do
    document = valid_document
    write_document(document)
    described_class.call(path: @bank_path)
    question = Question.find_by!(stable_key: "ruby.objects.mutation")
    original_id = question.id
    first_concept_id = question.question_concepts.first.id

    document["questions"].first["prompt"] = "Updated prompt"
    document["questions"].first["concepts"].first["concept"] = "Updated first concept"
    document["questions"].first["concepts"] << { "concept" => "Third concept", "weight" => 2 }
    write_document(document)

    result = described_class.call(path: @bank_path)
    question.reload

    expect(question.id).to eq(original_id)
    expect(question.prompt).to eq("Updated prompt")
    expect(question.question_concepts.pluck(:concept, :position)).to eq([
      [ "Updated first concept", 0 ], [ "Aliasing", 1 ], [ "Third concept", 2 ]
    ])
    expect(question.question_concepts.first.id).to eq(first_concept_id)
    expect(result.to_h).to include(questions_updated: 1, concepts_updated: 1, concepts_created: 1)
  end

  it "removes a source-owned follow-up when it disappears from YAML" do
    document = valid_document
    write_document(document)
    described_class.call(path: @bank_path)
    expect(QuestionFollowUp.count).to eq(1)

    document["questions"].first["follow_ups"] = []
    write_document(document)

    described_class.call(path: @bank_path)

    expect(QuestionFollowUp.count).to be_zero
    expect(Question.find_by!(stable_key: "ruby.objects.mutation").follow_up_questions).to be_empty
  end

  it "preserves a question when it disappears from YAML" do
    document = valid_document
    write_document(document)
    described_class.call(path: @bank_path)
    removed_question = Question.find_by!(stable_key: "ruby.objects.copying")
    removed_question_concept_ids = removed_question.question_concepts.ids

    document["questions"].first["follow_ups"] = []
    document["questions"].reject! { |question| question["stable_key"] == removed_question.stable_key }
    write_document(document)

    described_class.call(path: @bank_path)

    expect(Question.find_by(stable_key: removed_question.stable_key)).to eq(removed_question)
    expect(removed_question.reload.question_concepts.ids).to eq(removed_question_concept_ids)
    expect(Question.count).to eq(2)
  end

  it "fails clearly on malformed YAML without writing records" do
    File.write(@bank_path.join("broken.yml"), "topic: [unterminated")

    expect { described_class.call(path: @bank_path) }
      .to raise_error(described_class::Error, /Invalid question-bank YAML/)
    expect(Topic.count).to be_zero
  end

  it "rejects an unknown classification" do
    document = valid_document
    document["questions"].first["difficulty"] = "expert"
    write_document(document)

    expect { described_class.call(path: @bank_path) }
      .to raise_error(described_class::Error, /Unknown difficulty "expert"/)
  end

  it "rejects a missing follow-up reference" do
    document = valid_document
    document["questions"].first["follow_ups"].first["stable_key"] = "ruby.missing.question"
    write_document(document)

    expect { described_class.call(path: @bank_path) }
      .to raise_error(described_class::Error, /Missing follow-up question/)
  end

  it "rejects duplicate stable keys across source files" do
    document = valid_document
    document["questions"] << document["questions"].first.deep_dup
    write_document(document)

    expect { described_class.call(path: @bank_path) }
      .to raise_error(described_class::Error, /Duplicate stable_key/)
  end

  it "rejects duplicate topic slugs across source files" do
    write_document(valid_document, name: "first.yml")
    second = valid_document
    second["questions"].each { |question| question["stable_key"] = "other.#{question["stable_key"]}" }
    write_document(second, name: "second.yml")

    expect { described_class.call(path: @bank_path) }
      .to raise_error(described_class::Error, /Duplicate topic slug/)
  end

  def write_document(document, name: "questions.yml")
    File.write(@bank_path.join(name), YAML.dump(document))
  end

  def valid_document
    {
      "version" => 1,
      "topic" => {
        "name" => "Ruby", "slug" => "ruby", "description" => "Ruby semantics",
        "position" => 0, "active" => true
      },
      "questions" => [
        {
          "stable_key" => "ruby.objects.mutation", "topic" => "ruby", "short_title" => "Mutation",
          "prompt" => "Explain mutation.", "difficulty" => "junior", "priority" => "core",
          "question_type" => "code_reasoning", "reference_answer" => "Objects can be mutated.",
          "explanation" => "References can alias objects.", "common_mistakes" => "Confusing assignment with mutation.",
          "active" => true, "position" => 0,
          "concepts" => [
            { "concept" => "Object identity", "explanation" => "Objects have identity.", "weight" => 1 },
            { "concept" => "Aliasing", "weight" => 1.5 }
          ],
          "follow_ups" => [ { "stable_key" => "ruby.objects.copying", "relationship_type" => "deeper" } ]
        },
        {
          "stable_key" => "ruby.objects.copying", "topic" => "ruby", "short_title" => "Copying",
          "prompt" => "Explain shallow copying.", "difficulty" => "mid", "priority" => "important",
          "question_type" => "knowledge", "reference_answer" => "dup performs a shallow copy.",
          "explanation" => nil, "common_mistakes" => "Assuming nested objects are copied.",
          "active" => true, "position" => 1,
          "concepts" => [ { "concept" => "Shallow copy", "weight" => 1 } ],
          "follow_ups" => []
        }
      ]
    }
  end
end
