System.argv |> Enum.join(" ") |> Parser.parse |> Expr.eval |> IO.puts
