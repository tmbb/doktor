defmodule DoktorTest do
  use ExUnit.Case
  doctest Doktor

  test "greets the world" do
    assert Doktor.hello() == :world
  end
end
