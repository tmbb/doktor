defmodule Doktor do
  @moduledoc """
  Extract documentation from an external file.
  """
  alias Doktor.SectionsCache

  defp merge_lines(lines) do
    lines
    |> Enum.reverse
    |> Enum.join("\n")
    |> String.trim
    |> Kernel.<>("\n")
  end

  @doc false
  def extract_sections(text) do
    lines = String.split(text, "\n")
    {section_list, {last_header, last_lines}} = Enum.reduce lines, {[], {nil, []}}, fn
      line, {sections, {current_header, current_lines} = current_section} ->
        regex_match = Regex.named_captures(~r/^<!--\s@(?<type>(module|type)?doc)\s(?<name>\S+)\s-->$/m, line)

        case {regex_match, current_header} do
          {nil, nil} ->
            {sections, current_section}

          {nil, old_header} ->
            {sections, {old_header, [line | current_lines]}}

          {%{"type" => type, "name" => name}, nil} ->
            new_header = {type, name}
            # new_section = {current_header, merge_lines(current_lines)}
            next_section = {new_header, []}
            {sections, next_section}

          {%{"type" => type, "name" => name}, current_header} ->
            new_header = {type, name}
            new_section = {current_header, merge_lines(current_lines)}
            new_sections = [new_section | sections]
            next_section = {new_header, []}
            {new_sections, next_section}
        end
    end

    sections =
      case last_header do
        nil ->
          []

        _ ->
          last_section = {last_header, merge_lines(last_lines)}
          [last_section | section_list]
      end

    Enum.into(sections, %{})
  end

  defp extract_and_store_sections_from_file(filename, module_name) do
    sections_list =
      filename
      |> File.read!()
      |> extract_sections()

    store_sections(sections_list, module_name)
  end

  defp store_sections(sections_list, module_name) do
    {:ok, _pid} = SectionsCache.start_link(module_name)
    SectionsCache.put_sections(module_name, sections_list)
    :ok
  end

  defmacro @(call) do
    case call do
      {:dok, _, [name]} when is_binary(name) ->
        quote do
          Kernel.@(doc unquote(SectionsCache.get_contents(__MODULE__, {"doc", name})))
        end

      {:typedok, _, [name]} when is_binary(name) ->
        quote do
          Kernel.@(typedoc unquote(SectionsCache.get_contents(__MODULE__, {"typedoc", name})))
        end

      {:moduledok, _, [name]} when is_binary(name)  ->
        quote do
          Kernel.@(moduledoc unquote(SectionsCache.get_contents(__MODULE__, {"moduledoc", name})))
        end

      _ ->
        quote do
          Kernel.@(unquote(call))
        end
    end

  end

  defmacro __using__([file: file]) when is_binary(file) do
    extract_and_store_sections_from_file(file, __MODULE__)
    quote do
      import Kernel, except: [@: 1]
      import Doktor, only: [@: 1]
    end
  end
end