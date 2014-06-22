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
  include Gird::Logger

  def run(src, dest, filters=[])
    @phrase_bank = Gird::PhraseBank.new
    @parser = Gird::Parser.new
    stats = {}

    base = File.dirname(src)
    files = Dir.glob(src)

    logger.debug "Scanning #{files.length} files with #{filters.length} exclusion filters."
    logger.debug "Filters: #{filters.inspect}"

    files.each do |filepath|
      filename = filepath.sub(base, '')

      filter = filters.detect { |filter| filename.match(filter) }

      if filter.present?
        logger.warn "Filter applied: [#{filter}] ~> [#{filename}]"
        next
      end

      next if File.directory?(filepath)

      tally = @phrase_bank.size
      @parser.parse(File.read(filepath)).each do |phrase|
        rc = @phrase_bank.add(phrase[:path], phrase[:value], phrase[:source], filename)

        abort if !rc
      end

      tally = @phrase_bank.size - tally

      if tally > 0
        logger.info "Extracted #{tally} phrases from #{filename}"
      end
    end

    @phrase_bank.implode!

    stats[:imported_phrases] = 0
    stats[:files] = files.length
    stats[:phrases] = @phrase_bank.size
    stats[:missing] = @phrase_bank.missing.size

    logger.info '=' * 80
    logger.info "I18N PARSER STATS"
    logger.info '-' * 80
    logger.info stats.to_json
    logger.info '=' * 80

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

