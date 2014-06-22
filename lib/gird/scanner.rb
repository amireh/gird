#!/usr/bin/env ruby
#
# Scans the Pibi.js sources (JSTs and JavaScript scripts) for all i18n keys,
# and possibly default values, and merges them with the current locale phrases.
#
# Usage: ./bin/i18n-parser.rb
#
# Output:
#  - en.yml: ready for consumption by Pibi.js
#  - en.json: ready for consumption by the PLM API
#
# Dependencies:
#   - gem 'json'
#   - gem 'active_support', '>=4.0'
#   - script bin/i18n-to-yaml.py
#
# Sources:
#   - www/src/js/templates/**/*.hbs
#   - www/src/js/**/*.js
#   - www/assets/locales/**/*.yml

class Gird::Scanner
  def run(src, dest)
    @phrase_bank = Gird::PhraseBank.new
    @parser = Gird::Parser.new
    stats = {}

    base = File.dirname(src)
    files = Dir.glob(src)
    files.each do |filepath|
      filename = filepath.sub(base, '')
      @parser.parse(File.read(filepath)).each do |phrase|
        rc = @phrase_bank.add(phrase[:path], phrase[:value], phrase[:source], filename)

        abort if !rc
      end
    end


    @phrase_bank.build_namespaces

    stats[:imported_phrases] = 0
    stats[:files] = files.length
    stats[:phrases] = @phrase_bank.nr_phrases
    stats[:missing] = @phrase_bank.find_empty_phrases.length

    puts '=' * 80
    puts "I18N PARSER STATS"
    puts '-' * 80
    puts stats.to_json
    puts '=' * 80

    File.open(dest, 'w') do |f|
      f.write({
        locale: {
          en: @phrase_bank.tree
        }
      }.to_json)
    end
  end

  def abort
    raise "ParserError"
  end
end

