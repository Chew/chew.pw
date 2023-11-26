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
  add '/discord/servers', changefreq: 'weekly'
  add '/discord/connections', changefreq: 'weekly'
  add '/discord/webhooks', changefreq: 'weekly'
  add '/games/cookiesinc', changefreq: 'monthly'
  add '/games/cookiesinc/teams/top', changefreq: 'daily'
  add '/games/nytimes', changefreq: 'weekly'
  add '/games/nytimes/wordle', changefreq: 'weekly'
  add '/games/nytimes/connections', changefreq: 'daily'
  add '/games/roblox', changefreq: 'monthly'
  add '/games/roblox/badges', changefreq: 'monthly'
  add '/games/solitaire/challenges', changefreq: 'monthly'
  add '/mc', changefreq: 'weekly'
  add '/mc/enchant', changefreq: 'weekly'
  add '/mc/log', changefreq: 'weekly'
  add '/mc/jars', changefreq: 'daily'
  add '/mc/log', changefreq: 'weekly'
  add '/util/html', changefreq: 'weekly'
  add '/util/random', changefreq: 'weekly'
  add '/util/bases', changefreq: 'daily'
  add '/vaccine', changefreq: 'daily'
  add '/sports/mlb', changefreq: 'daily'
end