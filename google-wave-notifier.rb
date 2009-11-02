#!/usr/bin/env ruby

# NOTE: Main part of this script is result of inspection on http://thatsmith.com/2009/10/google-wave-add-on-for-firefox 

require "net/https"
require "yaml"

Net::HTTP.class_eval do
  def self.ssl_new(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == "https"  # enable SSL/TLS
      http.use_ssl = true 
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    http
  end
end

module GoogleWave
  class Notifier
    class InboxItem
      def initialize(hash)
        @hash = hash
      end

      def wave_id
        @hash["1"]
      end

      def url
        "https://wave.google.com/wave/#restored:wave:" + self.wave_id.sub("+", "%252B")
      end

      def title
        @hash["9"]["1"]
      end

      def unread_count
        @hash["7"]
      end

      def inspect
        "#<InboxItem: '#{title}' (#{unread_count})>"
      end
    end

    class Inbox
      def initialize(body)
        json = body.match(/var json = (\{\s?"r"\s?:\s?"\^d1".*\});/)[1]
        # tidy json to be capable for the YAML parser
        yaml = json.gsub(/:([^ ])/){ ": #{$1}" }.gsub(/,/, ", ") # FIXME: can't deal with ':' and ',' in key or value
        @hash = YAML.load(yaml)
      end

      def items
        @items ||= @hash["p"]["1"].map{|e| InboxItem.new(e)}
      end

      def unread_items
        self.items.select{|i| i.unread_count > 0}
      end

      def total_unread_count
        self.unread_items.inject(0){|s,i| s += i.unread_count}
      end
    end

    def self.get_inbox(email, password)
      notifier = Notifier.new
      unless ARGV[2]
        notifier.login(email, password)
      end
      notifier.get_inbox
    end

    def login(email, password)
      uri = URI.parse('https://www.google.com/accounts/ClientLogin')
      http = Net::HTTP.ssl_new(uri)

      header = {
        'Content-Type' => 'application/x-www-form-urlencoded',
      }
      data = {
        'accountType' => 'GOOGLE',
        'Email' => email,
        'Passwd' => password,
        'service' => 'wave',
        'source' => 'google-wave-notifier.rb',
      }
      http.start do
        req = Net::HTTP::Post.new(uri.path, header)
        req.form_data = data
        case res = http.request(req)
        when Net::HTTPSuccess
          @login_info = res.body.split(/\n/).inject({}){|h,l| k,v = l.split("="); h.update(k => v)}
        else # FIXME
          
        end
      end
    end

    def get_inbox
      unless ARGV[2]
        uri = URI.parse('https://wave.google.com/wave/?nouacheck&auth=' + @login_info["Auth"])
        http = Net::HTTP.ssl_new(uri)

        response_body = http.start do
          auth_res = http.request_get(uri.path + "?" + uri.query)
          cookie = auth_res["set-cookie"]
          redirect_uri = URI.parse(auth_res["location"])
          
          res = http.request_get(redirect_uri.path + "?" + redirect_uri.query, {"cookie" => cookie})
          res.body
        end
      else
        uri = URI.parse('https://wave.google.com/wave/?nouacheck')
        http = Net::HTTP.ssl_new(uri)

        response_body = http.start do
          res = http.request_get(uri.path + "?" + uri.query, {"cookie" => ARGV[2]})
          res.body
        end
      end
      Inbox.new(response_body)
    end
  end
end


if $0 == __FILE__
  email, password = ARGV
  if !email || !password
    puts "usage:\n  #{$0} email password"
    exit 1
  end

  inbox = GoogleWave::Notifier.get_inbox(email, password)
  #p inbox.items

  # output unread items as a plist
  items = inbox.unread_items.map do |item|
    <<-ITEM
      <dict>
        <key>Title</key>
        <string>#{item.title}</string>
        <key>Unread Count</key>
        <integer>#{item.unread_count}</integer>
        <key>Wave ID</key>
        <string>#{item.wave_id}</string>
        <key>URL</key>
        <string>#{item.url}</string>
      </dict>
    ITEM
  end
  puts <<-PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Total Unread Count</key>
    <integer>#{inbox.total_unread_count}</integer>
    <key>Items</key>
    <array>
#{items.join}
    </array>
  </dict>
</plist>
  PLIST
end
