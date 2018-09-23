defmodule SHExTest do
  use ExUnit.Case
  doctest SHEx

  test "greets the world" do
    assert SHEx.hello() == :world
  end
end
