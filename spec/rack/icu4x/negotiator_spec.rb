# frozen_string_literal: true

RSpec.describe Rack::ICU4X::Negotiator do
  describe "#negotiate" do
    context "with simple language codes" do
      let(:negotiator) { Rack::ICU4X::Negotiator.new(%w[en ja]) }

      it "matches exact language" do
        expect(negotiator.negotiate(%w[ja en])).to eq(%w[ja en])
      end

      it "matches region variant to base language" do
        expect(negotiator.negotiate(%w[en-US])).to eq(%w[en])
      end

      it "matches ja-JP to ja" do
        expect(negotiator.negotiate(%w[ja-JP])).to eq(%w[ja])
      end

      it "returns empty for no match" do
        expect(negotiator.negotiate(%w[zh-CN])).to eq([])
      end
    end

    context "with regional variants available" do
      let(:negotiator) { Rack::ICU4X::Negotiator.new(%w[en-US en-GB ja]) }

      it "matches exact regional variant" do
        expect(negotiator.negotiate(%w[en-GB])).to eq(%w[en-GB])
      end

      it "matches different region to first available of same language" do
        expect(negotiator.negotiate(%w[en-AU])).to eq(%w[en-US])
      end

      it "prefers exact match over partial" do
        expect(negotiator.negotiate(%w[en-GB en-US])).to eq(%w[en-GB en-US])
      end
    end

    context "with script variants" do
      let(:negotiator) { Rack::ICU4X::Negotiator.new(%w[zh-Hans zh-Hant]) }

      it "infers script from region (CN -> Hans)" do
        expect(negotiator.negotiate(%w[zh-CN])).to eq(%w[zh-Hans])
      end

      it "infers script from region (TW -> Hant)" do
        expect(negotiator.negotiate(%w[zh-TW])).to eq(%w[zh-Hant])
      end

      it "matches explicit script" do
        expect(negotiator.negotiate(%w[zh-Hant])).to eq(%w[zh-Hant])
      end
    end

    context "with politically sensitive Chinese variants (CRITICAL)" do
      context "when only zh-CN (Simplified) is available" do
        let(:negotiator) { Rack::ICU4X::Negotiator.new(%w[zh-CN]) }

        it "does NOT match zh-TW (Taiwan) to zh-CN" do
          expect(negotiator.negotiate(%w[zh-TW])).to eq([])
        end

        it "does NOT match zh-HK (Hong Kong) to zh-CN" do
          expect(negotiator.negotiate(%w[zh-HK])).to eq([])
        end

        it "does NOT match zh-Hant to zh-CN" do
          expect(negotiator.negotiate(%w[zh-Hant])).to eq([])
        end

        it "matches zh-CN exactly" do
          expect(negotiator.negotiate(%w[zh-CN])).to eq(%w[zh-CN])
        end

        it "matches zh (defaults to Hans-CN) to zh-CN" do
          expect(negotiator.negotiate(%w[zh])).to eq(%w[zh-CN])
        end
      end

      context "when only zh-TW (Traditional) is available" do
        let(:negotiator) { Rack::ICU4X::Negotiator.new(%w[zh-TW]) }

        it "does NOT match zh-CN (PRC) to zh-TW" do
          expect(negotiator.negotiate(%w[zh-CN])).to eq([])
        end

        it "does NOT match zh-Hans to zh-TW" do
          expect(negotiator.negotiate(%w[zh-Hans])).to eq([])
        end

        it "matches zh-HK (Hong Kong, also Hant) to zh-TW" do
          expect(negotiator.negotiate(%w[zh-HK])).to eq(%w[zh-TW])
        end

        it "matches zh-Hant to zh-TW" do
          expect(negotiator.negotiate(%w[zh-Hant])).to eq(%w[zh-TW])
        end
      end
    end

    context "with politically sensitive Serbian variants" do
      context "when only sr-Cyrl is available" do
        let(:negotiator) { Rack::ICU4X::Negotiator.new(%w[sr-Cyrl]) }

        it "does NOT match sr-Latn to sr-Cyrl" do
          expect(negotiator.negotiate(%w[sr-Latn])).to eq([])
        end

        it "matches sr (defaults to Cyrl) to sr-Cyrl" do
          expect(negotiator.negotiate(%w[sr])).to eq(%w[sr-Cyrl])
        end
      end

      context "when only sr-Latn is available" do
        let(:negotiator) { Rack::ICU4X::Negotiator.new(%w[sr-Latn]) }

        it "does NOT match sr-Cyrl to sr-Latn" do
          expect(negotiator.negotiate(%w[sr-Cyrl])).to eq([])
        end

        it "does NOT match bare sr (defaults to Cyrl) to sr-Latn" do
          expect(negotiator.negotiate(%w[sr])).to eq([])
        end
      end
    end
  end

  describe "available_locales with ICU4X::Locale instances" do
    context "with Locale instances only" do
      let(:locales) { [ICU4X::Locale.parse("en"), ICU4X::Locale.parse("ja")] }
      let(:negotiator) { Rack::ICU4X::Negotiator.new(locales) }

      it "accepts ICU4X::Locale instances" do
        expect(negotiator.negotiate(%w[ja])).to eq(%w[ja])
      end

      it "matches region variant to base language" do
        expect(negotiator.negotiate(%w[en-US])).to eq(%w[en])
      end
    end

    context "with mixed String and Locale instances" do
      let(:locales) { ["en", ICU4X::Locale.parse("ja")] }
      let(:negotiator) { Rack::ICU4X::Negotiator.new(locales) }

      it "accepts mixed array" do
        expect(negotiator.negotiate(%w[ja en])).to eq(%w[ja en])
      end
    end
  end
end
