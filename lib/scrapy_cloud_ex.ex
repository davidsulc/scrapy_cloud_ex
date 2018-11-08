defmodule ScrapyCloudEx do
  @moduledoc """
  An API wrapper for the [ScrapyCloud API](https://doc.scrapinghub.com/scrapy-cloud.html)
  provided by [ScraphingHub.com](https://scrapinghub.com/)
  """

  @type error_info :: String.t() | invalid_param_error | tagged_error_info
  @type result(type) :: {:ok, type} | tagged_error
  @type tagged_error :: {:error, error_info}
  @type tagged_error_info :: {atom, error_info}
  @type invalid_param_error :: {:invalid_param, tagged_error_info}
end
