module SolitaireHelper
  # Converts a difficulty integer to a friendly string
  # @param [Integer] int The difficulty from the API
  # @return [String] The friendly string
  def difficulty(int)
    case int
    when 1
      "Easy"
    when 2
      "Medium"
    when 3
      "Hard"
    when 4
      "Expert"
    else
      "Unknown"
    end
  end

  # Converts raw data from MS into friendly data! What's displayed in the app.
  # @param [Hash] data The data
  # @return [String, Hash] The friendly string or a hash if no data is found
  def friendly_challenge(data)
    case data['GameMode']
    when "Klondike"
      return friendly_klondike_challenge data
    when "Spider"
      return friendly_spider_challenge data
    when "FreeCell"
      return friendly_freecell_challenge data
    when "Pyramid"
      return friendly_pyramid_challenge data
    when "TriPeaks"
      return friendly_pyramid_challenge data
    else
      return data
    end
  end

  # Converts raw data from MS into friendly data! What's displayed in the app.
  # @param [Hash] data The data
  # @return [String, Hash] The friendly string or a hash if no data is found
  def friendly_klondike_challenge(data)
    if data['PARAM_SCOREREQUIRED']
      "Earn a score of #{data['PARAM_SCOREREQUIRED']}"
    elsif data['PARAM_CARDTOPLAY']
      card = data['PARAM_CARDTOPLAY']
      suit = case card.split('')[-1]
             when 'c'
               "Clubs"
             when 'h'
               "Hearts"
             when 'd'
               "Diamonds"
             when 's'
               "Spades"
             else
               "???"
             end

      "Clear the #{card.split('')[0...-1].join('')} of #{suit} from the board"
    elsif data['PARAM_NUMTOPLAY']
      "Clear #{data['PARAM_NUMTOPLAY']} #{data['PARAM_VALUETOPLAY']}s from the board"
    elsif data['CHDEF_ChallengeName'] == "Solve Challenge"
      "Solve the deck"
    else
      data
    end
  end

  # Converts raw data from MS into friendly data! What's displayed in the app.
  # @param [Hash] data The data
  # @return [String, Hash] The friendly string or a hash if no data is found
  def friendly_spider_challenge(data)
    if data['PARAM_STACKSREQUIRED']
      "Complete #{data['PARAM_STACKSREQUIRED']} stacks"
    elsif data['PARAM_SCOREREQUIRED']
      "Earn a score of #{data['PARAM_SCOREREQUIRED']}"
    elsif data['CHDEF_ChallengeName'] == "Solve Challenge"
      "Solve the deck"
    else
      data
    end
  end

  # Converts raw data from MS into friendly data! What's displayed in the app.
  # @param [Hash] data The data
  # @return [String, Hash] The friendly string or a hash if no data is found
  def friendly_freecell_challenge(data)
    if data['PARAM_CARDTOPLAY']
      card = data['PARAM_CARDTOPLAY']
      suit = case card.split('')[-1]
             when 'c'
               "Clubs"
             when 'h'
               "Hearts"
             when 'd'
               "Diamonds"
             when 's'
               "Spades"
             else
               "???"
             end

      "Clear the #{card.split('')[0...-1].join('')} of #{suit} from the board"
    elsif data['PARAM_NUMBERTOPLAY']
      "Clear #{data['PARAM_NUMBERTOPLAY']} #{data['PARAM_VALUETOPLAY']}s from the board"
    elsif data['CHDEF_ChallengeName'] == "Solve Challenge"
      "Solve the deck"
    else
      data
    end
  end

  # Converts raw data from MS into friendly data! What's displayed in the app.
  # @param [Hash] data The data
  # @return [String, Hash] The friendly string or a hash if no data is found
  def friendly_pyramid_challenge(data)
    if data['CHDEF_ChallengeName'] == "Card Challenge"
      "Clear #{data['PARAM_NUMBERTOPLAY']} #{data['PARAM_VALUETOPLAY']}s in #{data['PARAM_MAXDEALS']} deal(s)"
    elsif data['PARAM_SCOREREQUIRED']
      "Earn a score of #{data['PARAM_SCOREREQUIRED']}"
    elsif data['PARAM_BOARDSTOCLEAR']
      "Clear #{data['PARAM_BOARDSTOCLEAR']} boards in #{data['PARAM_MAXDEALS']} deal(s)"
    else
      data
    end
  end
end
