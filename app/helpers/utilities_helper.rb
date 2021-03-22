module UtilitiesHelper
  def type(name)
    if @states.include? name
      "State"
    elsif @territories.include? name
      "Territory"
    else
      "Misc"
    end
  end
end
