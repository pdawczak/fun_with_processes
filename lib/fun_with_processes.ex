defmodule FWP do
  def download(file_url) do
    dir = Application.get_env(:fun_with_processes, :downloads_dir)

    FWP.Downloader.StreamServer.start_link(file_url: file_url, dir: dir)
  end
end
