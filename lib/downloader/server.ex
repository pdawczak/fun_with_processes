defmodule FWP.Downloader.Server do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    file_url = Keyword.fetch!(opts, :file_url)
    dir = Keyword.fetch!(opts, :dir)

    state = %{
      file_url: file_url,
      dir: dir
    }

    {:ok, state, {:continue, :download}}
  end

  def handle_continue(:download, state) do
    {:ok, %{body: body}} = HTTPoison.get(state.file_url)

    file =
      state.file_url
      |> Utils.file_path_for(state.dir)
      |> Utils.open_file()

    IO.binwrite(file, body)

    File.close(file)

    Logger.info("That's all folks!")

    {:stop, :normal, state}
  end
end
