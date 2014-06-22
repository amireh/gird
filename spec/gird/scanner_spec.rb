require 'spec_helper'

describe Gird::Scanner do
  describe '#run' do
    let :dest do
      File.join(*[
        File.dirname(__FILE__),
        '..',
        '..',
        'tmp',
        'scanner_spec.json'
      ])
    end

    after do
      FileUtils.rm(dest) if File.exists?(dest)
    end

    it "should scan all files and output to a JSON file" do
      subject.run(File.join(*[
        File.dirname(__FILE__),
        '..',
        'fixture',
        '*.*'
      ]), dest)

      expect(JSON.parse(File.read(dest)).with_indifferent_access).to eq({
        locale: {
          en: {
            ns_goblins: {
              cyclops: 'Cyclops',
              behemoth: ''
            },
            ns_necropolis: {
              lich: 'Lich',
              lich_arch: 'Arch Lich',
              vampire: 'Vampire'
            },
            ns_wizards: {
              magi: 'Magi'
            }
          }
        }
      }.with_indifferent_access)
    end

    it 'should abort on an error' do
      expect {
        subject.run(File.join(File.dirname(__FILE__), '..', 'fixture', 'broken', '*'), dest)
      }.to raise_error(Gird::PhraseBank::PhraseError)

      expect(File.exists?(dest)).to be(false)
    end
  end
end
