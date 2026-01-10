# frozen_string_literal: true

require "rack/icu4x/locale"
require "sinatra/base"

# Demo application for Rack::ICU4X::Locale middleware
class DemoApp < Sinatra::Base
  enable :inline_templates

  AVAILABLE_LOCALES = %w[en ja de fr].freeze
  private_constant :AVAILABLE_LOCALES

  get "/" do
    @available_locales = AVAILABLE_LOCALES
    @accept_language = request.env["HTTP_ACCEPT_LANGUAGE"]
    @cookie_locale = request.cookies["locale"]
    @detected_locales = request.env[Rack::ICU4X::Locale::ENV_KEY]

    erb :index
  end

  post "/set_locale" do
    locale = params[:locale]
    if AVAILABLE_LOCALES.include?(locale)
      response.set_cookie("locale", value: locale, path: "/")
    end
    redirect "/"
  end

  post "/clear_locale" do
    response.delete_cookie("locale", path: "/")
    redirect "/"
  end
end

__END__

@@ layout
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Rack::ICU4X::Locale Demo</title>
  <style>
    body { font-family: sans-serif; max-width: 800px; margin: 2em auto; padding: 0 1em; }
    h1 { color: #333; }
    table { border-collapse: collapse; width: 100%; margin: 1em 0; }
    th, td { border: 1px solid #ddd; padding: 0.75em; text-align: left; }
    th { background: #f5f5f5; }
    form { margin: 1em 0; }
    select, button { padding: 0.5em 1em; font-size: 1em; }
    button { cursor: pointer; }
    .locale-list { list-style: decimal; padding-left: 2em; }
    .locale-list li { margin: 0.25em 0; }
  </style>
</head>
<body>
  <%= yield %>
</body>
</html>

@@ index
<h1>Rack::ICU4X::Locale Demo</h1>

<table>
  <tr>
    <th>Available Locales</th>
    <td><%= @available_locales.join(", ") %></td>
  </tr>
  <tr>
    <th>Accept-Language Header</th>
    <td><%= @accept_language || "(not set)" %></td>
  </tr>
  <tr>
    <th>Cookie Locale</th>
    <td><%= @cookie_locale || "(not set)" %></td>
  </tr>
  <tr>
    <th>Detected Locales (preference order)</th>
    <td>
      <ol class="locale-list">
        <% @detected_locales.each do |locale| %>
          <li><%= locale.to_s %></li>
        <% end %>
      </ol>
    </td>
  </tr>
</table>

<h2>Change Locale</h2>

<form action="/set_locale" method="post">
  <select name="locale">
    <% @available_locales.each do |locale| %>
      <option value="<%= locale %>" <%= "selected" if @detected_locales.first&.to_s == locale %>><%= locale %></option>
    <% end %>
  </select>
  <button type="submit">Set Locale (Cookie)</button>
</form>

<form action="/clear_locale" method="post">
  <button type="submit">Clear Locale Cookie</button>
</form>
