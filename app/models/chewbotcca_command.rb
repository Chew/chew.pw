class ChewbotccaCommand < ApplicationRecord
  # The prefix of the command.
  def prefix
    slash ? '/' : '%^'
  end

  def invocation
    "#{prefix}#{command}"
  end
end
