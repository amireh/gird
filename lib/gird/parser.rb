require 'active_support/core_ext'

class Gird::Parser
  SCOPE_PREFIX = Gird::Constants::SCOPE_PREFIX

  # Require.js i18n! loader style, stuff like:
  #
  #   define([ 'foo', 'i18n!foo' ], function(Foo, t) {
  #     t(/* ... */);
  #   });
  RJS = 1

  # Simplified CommonJS-style:
  #
  #   define(function(require) {
  #     var t = require('i18n!foo');
  #     var tError = require('i18n!foo/errors');
  #     t(/*...*/);
  #     tError(/*...*/);
  #   });
  CJS = 2

  CJS_TOKENIZER = /
    var \s+
      ([^\s]+)
      \s* = \s*
      require\(
        ['"]
          i18n!([^'"]+)
        ['"]
      \)
  /x

  RJS_TOKENIZER = /
    define\(\[
      ([^\]]+)
    \] \s*,\s* function\(
      ([^\)]+)
    \)
  /x

  QUOTE_STRIPPER = /^['"]|['"]$/

  PHRASE = /
    \(
      ['"] ([^']+) ['"] # the phrase key, what is inside the quotes
      \s* ,? \s*        # discard separating commas, if any
      ([^\)]*)          # capture all kinds of value arguments
    \)
  /xs

  # An options hash locator:
  #
  # t('something', { /* ... */ });
  OPTIONS = /
    \{
      ([^\}]+)
    \}
  /xs

  # Specifying a default value inside an options hash:
  #
  # t('something', {
  #   defaultValue: 'Something'
  # });
  OPTION_VALUE = /
    defaultValue: \s*
      ['"]
        ([^']+)
      ['"]
  /x

  # Specifying a context:
  #
  # t('something', {
  #   context: 'blue'
  # });
  CONTEXT = /
    context: \s*
      ['"]
        ([^'"]+)
      ['"]
  /x

  # Specifying a default value directly as a second argument:
  #
  # t('something', 'Something');
  SCALAR_VALUE = /
    ['"]
      ([^'"]+)
    ['"]
  /x

  def determine_style(stream)
    if stream.scan(/define\(function\(require/).present?
      CJS
    else
      RJS
    end
  end

  # Scan the stream for all references of i18n! reference variables and scopes.
  #
  # @param [String] stream
  #   Your DOC stream.
  #
  # @return [Array<Hash>]
  #   A set of the i18n! variable references and the scopes they represent.
  #
  # === RJS example:
  #
  # Input stream:
  #
  #   define([ 'foo', 'i18n!foo' ], function(Foo, t) {
  #     t(/* ... */);
  #   });
  #
  # Output:
  #
  #   [{ ref: 't', scope: 'foo' }]
  #
  # === CJS example:
  #
  # Input stream:
  #
  #   define(function(require) {
  #     var t = require('i18n!foo');
  #     var tError = require('i18n!foo/errors');
  #     t(/*...*/);
  #     tError(/*...*/);
  #   });
  #
  # Output:
  #
  #   [{ ref: 't', scope: 'foo' }, { ref: 'tError', scope: 'foo.errors' }]
  def extract_refs(stream)
    scopes = []
    style = determine_style(stream)

    normalize_scope = ->(scope) {
      SCOPE_PREFIX + scope.to_s.sub(/^i18n!/, '').gsub('/', Gird::Constants::SCOPE_DELIMITER)
    }

    case style
    when CJS
      stream.scan(CJS_TOKENIZER).each do |ref, scope|
        scopes << { ref: ref, scope: normalize_scope.call(scope) }
      end

    when RJS
      deps, refs = stream.scan(RJS_TOKENIZER).flatten.map do |capture|
        capture.split(',').map { |entry| entry.strip.gsub(QUOTE_STRIPPER, '') }
      end

      if deps.present?
        deps.each_with_index do |dep, i|
          next unless dep =~ /^i18n!/

          scopes << {
            ref: refs[i],
            scope: normalize_scope.call(dep)
          }
        end
      end
    end

    scopes
  end

  def parse(stream)
    phrases = []

    extract_refs(stream).each do |scope_and_ref|
      scope, ref = scope_and_ref[:scope], scope_and_ref[:ref]
      ref_extractor = /\b
        #{ref}
          \(
            [^\)]+
          \)
      /x

      stream.scan(ref_extractor) do |capture|
        capture = capture.to_s.strip

        next if capture.empty?

        phrase = capture.scan(PHRASE).flatten.map(&:strip)

        key = phrase[0].clone
        options = phrase[1].clone
        value = ''

        # Value in options hash:
        #
        #   t('something', { defaultValue: 'Something' })
        if options =~ OPTIONS
          if options =~ OPTION_VALUE
            value = $1.strip
          end

          # Extract any context
          if options =~ CONTEXT
            key << "_#{$1.strip}"
          end

        # Value as a string:
        #
        #   t('something', 'Something')
        elsif options =~ SCALAR_VALUE
          value = $1
        end

        phrases << {
          path: [ scope, key ].join(Gird::Constants::SCOPE_DELIMITER),
          value: value,
          source: capture
        }
      end
    end

    phrases
  end
end
