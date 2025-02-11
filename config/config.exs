import Config

environment_file_path = "#{config_env() |> Atom.to_string()}.exs"

if File.exists?(Path.join(__DIR__, environment_file_path)) do
  import_config(environment_file_path)
end
