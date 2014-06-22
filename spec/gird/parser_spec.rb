require 'spec_helper'

describe Gird::Parser do
  describe 'scope resolution' do
    it "var t = require('i18n!something');" do
      doc = <<-EOF
        define(function(require) {
          var t = require('i18n!wizards');

          var BadWizard = React.createClass({
            render: function() {
              return <div title={t('bad_wizard', 'Barrrgh')} />
            }
          });
        });
      EOF

      subject.extract_refs(doc).should == [{
        ref: 't',
        scope: 'ns_wizards'
      }]
    end

    it "define([ 'module1', 'i18n!wizards' ], function(Module, t) { ... });" do
      doc = <<-EOF
        define([ 'module1', 'i18n!wizards' ], function(Module, t) {
          var BadWizard = React.createClass({
            render: function() {
              return <div title={t('bad_wizard', 'Barrrgh')} />
            }
          });
        });
      EOF

      subject.extract_refs(doc).should == [{
        ref: 't',
        scope: 'ns_wizards'
      }]
    end


    it "define([ 'i18n!wizards', 'i18n!goblins' ], function(t) { ... });" do
      doc = <<-EOF
        define([ 'i18n!wizards', 'i18n!goblins' ], function(tWizards, tGoblins) {
          var BadWizard = React.createClass({
            render: function() {
              return <div title={tWizards('bad_wizard', 'Barrrgh')} />
            }
          });
        });
      EOF

      subject.extract_refs(doc).should == [{
        ref: 'tWizards',
        scope: 'ns_wizards'
      }, {
        ref: 'tGoblins',
        scope: 'ns_goblins'
      }]
    end

    it 'converts nesting using "/" to "."' do
      doc = <<-EOF
        define([ 'i18n!wizards/spells' ], function(tSpells) {
        });
      EOF

      subject.extract_refs(doc).should == [{
        ref: 'tSpells',
        scope: 'ns_wizards.spells'
      }]
    end
  end

  context 'phrase extraction' do
    let(:doc) {
      <<-EOF
      define(function(require) {
        var t = require('i18n!wizards');

        var BadWizard = React.createClass({
          render: function() {
            return <div title={t('bad_wizard', 'Barrrgh')} />
          }
        });

        var Label = t('no_default');

        // Form 3
        var Label2 = t('magi', {
          defaultValue: 'Magi'
        });

        // Form 3 but with another option:
        var Label3 = t('magi', {
          count: 5,
          defaultValue: 'Magi'
        });

        // Form 4: with a context
        var Label4 = t('magi', {
          defaultValue: 'Arch Magi',
          context: 'arch'
        });
      });
      EOF
    }

    it "{t('foo', 'bar')}" do
      phrases = subject.parse(doc)
      phrases[0].tap do |phrase|
        phrase[:path].should == 'ns_wizards.bad_wizard'
        phrase[:value].should == 'Barrrgh'
      end
    end

    it "{t('foo')}" do
      phrases = subject.parse(doc)
      phrases[1].tap do |phrase|
        phrase[:path].should == 'ns_wizards.no_default'
        phrase[:value].should == ''
      end
    end

    it "{t('magi', { defaultValue: 'Magi' })}" do
      phrases = subject.parse(doc)
      phrases[2].tap do |phrase|
        phrase[:path].should == 'ns_wizards.magi'
        phrase[:value].should == 'Magi'
      end
    end

    it "{t('magi', { count: 5, defaultValue: 'Magi' })}" do
      phrases = subject.parse(doc)
      phrases[3].tap do |phrase|
        phrase[:path].should == 'ns_wizards.magi'
        phrase[:value].should == 'Magi'
      end
    end

    it "{t('magi', { context: 'arch', defaultValue: 'Arch Magi' })}" do
      phrases = subject.parse(doc)
      phrases[4].tap do |phrase|
        phrase[:path].should == 'ns_wizards.magi_arch'
        phrase[:value].should == 'Arch Magi'
      end
    end
  end
end
