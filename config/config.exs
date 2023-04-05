import Config

environment_file_path = "#{Mix.env() |> Atom.to_string()}.exs"

if File.exists?(environment_file_path) do
  import_config(environment_file_path)
end
