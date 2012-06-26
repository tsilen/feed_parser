require 'open-uri'
require 'nokogiri'

class FeedParser

  VERSION = "0.3.2"

  USER_AGENT = "Ruby / FeedParser gem"

  class FeedParser::UnknownFeedType < Exception ; end

  def initialize(opts)
    @url = opts[:url]
    @http_options = {"User-Agent" => FeedParser::USER_AGENT}.merge(opts[:http] || {})
    @@sanitizer = (opts[:sanitizer] || SelfSanitizer.new)
    @@fields_to_sanitize = (opts[:fields_to_sanitize] || [:content])
    self
  end

  def self.sanitizer
    @@sanitizer
  end

  def self.fields_to_sanitize
    @@fields_to_sanitize
  end

  def parse
    feed_xml = open_or_follow_redirect(@url)
    @feed ||= Feed.new(feed_xml)
  end

  private

  def open_or_follow_redirect(feed_url)
    uri = URI.parse(feed_url)

    if uri.userinfo
      @http_options[:http_basic_authentication] = [uri.user, uri.password].compact
      uri.userinfo = uri.user = uri.password = nil
    end

    @http_options[:redirect] = true if RUBY_VERSION >= '1.9'

    if uri.scheme
      open(uri.to_s, @http_options)
    else
      open(uri.to_s)
    end
  rescue RuntimeError => ex
    redirect_url = ex.to_s.split(" ").last
    if URI.parse(feed_url).scheme == "http" && URI.parse(redirect_url).scheme == "https"
      open_or_follow_redirect(redirect_url)
    else
      raise ex
    end
  end
end

require 'feed_parser/dsl'
require 'feed_parser/feed'
require 'feed_parser/feed_item'
require 'feed_parser/self_sanitizer'
