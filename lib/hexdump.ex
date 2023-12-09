defmodule Hexdump do
  @moduledoc """
  Hexdump makes it easier to work with binary data
  By default elixir display binaries as a list of integers in the range from 0..255
  This make it problematic to spot binary patterns
  our example binary:
  ```
  term = <<0,1,2,3,4>> <> "123abcdefxyz" <> <<253,254,255>>
  ```

  ```
  <<0, 1, 2, 3, 4, 49, 50, 51, 97, 98, 99, 100, 101, 102, 120, 121, 122, 253, 254,
  255>>
  ```

  You can pass a param to IO.inspect(term, base: :hex) to print the same term as hex,
  this makes it a bit easier.

  ```
  <<0x0, 0x1, 0x2, 0x3, 0x4, 0x31, 0x32, 0x33, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66,
  0x78, 0x79, 0x7A, 0xFD, 0xFE, 0xFF>>
  ```

  With Hexdump you can see similar output like hex editors have:
  The first column is offset
  second shows a row of 16 bits in binary
  last column shows printable characers

  ```
  0000000  0001 0203 0431 3233 6162 6364 6566 7879   .....123abcdefxy
  0000010  7AFD FEFF                                 z...
  ```

  You can switch between hexdump output by calling:
  ```
  Hexdump.on()
  Hexdump.off()
  Hexdump.on(binaries: :infer)
  Hexdump.on(binaries: :as_strings)
  ```
  """
  @printable_range 0x20..0x7F
  @column_divider "  "
  @newline "\n"

  @doc """
  restores previous inspect function
  """
  def off do
    Inspect.Opts.default_inspect_fun(&Inspect.inspect/2)
  end

  @default_hexdump_inspect_opts %Inspect.Opts{printable_limit: 500, binaries: :as_binaries}
  def on(opts \\ @default_hexdump_inspect_opts) do
    opts =
      case opts do
        opts when is_struct(opts) -> Map.from_struct(opts)
        opts when is_list(opts) -> Map.new(opts)
        opts -> opts
      end

    Inspect.Opts.default_inspect_fun(&hexdump_inspect_fun(&1, struct(&2, opts)))
  end

  def hexdump_inspect_fun(term, opts) when not is_binary(term) do
    Inspect.inspect(term, %{opts | base: :hex})
  end

  def hexdump_inspect_fun(term, opts) do
    %Inspect.Opts{binaries: bins, printable_limit: printable_limit} = opts

    if bins == :as_strings or
         (bins == :infer and String.printable?(term, printable_limit)) do
      Inspect.inspect(term, opts)
    else
      @newline <> format_hexdump_output(term, opts) <> @newline
    end
  end

  def format_hexdump_output(term, opts \\ @default_hexdump_inspect_opts) do
    {:ok, string_io} = StringIO.open(term)

    result =
      string_io
      |> IO.binstream(2)
      |> Stream.take(opts.printable_limit)
      |> Stream.chunk_every(8)
      |> Stream.map(
        &{
          # generates the text: AABB CCDD EEFF 1122 3344 5566 7788 9900
          Enum.map_join(&1, " ", fn two_chars -> Base.encode16(two_chars) end),
          # generates the text: abc...def1234567
          for <<char::size(8) <- Enum.join(&1, "")>> do
            if Enum.member?(@printable_range, char), do: <<char>>, else: "."
          end
        }
      )
      |> Stream.with_index()
      |> Enum.map_join(@newline, fn {{chunk, original_text}, index} ->
        [
          # generates the first column 00001
          String.pad_leading("#{index}", 6, "0"),
          # last 0 and divider in the first column
          "0:",
          @column_divider,
          # empty spaces for the last row when it's not full width
          String.pad_trailing(chunk, 40, " "),
          @column_divider,
          original_text
        ]
      end)

    StringIO.close(string_io)
    result
  end
end
