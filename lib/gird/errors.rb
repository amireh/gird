module Gird
  class PhraseError < RuntimeError
  end

  class DuplicatePhraseError < PhraseError
  end
end