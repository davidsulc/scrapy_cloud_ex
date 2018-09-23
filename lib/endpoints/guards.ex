defmodule SHEx.Endpoints.Guards do
  defguard is_api_key(key) when is_binary(key)

  defguard is_project_id(id) when is_binary(id) or is_integer(id)

  defguard is_job_id(id) when is_binary(id)
end
