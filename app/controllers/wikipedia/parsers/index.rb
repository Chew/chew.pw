# frozen_string_literal: true
require_relative 'genealogybank.com.rb'
require_relative 'mlb.com.rb'
require_relative 'mlb.mlb.com.rb'
require_relative 'mlbtraderumors.com.rb'
require_relative 'newspapers.com.rb'
require_relative 'nytimes.com.rb'
require_relative 'washingtonpost.com.rb'

require_relative './util.rb'

PARSERS = %w[genealogybank.com mlb.com mlb.mlb.com mlbtraderumors.com newspapers.com nytimes.com washingtonpost.com].freeze