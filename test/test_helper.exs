ExUnit.start()

__DIR__
|> Path.join("support/**/*.ex")
|> Path.wildcard()
|> Enum.each(&Code.require_file/1)
