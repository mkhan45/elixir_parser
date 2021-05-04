defmodule Scanner do
  @type token :: atom | {:number, number} | {:ident, String.t}
  
  @doc """
      iex> Scanner.scan({:number, "35"})
      [{:number, 35}]

      iex> Scanner.scan("hello world")
      [{:ident, "hello"}, {:ident, "world"}]

      iex> Scanner.scan("1 + 2")
      [{:number, 1}, :add, {:number, 2}]

      iex> Scanner.scan("1 + abc")
      [{:number, 1}, :add, {:ident, "abc"}]
  """
  @spec scan({:number, String.t}) :: [{:number, number}]
  def scan({:number, inp}) do
    {x, xs} = Integer.parse(inp)
    [{:number, x}] ++ scan(xs)
  end

  @spec scan({:ident, String.t}) :: [{:ident, String.t}]
  def scan({:ident, inp}) do
    case String.split(inp, " ", parts: 2) do
      [lex] -> [{:ident, lex}]
      [lex, xs] -> [{:ident, lex}] ++ scan(xs)
    end
  end

  @spec scan(String.t) :: [token]
  def scan(inp) do
    case String.next_grapheme inp do
      nil -> []
      {" ", xs} -> scan(xs)
      {"\t", xs} -> scan(xs)
      {"+", xs} -> [:add] ++ scan(xs)
      {"-", xs} -> [:sub] ++ scan(xs)
      {"*", xs} -> [:mul] ++ scan(xs)
      {"/", xs} -> [:div] ++ scan(xs)
      {x, _} when "0" <= x and x <= "9" -> scan({:number, inp})
      {x, _} when "a" <= x and x <= "z" -> scan({:ident, inp})
    end
  end
end

defmodule Expr do
  defmodule BinaryExpr do
    defstruct [:op, :lhs, :rhs]
    @type t :: %BinaryExpr {op: atom, lhs: Expr.t, rhs: Expr.t}
  end

  @doc """
      iex> Expr.eval(12)
      12

      iex> Expr.eval(%BinaryExpr{op: :mul, lhs: 5, rhs: %BinaryExpr{op: sub, lhs: 10, rhs: 2}})
      40
  """
  @spec eval(BinaryExpr.t) :: number
  def eval(%BinaryExpr{} = expr) do
    case expr.op do
      :add -> eval(expr.lhs) + eval(expr.rhs)
      :sub -> eval(expr.lhs) - eval(expr.rhs)
      :mul -> eval(expr.lhs) * eval(expr.rhs)
      :div -> eval(expr.lhs) / eval(expr.rhs)
    end
  end

  @spec eval(atomic) :: number
  def eval(n) do
    n
  end

  @type atomic :: number
  @type t :: atomic | BinaryExpr.t
end

defmodule Parser do
end

defmodule Main do
  use Application
  alias Expr.BinaryExpr, as: BinaryExpr

  def start(_type, _args) do
    # IO.inspect ("5 + 3 + 2 - 17 * 3" |> Scanner.scan)
    IO.inspect (%BinaryExpr{op: :add, lhs: 2, rhs: %BinaryExpr{op: :mul, lhs: 3, rhs: 4}} |> Expr.eval)
    Supervisor.start_link([], strategy: :one_for_one)
  end
end
