# frozen_string_literal: true

RSpec.describe Rack::ICU4X::Locale::Detector::Query do
  describe "#call" do
    context "with default parameter name" do
      let(:detector) { Rack::ICU4X::Locale::Detector::Query.new }

      it "returns locale from ?locale=ja" do
        env = Rack::MockRequest.env_for("/?locale=ja")
        expect(detector.call(env)).to eq("ja")
      end

      it "returns nil when parameter is missing" do
        env = Rack::MockRequest.env_for("/")
        expect(detector.call(env)).to be_nil
      end

      it "returns nil when parameter is empty" do
        env = Rack::MockRequest.env_for("/?locale=")
        expect(detector.call(env)).to be_nil
      end

      it "returns nil when query string is empty" do
        env = Rack::MockRequest.env_for("/")
        env["QUERY_STRING"] = ""
        expect(detector.call(env)).to be_nil
      end

      it "handles URL-encoded values" do
        env = Rack::MockRequest.env_for("/?locale=zh-Hant-TW")
        expect(detector.call(env)).to eq("zh-Hant-TW")
      end
    end

    context "with custom parameter name" do
      let(:detector) { Rack::ICU4X::Locale::Detector::Query.new("lang") }

      it "returns locale from ?lang=ja" do
        env = Rack::MockRequest.env_for("/?lang=ja")
        expect(detector.call(env)).to eq("ja")
      end

      it "ignores default parameter when custom is set" do
        env = Rack::MockRequest.env_for("/?locale=en&lang=ja")
        expect(detector.call(env)).to eq("ja")
      end
    end
  end
end
