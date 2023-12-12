defmodule HexdumpTest do
  use ExUnit.Case
  doctest Hexdump

  describe "format_hexdump_output/2" do
    test "adds padding to binary" do
      assert "abcd"
             |> Hexdump.format_hexdump_output()
             |> Hexdump.remove_escapes() ==
               """
                 0000000:  6162 6364                                 abcd
               """
               |> String.trim_trailing()
    end

    test "prints multiline" do
      assert "1234567890abcdef1234567890abcdef"
             |> Hexdump.format_hexdump_output()
             |> Hexdump.remove_escapes() ==
               """
                 0000000:  3132 3334 3536 3738 3930 6162 6364 6566   1234567890abcdef
                 0000010:  3132 3334 3536 3738 3930 6162 6364 6566   1234567890abcdef
               """
               |> String.trim_trailing()
    end
  end

  describe "hexdump_output/2" do
    test "prints multiline with header" do
      assert ("1234567890abcdef1234567890abcdef" <>
                "1234567890abcdef1234567890abcdef" <> "1234567890abcdef1234567890abcdef")
             |> Hexdump.hexdump_output(printable_limit: 32)
             |> Hexdump.remove_escapes() ==
               """
                  offset    0 1  2 3  4 5  6 7  8 9  A B  C D  E F    printable data
                 0000000:  3132 3334 3536 3738 3930 6162 6364 6566   1234567890abcdef
                 0000010:  3132 3334 3536 3738 3930 6162 6364 6566   1234567890abcdef
                 **
                 0000050:  3132 3334 3536 3738 3930 6162 6364 6566   1234567890abcdef
               """
               |> String.trim_trailing()
    end
  end
end
