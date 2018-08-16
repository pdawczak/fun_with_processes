defmodule FWP.Downloader.StreamServer do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    file_url = Keyword.fetch!(opts, :file_url)
    dir = Keyword.fetch!(opts, :dir)
    engine = Keyword.get(opts, :engine, HTTPoison)

    state = %{
      file_url: file_url,
      dir: dir,
      engine: engine,
      file_path: nil,
      file: nil
    }

    {:ok, state, {:continue, :init_download}}
  end

  def handle_continue(:init_download, state) do
    {:ok, %HTTPoison.AsyncResponse{}} = state.engine.get(state.file_url, [], stream_to: self())

    file_path = Utils.file_path_for(state.file_url, state.dir)

    file = Utils.open_file(file_path)

    new_state = %{state | file_path: file_path, file: file}

    {:noreply, new_state}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: chunk}, state) do
    Logger.debug("Receiving chunk...")

    IO.binwrite(state.file, chunk)

    {:noreply, state}
  end

  def handle_info(%HTTPoison.Error{reason: reason}, state) do
    Logger.error("Failed to download the file: #{inspect(reason)}")

    File.close(state.file)
    File.rm(state.file_path)

    {:stop, {:shutdown, reason}, state}
  end

  def handle_info(%HTTPoison.AsyncEnd{}, state) do
    Logger.info("That's all folks!")

    File.close(state.file)

    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Received: #{inspect(msg)}")

    {:noreply, state}
  end
end
