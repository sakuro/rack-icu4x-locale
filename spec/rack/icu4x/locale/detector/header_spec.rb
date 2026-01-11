# frozen_string_literal: true

RSpec.describe Rack::ICU4X::Locale::Detector::Header do
  describe "#call" do
    let(:detector) { Rack::ICU4X::Locale::Detector::Header.new }

    it "returns locales sorted by quality value" do
      env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "ja,en;q=0.9,de;q=0.8")
      expect(detector.call(env)).to eq(%w[ja en de])
    end

    it "returns nil when header is missing" do
      env = Rack::MockRequest.env_for("/")
      expect(detector.call(env)).to be_nil
    end

    it "returns nil when header is empty" do
      env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "")
      expect(detector.call(env)).to be_nil
    end

    it "handles quality values" do
      env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "en;q=0.5,ja;q=1.0,de;q=0.8")
      expect(detector.call(env)).to eq(%w[ja de en])
    end

    it "handles locales with regions" do
      env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "en-US,en;q=0.9,ja;q=0.8")
      expect(detector.call(env)).to eq(%w[en-US en ja])
    end

    it "handles locales with scripts" do
      env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "zh-Hant-TW,zh-Hans-CN;q=0.9")
      expect(detector.call(env)).to eq(%w[zh-Hant-TW zh-Hans-CN])
    end

    it "defaults quality to 1.0 when not specified" do
      env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "ja,en;q=0.9")
      expect(detector.call(env)).to eq(%w[ja en])
    end
  end
end
