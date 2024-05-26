class UtilitiesController < ApplicationController
  def strippedhtml
    @response = Nokogiri::HTML.parse(params['input']).text
  end

  def calculate_aa
    # determine multiplier
    @multiplier = 1

    # basic_economy and aadvantage_card are checkboxes
    @basic_economy = params['basic_economy'] == '1'
    @aadvantage_card = params['aadvantage_card'] == '1'

    @loyalty_points = params['current_loyalty'].to_i
    @pre_tax_cost = params['before_tax'].to_i
    @total_cost = params['with_tax'].to_i

    @status = "None"
    @bonus = 0

    if @basic_economy
      @multiplier = 2
    elsif @loyalty_points >= 200000
      @multiplier = 11
      @status = "Executive Platinum"
      @bonus = 120
    elsif @loyalty_points >= 125000
      @multiplier = 9
      @status = "Platinum Pro"
      @bonus = 80
    elsif @loyalty_points >= 75000
      @multiplier = 8
      @status = "Platinum"
      @bonus = 60
    elsif @loyalty_points >= 40000
      @multiplier = 7
      @status = "Gold"
      @bonus = 40
    else
      @multiplier = 5
    end

    @points_from_ticket = @pre_tax_cost * @multiplier
    @points_from_card = @aadvantage_card ? @total_cost : 0
  end
end
