class Gird::Importer

  # Import phrases from a YAML file.
  #
  # @param [String] filepath (required)
  #   Path to the YAML file to import from.
  #
  # @param [Symbol|NilClass] locale
  #   If the phrase tree in the YAML file is scoped by the locale identifier,
  #   e.g, "en", then you should pass that.
  #
  # @return [Gird::PhraseBank]
  def self.from_yaml(filepath, locale='en')
    contents = YAML.load_file(filepath)

    if locale.present?
      contents = contents[locale.to_s]
    end

    Importer.import(contents)
  end

  # Build a PhraseBank from a given phrase tree.
  #
  # @return [Gird::PhraseBank]
  def self.import(tree)
    populate(tree)
  end

  private

  def populate(source, scope = '', bank = Gird::PhraseBank.new)
    source.each_pair do |phrase_key, phrase_value|
      unless scope.empty?
        phrase_key = [ scope, phrase_key ].join(Gird::Constants::SCOPE_DELIMITER)
      end

      if phrase_value.is_a?(Hash) # is it a scope in itself?
        populate(v, k, bank)
      else
        @phrase_bank.add k, v, @filename
      end
    end
  end
end