for line <- Path.join(__DIR__, "define_test_scope.sql") |> File.read!() |> String.split("\n") do
  unless String.starts_with?(line, "--") do
    IO.puts("RUNNING: #{line}")

    System.shell(
      "echo \"#{line}\" | surreal sql --conn http://127.0.0.1:8000 --user root --pass root --ns test --db test"
    )
  end
end
