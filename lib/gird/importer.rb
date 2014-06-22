
class Gird::Importer
  def import(locale = :en, &block)
    file = YAML.load_file("#{LocaleDir}/#{locale}/locale.yml")
    data = file[locale.to_s]

    populate(data, '', &block)
  end

  private

  def populate(source, context = '', phrases = [], &block)
    source.each_pair do |k,v|
      unless context.empty?
        k = "#{context}.#{k}"
      end

      if v.is_a?(Hash)
        populate(v, k, phrases, &block)
      else
        yield(k,v) if block_given?
      end
    end
  end
end

# @importer = Importer.new
# @importer.import(:en) do |key, value|
#   @phrase_bank.add key, value, "en.yml"
#   @stats[:imported_phrases] += 1
# end