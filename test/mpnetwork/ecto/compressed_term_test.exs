defmodule Mpnetwork.Ecto.CompressedTermTest do
  # use Mpnetwork.DataCase, async: true
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias Mpnetwork.Ecto.CompressedTerm

  @data "This is a test"
  # NOTE
  # I had to rip out lz4 for now. Here's the original compressed lz4 test data:
  # @ct_data <<1, 20, 0, 0, 0, 240, 5, 131, 109, 0, 0, 0, 14, 84, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116>>
  @ct_data <<0>> <> :erlang.term_to_binary(@data)
  # @ct_data_length String.length(@ct_data)
  
  test "stores a term properly" do
    assert {:ok, @ct_data} == CompressedTerm.dump(@data)
  end

  test "retrieves a term properly" do
    assert {:ok, @data} == CompressedTerm.load(@ct_data)
  end

  test "throws expected runtime error when version byte is unknown" do
    # <<1>> <> without_version = @ct_data
    <<0>> <> without_version = @ct_data
    invalid_ct_version_data = <<99>> <> without_version
    assert_raise(RuntimeError, "Unsupported compression version", fn -> CompressedTerm.load(invalid_ct_version_data) end)
  end

  test "doesn't explode when compressed data is using newly-unsupported version and just returns nil (but also logs)" do
    <<0>> <> without_version = @ct_data
    newly_unsupported_compression = <<1>> <> without_version
    assert capture_log(fn ->
      assert {:ok, nil} == CompressedTerm.load(newly_unsupported_compression)
    end) =~ "CT_error"
  end

  # The following test is only valid if compression is actually used on the binary output of :erlang.term_to_binary,
  # otherwise :erlang.term_to_binary will just throw (which is so unlikely that I just don't want to handle that case for now)

  # @tag capture_log: true
  # test "doesn't explode when compressed data is corrupted and just returns an empty string (but also logs)" do
  #   truncated_ct_data = String.slice(@ct_data, 0..(@ct_data_length - trunc(@ct_data_length/3)))
  #   assert capture_log(fn ->
  #     assert {:ok, ""} == CompressedTerm.load(truncated_ct_data)
  #   end) =~ "CT_error"
  # end

end
