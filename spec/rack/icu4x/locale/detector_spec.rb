# frozen_string_literal: true

RSpec.describe Rack::ICU4X::Locale::Detector do
  describe ".build" do
    context "with Symbol" do
      it "builds Header from :header" do
        detector = Rack::ICU4X::Locale::Detector.build(:header)
        expect(detector).to be_a(Rack::ICU4X::Locale::Detector::Header)
      end

      it "builds Cookie from :cookie" do
        detector = Rack::ICU4X::Locale::Detector.build(:cookie)
        expect(detector).to be_a(Rack::ICU4X::Locale::Detector::Cookie)
      end

      it "builds Query from :query" do
        detector = Rack::ICU4X::Locale::Detector.build(:query)
        expect(detector).to be_a(Rack::ICU4X::Locale::Detector::Query)
      end

      it "raises for unknown symbol" do
        expect {
          Rack::ICU4X::Locale::Detector.build(:unknown)
        }.to raise_error(Rack::ICU4X::Locale::Detector::InvalidSpecificationError, /Unknown detector/)
      end
    end

    context "with Hash" do
      it "builds Cookie with custom name" do
        detector = Rack::ICU4X::Locale::Detector.build({cookie: "user_locale"})
        expect(detector).to be_a(Rack::ICU4X::Locale::Detector::Cookie)
      end

      it "builds Query with custom param" do
        detector = Rack::ICU4X::Locale::Detector.build({query: "lang"})
        expect(detector).to be_a(Rack::ICU4X::Locale::Detector::Query)
      end

      it "raises for hash with multiple keys" do
        expect {
          Rack::ICU4X::Locale::Detector.build({cookie: "a", query: "b"})
        }.to raise_error(Rack::ICU4X::Locale::Detector::InvalidSpecificationError, /exactly one key/)
      end

      it "raises for unknown detector type" do
        expect {
          Rack::ICU4X::Locale::Detector.build({unknown: "value"})
        }.to raise_error(Rack::ICU4X::Locale::Detector::InvalidSpecificationError, /Unknown detector type/)
      end
    end

    context "with Proc" do
      it "returns the proc as-is" do
        proc = ->(env) { env["custom.locale"] }
        expect(Rack::ICU4X::Locale::Detector.build(proc)).to eq(proc)
      end
    end

    context "with callable object" do
      it "returns the object if it responds to call" do
        callable = Object.new
        def callable.call(_env)
          "ja"
        end
        expect(Rack::ICU4X::Locale::Detector.build(callable)).to eq(callable)
      end

      it "raises if object does not respond to call" do
        expect {
          Rack::ICU4X::Locale::Detector.build("invalid")
        }.to raise_error(Rack::ICU4X::Locale::Detector::InvalidSpecificationError, /must respond to #call/)
      end
    end
  end
end
