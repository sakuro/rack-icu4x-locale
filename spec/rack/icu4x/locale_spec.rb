# frozen_string_literal: true

RSpec.describe Rack::ICU4X::Locale do
  let(:app) { ->(env) { [200, {}, [env[Rack::ICU4X::Locale::ENV_KEY].map(&:to_s).join(",")]] } }
  let(:available_locales) { %w[en ja de] }
  let(:middleware) { Rack::ICU4X::Locale.new(app, available_locales:) }

  describe "#call" do
    context "with Accept-Language header" do
      it "returns locales sorted by quality value" do
        env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "ja,en;q=0.9,de;q=0.8")

        middleware.call(env)

        locales = env[Rack::ICU4X::Locale::ENV_KEY]
        expect(locales).to be_an(Array)
        expect(locales.size).to eq(3)
        expect(locales[0].to_s).to eq("ja")
        expect(locales[1].to_s).to eq("en")
        expect(locales[2].to_s).to eq("de")
      end

      it "filters out unavailable locales" do
        env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "fr,ja;q=0.9")

        middleware.call(env)

        locales = env[Rack::ICU4X::Locale::ENV_KEY]
        expect(locales.size).to eq(1)
        expect(locales[0].to_s).to eq("ja")
      end

      it "negotiates region variant to base language" do
        env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "en-US,ja-JP;q=0.9")

        middleware.call(env)

        locales = env[Rack::ICU4X::Locale::ENV_KEY]
        expect(locales.size).to eq(2)
        expect(locales[0].to_s).to eq("en")
        expect(locales[1].to_s).to eq("ja")
      end
    end

    context "without Accept-Language header" do
      it "returns empty array" do
        env = Rack::MockRequest.env_for("/")

        middleware.call(env)

        locales = env[Rack::ICU4X::Locale::ENV_KEY]
        expect(locales).to eq([])
      end
    end

    context "when Accept-Language contains no available locales" do
      it "returns empty array" do
        env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "fr,es")

        middleware.call(env)

        locales = env[Rack::ICU4X::Locale::ENV_KEY]
        expect(locales).to eq([])
      end
    end
  end

  describe "with cookie option" do
    let(:middleware) { Rack::ICU4X::Locale.new(app, available_locales:, cookie: "locale") }

    context "when cookie is set with valid locale" do
      it "returns the locale from cookie" do
        env = Rack::MockRequest.env_for("/", "HTTP_COOKIE" => "locale=ja")

        middleware.call(env)

        locales = env[Rack::ICU4X::Locale::ENV_KEY]
        expect(locales.size).to eq(1)
        expect(locales[0].to_s).to eq("ja")
      end

      it "ignores Accept-Language header when cookie is set" do
        env = Rack::MockRequest.env_for(
          "/",
          "HTTP_COOKIE" => "locale=de",
          "HTTP_ACCEPT_LANGUAGE" => "ja,en;q=0.9"
        )

        middleware.call(env)

        locales = env[Rack::ICU4X::Locale::ENV_KEY]
        expect(locales.size).to eq(1)
        expect(locales[0].to_s).to eq("de")
      end
    end

    context "when cookie is set with unavailable locale" do
      it "falls back to Accept-Language" do
        env = Rack::MockRequest.env_for(
          "/",
          "HTTP_COOKIE" => "locale=fr",
          "HTTP_ACCEPT_LANGUAGE" => "ja"
        )

        middleware.call(env)

        locales = env[Rack::ICU4X::Locale::ENV_KEY]
        expect(locales.size).to eq(1)
        expect(locales[0].to_s).to eq("ja")
      end
    end

    context "when cookie is not set" do
      it "falls back to Accept-Language" do
        env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "de")

        middleware.call(env)

        locales = env[Rack::ICU4X::Locale::ENV_KEY]
        expect(locales.size).to eq(1)
        expect(locales[0].to_s).to eq("de")
      end
    end
  end

  describe "language negotiation" do
    context "with regional variants" do
      let(:middleware) { Rack::ICU4X::Locale.new(app, available_locales: %w[en-US en-GB ja]) }

      it "matches exact regional variant" do
        env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "en-GB")
        _, _, body = middleware.call(env)
        expect(body.first).to eq("en-GB")
      end

      it "falls back to available region" do
        env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "en-AU")
        _, _, body = middleware.call(env)
        expect(body.first).to eq("en-US")
      end

      it "respects quality values" do
        env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "ja;q=0.9,en-US;q=1.0")
        _, _, body = middleware.call(env)
        expect(body.first).to eq("en-US,ja")
      end
    end

    context "with script-sensitive locales (Chinese)" do
      let(:middleware) { Rack::ICU4X::Locale.new(app, available_locales: %w[zh-CN en]) }

      it "does not match zh-TW to zh-CN (different scripts)" do
        env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "zh-TW")
        _, _, body = middleware.call(env)
        expect(body.first).to eq("")
      end

      it "matches zh to zh-CN" do
        env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "zh")
        _, _, body = middleware.call(env)
        expect(body.first).to eq("zh-CN")
      end
    end
  end

  describe "with default option" do
    context "when default is a String" do
      let(:middleware) { Rack::ICU4X::Locale.new(app, available_locales:, default: "en") }

      it "returns default locale when no match is found" do
        env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "fr")

        middleware.call(env)

        locales = env[Rack::ICU4X::Locale::ENV_KEY]
        expect(locales.size).to eq(1)
        expect(locales[0].to_s).to eq("en")
      end

      it "returns matched locales instead of default when match exists" do
        env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "ja")

        middleware.call(env)

        locales = env[Rack::ICU4X::Locale::ENV_KEY]
        expect(locales.size).to eq(1)
        expect(locales[0].to_s).to eq("ja")
      end
    end

    context "when default is an ICU4X::Locale" do
      let(:middleware) { Rack::ICU4X::Locale.new(app, available_locales:, default: ICU4X::Locale.parse("en")) }

      it "returns default locale when no match is found" do
        env = Rack::MockRequest.env_for("/")

        middleware.call(env)

        locales = env[Rack::ICU4X::Locale::ENV_KEY]
        expect(locales.size).to eq(1)
        expect(locales[0].to_s).to eq("en")
      end
    end
  end

  describe "ENV_KEY" do
    it "is set to rack.icu4x.locale" do
      expect(Rack::ICU4X::Locale::ENV_KEY).to eq("rack.icu4x.locale")
    end
  end

  describe "VERSION" do
    it "is defined" do
      expect(Rack::ICU4X::Locale::VERSION).to match(/\A\d+\.\d+\.\d+/)
    end
  end
end
