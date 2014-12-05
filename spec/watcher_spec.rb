require 'spec_helper'

describe(Jekyll::Watcher) do
  let(:base_opts) do
    {
      'source' => source_dir,
      'destination' => dest_dir
    }
  end
  let(:options) { base_opts }
  let(:default_ignored) { [/_config\.yml/, /_site/, /\.jekyll\-metadata/] }
  subject { described_class }
  before(:each) do
    FileUtils.mkdir(options['destination']) if options['destination']
  end
  after(:each) do
    FileUtils.rm_rf(options['destination']) if options['destination']
  end

  context "#build_listener" do
    let(:listener) { subject.build_listener(options) }

    it "returns a Listen::Listener" do
      expect(listener).to be_a(Listen::Listener)
    end

    it "ignores the config and site by default" do
      expect(listener.options[:ignore]).to eql(default_ignored)
    end

    it "defaults to no force_polling" do
      expect(listener.options[:force_polling]).to be(nil)
    end

    context "with force_polling turned on" do
      let(:options)  { base_opts.merge('force_polling' => true) }
      let(:listener) { subject.build_listener(options) }

      it "respects the custom value of force_polling" do
        expect(listener.options[:force_polling]).to be(true)
      end
    end
  end

  context "#listen_ignore_paths" do
    let(:ignored) { subject.listen_ignore_paths(options) }
    let(:metadata_path) { Jekyll.sanitized_path(options['source'], '.jekyll-metadata') }

    before(:each) { FileUtils.touch(metadata_path) }
    after(:each)  { FileUtils.rm(metadata_path) }

    it "ignores config.yml, .jekyll-metadata, and _site by default" do
      expect(ignored).to eql(default_ignored)
    end

    context "with something excluded" do
      let(:excluded) { ['README.md', 'LICENSE'] }
      let(:excluded_absolute) { excluded.map { |p| Jekyll.sanitized_path(options['source'], p) }}
      let(:options) { base_opts.merge('exclude' => excluded) }
      before(:each) { FileUtils.touch(excluded_absolute) }
      after(:each)  { FileUtils.rm(excluded_absolute) }

      it "ignores the excluded files" do
        expect(ignored).to include(/README\.md/)
        expect(ignored).to include(/LICENSE/)
      end
    end

    context "with a custom destination" do
      let(:default_ignored) { [/_config\.yml/, /_dest/, /\.jekyll\-metadata/] }

      context "when source is absolute" do
        context "when destination is absolute" do
          let(:options) { base_opts.merge('destination' => source_dir('_dest')) }
          it "ignores the destination" do
            expect(ignored).to eql(default_ignored)
          end
        end

        context "when destination is relative" do
          let(:options) { base_opts.merge('destination' => 'spec/test-site/_dest') }
          it "ignores the destination" do
            expect(ignored).to eql(default_ignored)
          end
        end
      end

      context "when source is relative" do
        let(:base_opts) { {'source' => Pathname.new(source_dir).relative_path_from(Pathname.new('.').expand_path).to_s } }

        context "when destination is absolute" do
          let(:options) { base_opts.merge('destination' => source_dir('_dest')) }
          it "ignores the destination" do
            expect(ignored).to eql(default_ignored)
          end
        end

        context "when destination is relative" do
          let(:options) { base_opts.merge('destination' => 'spec/test-site/_dest') }
          it "ignores the destination" do
            expect(ignored).to eql(default_ignored)
          end
        end
      end
    end

  end

end
