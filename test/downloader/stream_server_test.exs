defmodule FWP.Downloader.StreamServerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias FWP.Downloader.StreamServer

  @test_dir Path.expand("../tmp/downloads", __DIR__)

  defmodule HTTPMock do
    def get(_url, _params, _opts) do
      {:ok, %HTTPoison.AsyncResponse{}}
    end
  end

  @tag :capture_log
  test "accepts chunks and writes them to the file" do
    url = "http://foo.com/test-success.txt"
    file_path = Utils.file_path_for("test-success.txt", @test_dir)
    File.rm_rf!(file_path)

    Process.flag(:trap_exit, true)
    {:ok, server} = StreamServer.start_link(file_url: url, dir: @test_dir, engine: HTTPMock)

    send(server, %HTTPoison.AsyncChunk{chunk: [?H, ?e]})
    send(server, %HTTPoison.AsyncChunk{chunk: [?l]})
    send(server, %HTTPoison.AsyncChunk{chunk: [?l, ?o]})
    send(server, %HTTPoison.AsyncEnd{})

    assert_receive {:EXIT, ^server, :normal}
    assert File.exists?(file_path)
    assert File.read!(file_path) == "Hello"
  end

  @tag :capture_log
  test "if at any point there is error occurred, the file will be removed" do
    url = "http://foo.com/test-failure.txt"
    file_path = Utils.file_path_for("test-failure.txt", @test_dir)

    Process.flag(:trap_exit, true)
    {:ok, server} = StreamServer.start_link(file_url: url, dir: @test_dir, engine: HTTPMock)

    send(server, %HTTPoison.AsyncChunk{chunk: [?H, ?e]})

    log =
      capture_log([level: :error], fn ->
        send(server, %HTTPoison.Error{reason: "HOW ABOUT NOPE"})
        assert_receive {:EXIT, ^server, {:shutdown, "HOW ABOUT NOPE"}}
      end)

    assert log =~ "HOW ABOUT NOPE"
    refute File.exists?(file_path)
  end
end
