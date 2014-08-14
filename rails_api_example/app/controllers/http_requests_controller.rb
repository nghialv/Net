class HttpRequestsController < ApplicationController
  def get_json
    data = {name: 'nghialv', github: 'https://github.com/nghialv', parameters: params}
    render json: data
  end

  def post_url_encoded
    result = {status: 'ok', parameters: params}
    render json: result
  end

  def post_multi_part
    result = {status: 'ok'}
    render json: result
  end
end
