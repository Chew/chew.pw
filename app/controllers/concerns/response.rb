module Response
  # A simple user-input error response
  # @param error [String] An error to provide
  def json_error_response(error)
    json_response({ error: error, success: false }, 400)
  end

  def json_response(object, status = :ok)
    render json: object, status: status
  end
end
