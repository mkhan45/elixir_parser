defmodule ElixirParseTest do
  use ExUnit.Case
  doctest Scanner
  doctest Parser

  test "atom" do
    assert "5" |> Parser.parse() |> Expr.eval() == 5
  end

  test "two_term" do
    assert "5 + 3" |> Parser.parse() |> Expr.eval() == 8
  end

  test "three_term" do
    assert "5 + 3 * 2" |> Parser.parse() |> Expr.eval() == 11
  end

  test "four_term" do
    assert "5 / 2 + 3 * 2" |> Parser.parse() |> Expr.eval() == 8.5
  end

  test "parens" do
    assert "5 / (2 + 3) * 2" |> Parser.parse() |> Expr.eval() == 2
  end
end
