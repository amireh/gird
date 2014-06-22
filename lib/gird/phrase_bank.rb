class Gird::PhraseBank
  attr_accessor :tree, :nr_phrases

  class Tree < Hash
    def sort_by_keys!
      replace(Hash[self.sort_by { |k,v| k }])
    end
  end

  class PhraseError < RuntimeError
    def initialize(details)
      super(JSON.pretty_generate(details))
    end
  end

  SCOPE_PREFIX = Gird::Constants::SCOPE_PREFIX

  RE_ENDS_WITH_DOT = /\.$/
  RE_CONTAINS_SPACES = /\b\s\b/
  RE_CONTAINS_DOT = /\./
  RE_CONTAINS_UPPERCASE = /[A-Z]/
  RE_STARTS_WITH_SCOPE = /^#{SCOPE_PREFIX}/

  def initialize
    self.tree = Tree.new { |h,k| h[k] = Tree.new(&h.default_proc) }
    self.nr_phrases = 0
  end

  def add(key, value, source, filepath="")
    key = (key||'').to_s
    value = (value||'').to_s

    warn = ->(reason, fatal) {
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
      warn.call('doesnt start with ns_', false)
    end

    if key =~ RE_CONTAINS_UPPERCASE
      abort.call('is not lowercase')
    end

    existing_phrase = @tree[key]

    if existing_phrase && !existing_phrase.empty?
      return false if value.empty?

      if existing_phrase != value
        abort.call("duplicate: was defined as #{existing_phrase}, and now got #{value}")
      end
    end

    puts "Phrase: [#{key}] ~> [#{value}] (source: #{source} in #{filepath})"
    @tree[key] = value
    self.nr_phrases += 1
  end

  def build_namespaces
    @tree.sort_by_keys!
    @tree.dup.each_pair do |k,v|
      *keys, last = k.split('.')

      namespace = Tree.new { |h,k| h[k] = Tree.new(&h.default_proc) }
      keys.inject(namespace, :[])
      keys.inject(namespace, :fetch)[last] = v

      namespace.sort_by_keys!

      @tree.delete(k)
      @tree.deep_merge!(namespace)
    end
  end

  def find_empty_phrases(phrases = tree, missing = [])
    phrases.each_pair do |key, value|
      missing << key if value.blank?

      if key.is_a?(Tree)
        find_empty_phrases(value, missing)
      end
    end

    missing
  end

  private

  def warn_bad_phrase(key, value, source, reason, file, options={})
    details = ({
      key: key,
      value: value,
      source: source,
      error: reason,
      file: file
    })

    if options[:abort]
      raise PhraseError.new(details)
    else
      puts "[WARN] Bad phrase: #{JSON.pretty_generate(details)}"
    end
  end
end
