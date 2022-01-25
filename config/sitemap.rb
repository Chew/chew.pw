SitemapGenerator::Sitemap.default_host = 'https://chew.pw'
SitemapGenerator::Sitemap.compress = false
SitemapGenerator::Sitemap.create do
  add '/', changefreq: 'daily'
  add '/sitemap', changefreq: 'daily'
  add '/chewbotcca', changefreq: 'weekly'
  add '/chewbotcca/discord', changefreq: 'weekly'
  add '/chewbotcca/discord/commands', changefreq: 'daily'
  add '/chewbotcca/discord/privacy', changefreq: 'monthly'
  add '/chewbotcca/slack', changefreq: 'weekly'
  add '/chewbotcca/slack/privacy', changefreq: 'monthly'
  add '/cookiesinc', changefreq: 'monthly'
  add '/cookiesinc/teams/top', changefreq: 'daily'
  add '/discord/servers', changefreq: 'weekly'
  add '/discord/connections', changefreq: 'weekly'
  add '/discord/webhooks', changefreq: 'weekly'
  add '/hqbot', changefreq: 'weekly'
  add '/hqbot/authkey', changefreq: 'weekly'
  add '/mc', changefreq: 'weekly'
  add '/mc/enchant', changefreq: 'weekly'
  add '/mc/log', changefreq: 'weekly'
  add '/mc/jars', changefreq: 'daily'
  add '/mc/log', changefreq: 'weekly'
  add '/roblox', changefreq: 'monthly'
  add '/roblox/badges', changefreq: 'monthly'
  add '/util/html', changefreq: 'weekly'
  add '/util/random', changefreq: 'weekly'
  add '/util/wordle', changefreq: 'weekly'
  add '/vaccine', changefreq: 'daily'
end