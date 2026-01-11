# frozen_string_literal: true

RSpec.describe Rack::ICU4X::Locale::Detector::Cookie do
  describe "#call" do
    context "with default cookie name" do
      let(:detector) { Rack::ICU4X::Locale::Detector::Cookie.new }

      it "returns locale from cookie" do
        env = Rack::MockRequest.env_for("/", "HTTP_COOKIE" => "locale=ja")
        expect(detector.call(env)).to eq("ja")
      end

      it "returns nil when cookie is missing" do
        env = Rack::MockRequest.env_for("/")
        expect(detector.call(env)).to be_nil
      end

      it "returns nil when cookie is empty" do
        env = Rack::MockRequest.env_for("/", "HTTP_COOKIE" => "locale=")
        expect(detector.call(env)).to be_nil
      end

      it "handles locale with region" do
        env = Rack::MockRequest.env_for("/", "HTTP_COOKIE" => "locale=en-US")
        expect(detector.call(env)).to eq("en-US")
      end
    end

    context "with custom cookie name" do
      let(:detector) { Rack::ICU4X::Locale::Detector::Cookie.new("user_locale") }

      it "returns locale from named cookie" do
        env = Rack::MockRequest.env_for("/", "HTTP_COOKIE" => "user_locale=en")
        expect(detector.call(env)).to eq("en")
      end

      it "ignores default cookie when custom is set" do
        env = Rack::MockRequest.env_for("/", "HTTP_COOKIE" => "locale=ja; user_locale=en")
        expect(detector.call(env)).to eq("en")
      end
    end
  end
end
