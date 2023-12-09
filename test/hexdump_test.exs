defmodule HexdumpTest do
  use ExUnit.Case
  doctest Hexdump

  describe "format_hexdump_output/2" do
    test "adds padding to binary" do
      assert Hexdump.format_hexdump_output("abcd") ==
               "0000000:  6162 6364                                 abcd"
    end

    test "prints multiline" do
      assert Hexdump.format_hexdump_output("1234567890abcdef1234567890abcdef") ==
               """
               0000000:  3132 3334 3536 3738 3930 6162 6364 6566   1234567890abcdef
               0000010:  3132 3334 3536 3738 3930 6162 6364 6566   1234567890abcdef
               """
               |> String.trim()
    end
  end
end
