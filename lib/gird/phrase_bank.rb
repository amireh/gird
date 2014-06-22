class Gird::PhraseBank
  attr_accessor :tree

  RE_ENDS_WITH_DOT = /\.$/
  RE_CONTAINS_SPACES = /\b\s\b/
  RE_CONTAINS_DOT = /\./
  RE_CONTAINS_UPPERCASE = /[A-Z]/
  RE_STARTS_WITH_SCOPE = /^#{Gird::Constants::SCOPE_PREFIX}/

  class Tree < Hash
    def initialize
      super { |h,k| h[k] = Tree.new(&h.default_proc) }
    end

    def sort_by_keys!
      replace(Hash[self.sort_by { |k,v| k }])
    end
  end

  def initialize
    @phrases = {}
    self.tree = Tree.new
  end

  # Add a phrase to the bank.
  #
  # @param [String] key
  #   The full path of the phrase.
  #
  # @param [String] value
  #   The translation. Can be left empty if you're expecting it to be translated
  #   later by an editor, or when importing phrases from another bank.
  #
  # @param [String] source
  #   The source block from which the phrase was extracted.
  #   Debugging/logging purposes only.
  #
  # @param [String] filepath
  #   The source file from which the phrase was extracted.
  #   Debugging/logging purposes only.
  def add(key, value='', source='', filepath="")
    key = (key||'').to_s
    value = (value||'').to_s

    warn = ->(reason, fatal=false) {
      warn_bad_phrase(key, value, source, reason, filepath, { abort: fatal })
    }

    abort = ->(reason) {
      warn.call(reason, true)
    }

    if key =~ RE_ENDS_WITH_DOT
      abort.call('ends with a dot')
    end

    if key =~ RE_CONTAINS_SPACES
      abort.call('contains spaces')
    end

    if key =~ RE_CONTAINS_DOT && !(key =~ RE_STARTS_WITH_SCOPE)
      warn.call('doesnt start with ns_')
    end

    if key =~ RE_CONTAINS_UPPERCASE
      abort.call('is not lowercase')
    end

    existing_phrase = @phrases[key]

    if existing_phrase.present?
      if value.empty?
        return false
      elsif existing_phrase != value
        abort.call("duplicate: was defined as #{existing_phrase}, and now got #{value}")
      end
    end

    # puts "Phrase: [#{key}] ~> [#{value}] (source: #{source} in #{filepath})"
    @phrases[key] = value
  end

  # Get the value of a phrase.
  def get(key)
    @phrases.fetch(key.to_s, nil)
  end

  # Import phrases from another bank.
  def merge(bank)
    bank.phrases.each do |phrase|
      add(phrase, bank.get(phrase))
    end
  end

  def size
    @phrases.keys.size
  end

  def phrases
    @phrases.keys
  end

  def missing
    @phrases.values.select(&:empty?)
  end

  # Collect all phrases in their corresponding namespace.
  #
  # Example:
  #
  #   {
  #     "ns_wizards.mages.magi" => "Magi",
  #     "ns_wizards.mages.magi_arch" => "Arch Magi"
  #   }
  #
  # Turns into:
  #
  #   {
  #     "ns_wizards" => {
  #       "mages" => {
  #         "magi" => "Magi",
  #         "magi_arch" => "Arch Magi"
  #       }
  #     }
  #   }
  def implode(source=@phrases)
    tree = Tree.new.replace(source)

    tree.sort_by_keys!
    tree.dup.each_pair do |path, phrase_value|
      namespace = Tree.new

      *path_fragments, last = path.split(Gird::Constants::SCOPE_DELIMITER)

      path_fragments.inject(namespace, :[])
      path_fragments.inject(namespace, :fetch)[last] = phrase_value

      namespace.sort_by_keys!

      tree.delete(path)
      tree.deep_merge!(namespace)
    end

    tree
  end

  def implode!
    @tree = implode
  end

  def to_hash
    implode
  end

  def to_json
    to_hash.to_json
  end

  private

  def warn_bad_phrase(key, value, source, reason, file, options={})
    details = JSON.pretty_generate({
      key: key,
      value: value,
      source: source,
      error: reason,
      file: file
    })

    if options[:abort]
      raise Gird::PhraseError.new(details)
    else
      puts "[WARN] Bad phrase: #{details}"
    end
  end
end
