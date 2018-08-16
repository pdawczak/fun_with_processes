defmodule Utils do
  def file_path_for(img_url, dir) do
    img_url
    |> URI.parse()
    |> (& &1.path).()
    |> Path.basename()
    |> (&Path.join([dir, &1])).()
  end

  def open_file(file_path) do
    file_path
    |> Path.dirname()
    |> File.mkdir_p()

    File.open!(file_path, [:binary, :write])
  end

  def open_file_for(url, dir) do
    url
    |> file_path_for(dir)
    |> open_file()
  end
end
