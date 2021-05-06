defmodule Scanner do
  @type token :: atom | {:number, number} | {:ident, String.t()}

  @doc """
      iex> Scanner.scan({:number, "35"})
      [{:number, 35}]

      iex> Scanner.scan("hello world")
      [{:ident, "hello"}, {:ident, "world"}]

      iex> Scanner.scan("1 + 2")
      [{:number, 1}, :add, {:number, 2}]

      iex> Scanner.scan("1 + abc")
      [{:number, 1}, :add, {:ident, "abc"}]

      iex> Scanner.scan("(1 + 3)")
      [:lparen, {:number, 1}, :add, {:number, 3}, :rparen]
  """
  @spec scan({:number, String.t()}) :: [{:number, number}]
  def scan({:number, inp}) do
    {x, xs} = Integer.parse(inp)
    [{:number, x}] ++ scan(xs)
  end

  @spec scan({:ident, String.t()}) :: [{:ident, String.t()}]
  def scan({:ident, inp}) do
    case String.split(inp, " ", parts: 2) do
      [lex] -> [{:ident, lex}]
      [lex, xs] -> [{:ident, lex}] ++ scan(xs)
    end
  end

  @spec scan(String.t()) :: [token]
  def scan(inp) do
    case String.next_grapheme(inp) do
      nil -> []
      {" ", xs} -> scan(xs)
      {"\t", xs} -> scan(xs)
      {"+", xs} -> [:add] ++ scan(xs)
      {"-", xs} -> [:sub] ++ scan(xs)
      {"*", xs} -> [:mul] ++ scan(xs)
      {"/", xs} -> [:div] ++ scan(xs)
      {"(", xs} -> [:lparen] ++ scan(xs)
      {")", xs} -> [:rparen] ++ scan(xs)
      {x, _} when "0" <= x and x <= "9" -> scan({:number, inp})
      {x, _} when "a" <= x and x <= "z" -> scan({:ident, inp})
    end
  end
end

defmodule Expr do
  defmodule BinaryExpr do
    defstruct [:op, :lhs, :rhs]
    @type t :: %BinaryExpr{op: atom, lhs: Expr.t(), rhs: Expr.t()}
  end

  @doc """
      iex> Expr.eval(12)
      12

      iex> Expr.eval(%BinaryExpr{op: :mul, lhs: 5, rhs: %BinaryExpr{op: sub, lhs: 10, rhs: 2}})
      40
  """
  @spec eval(BinaryExpr.t()) :: number
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
  @type t :: atomic | BinaryExpr.t()
end

defmodule Parser do
  @spec op_bp(atom) :: {integer, integer}
  def op_bp(op) do
    case op do
      op when op in [:add, :sub] -> {4, 5}
      op when op in [:mul, :div] -> {6, 7}
    end
  end

  defmacro is_op(a) do
    quote do: unquote(a) in [:add, :sub, :mul, :div]
  end

  defp complete_expr(lhs, [], _min_bp) do
    {lhs, []}
  end

  @spec complete_expr(Expr.t(), [Scanner.token()], integer) :: {Expr.t(), [Scanner.token()]}
  defp complete_expr(lhs, [nx | _] = ls, _min_bp) when not is_op(nx) do
    {lhs, ls}
  end

  defp complete_expr(lhs, [nx | xs] = ls, min_bp) do
    {l_bp, r_bp} = op_bp(nx)

    if l_bp < min_bp do
      {lhs, ls}
    else
      {rhs, rem} = expr_bp(xs, r_bp)
      complete = %Expr.BinaryExpr{op: nx, lhs: lhs, rhs: rhs}
      complete_expr(complete, rem, min_bp)
    end
  end

  @spec expr_bp([Scanner.token()], integer) :: {Expr.t(), [Scanner.token()]}
  def expr_bp([nx | xs], min_bp) do
    {lhs, rest} =
      case nx do
        :lparen ->
          {paren_expr, temp} = expr_bp(xs, 0)

          if temp == [] or hd(temp) != :rparen do
            throw("Mismatched parentheses")
          end

          {paren_expr, tl(temp)}

        {:number, n} ->
          {n, xs}
      end

    complete_expr(lhs, rest, min_bp)
  end

  @doc """
      iex> Parser.parse "5"
      5

      iex> Parser.parse "5 + 2"
      %Expr.BinaryExpr{op: :add, lhs: 5, rhs: 2}

      iex> Parser.parse "5 + 2 * 3"
      %Expr.BinaryExpr{op: :add, lhs: 5, rhs: %Expr.BinaryExpr{op: :mul, lhs: 2, rhs: 3}}

      iex> Parser.parse "10 / 2 + 5 * 3"
      %Expr.BinaryExpr{op: :add, lhs: %Expr.BinaryExpr{op: :div, lhs: 10, rhs: 2}, rhs: %Expr.BinaryExpr{op: :mul, lhs: 5, rhs: 3}}

      iex> Parser.parse "10 / (2 + 5) * 3"
      %Expr.BinaryExpr{op: :mul, lhs: %Expr.BinaryExpr{lhs: 10, op: :div, rhs: %Expr.BinaryExpr{lhs: 2, op: :add, rhs: 5}}, rhs: 3}
  """
  @spec parse(String.t()) :: Expr.t()
  def parse(s) do
    tokens = Scanner.scan(s)
    {res, _} = expr_bp(tokens, 0)
    res
  end
end

defmodule Main do
  def main(args) do
    args |> Enum.join(" ") |> Parser.parse() |> Expr.eval() |> IO.puts()
  end
end
