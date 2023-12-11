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
  @header "   offset    0 1  2 3  4 5  6 7  8 9  A B  C D  E F    printable data"

  @doc """
  Restores the standard inspect function
  """
  def off do
    Inspect.Opts.default_inspect_fun(&Inspect.inspect/2)
  end

  @doc """
  Enables the custom inspect function
  """
  @default_hexdump_inspect_opts %Inspect.Opts{printable_limit: 5, binaries: :as_binaries}
  def on(opts \\ @default_hexdump_inspect_opts) do
    opts =
      case opts do
        opts when is_struct(opts) -> Map.from_struct(opts)
        opts when is_list(opts) -> Map.new(opts)
        opts -> opts
      end

    Inspect.Opts.default_inspect_fun(&hexdump_inspect_fun(&1, struct(&2, opts)))
  end

  @doc """
  Custom inspect function
  """
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

  @doc """
  Formatter used in the custom inspect function
  colors meaning:

   - grey: zero byte 0x00
   - green: whitespace
   - yellow: ascii non printable
   - red: non ascii char
   - cyan: printable character
  """
  def format_hexdump_output(term, opts \\ @default_hexdump_inspect_opts) do
    {:ok, string_io} = StringIO.open(term)

    result =
      string_io
      |> IO.binstream(1)
      |> Stream.chunk_every(16)
      |> take_or_infinity(opts.printable_limit)
      |> Stream.map(
        &for char <- &1 do
          <<ascii>> = char
          encoded = Base.encode16(char)

          cond do
            # zero byte
            ascii == 0x00 -> [IO.ANSI.light_black(), encoded, "⋄"]
            # space
            ascii == 0x20 -> [IO.ANSI.reset(), encoded, " "]
            # other whitespace
            ascii in [0x09, 0x0A, 0x0C, 0x0D] -> [IO.ANSI.green(), encoded, "_"]
            # non ascii
            ascii > 0x7F -> [IO.ANSI.light_red(), encoded, "×"]
            # ascii printable
            ascii in @printable_range -> [IO.ANSI.cyan(), encoded, char]
            # ascii non printable
            true -> [IO.ANSI.yellow(), encoded, "•"]
          end
        end
      )
      |> Stream.with_index()
      |> Enum.map(fn {chunk, index} ->
        length = length(chunk)

        # add padding to last line when it has less that 16 bytes
        chunk =
          if length < 16 do
            chunk ++ Enum.map(1..(16 - length), fn _ -> ["", "  ", ""] end)
          else
            chunk
          end

        {binary_representation, original_text} =
          chunk
          |> Enum.with_index()
          |> Enum.map(fn {[ascii_color, binary, printable], index} ->
            space = if rem(index, 2) == 1, do: " ", else: ""
            {[ascii_color, binary, space], [ascii_color, printable]}
          end)
          |> Enum.unzip()

        [
          @column_divider,
          # generates the first column 00001
          String.pad_leading("#{index}", 6, "0"),
          # last 0 in the offset column
          "0:",
          @column_divider,
          binary_representation,
          @column_divider,
          original_text,
          IO.ANSI.reset()
        ]
      end)
      |> List.insert_at(0, [IO.ANSI.light_black(), @header])
      |> Enum.join(@newline)

    StringIO.close(string_io)
    result
  end

  @doc """
  Replace terminal escape sequences with empty string.
  Used for removing coloring from the generated string.
  """
  def remove_escapes(string) do
    Regex.replace(~r<\x1B([@-_]|[\x80-\x9F])[0-?]*[ -/]*[@-~]>, string, "")
  end

  defp take_or_infinity(stream, :infinity), do: stream
  defp take_or_infinity(stream, limit), do: Stream.take(stream, limit)
end
