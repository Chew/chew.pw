require "uri"
require "net/http"

class Utils
  def self.simulate_browser(url)
    url = URI(url)

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
    request["accept-language"] = "en-US,en;q=0.9"
    request["cache-control"] = "no-cache"
    request["dnt"] = "1"
    request["pragma"] = "no-cache"
    request["priority"] = "u=0, i"
    request["sec-ch-ua"] = "\"Not?A_Brand\";v=\"99\", \"Chromium\";v=\"130\""
    request["sec-ch-ua-mobile"] = "?0"
    request["sec-ch-ua-platform"] = "\"macOS\""
    request["sec-fetch-dest"] = "document"
    request["sec-fetch-mode"] = "navigate"
    request["sec-fetch-site"] = "cross-site"
    request["sec-fetch-user"] = "?1"
    request["upgrade-insecure-requests"] = "1"
    request["user-agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"

    response = https.request(request)

    response.read_body
  end
end
