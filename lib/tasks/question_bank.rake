namespace :question_bank do
  desc "Import the YAML question bank"
  task import: :environment do
    result = Interview::QuestionBank::Importer.call
    puts result.summary
  rescue Interview::QuestionBank::Importer::Error => error
    abort "Question-bank import failed: #{error.message}"
  end
end
