defmodule ExDoc.Formatter.HTML.Templates do
  @moduledoc """
  Handle all template interfaces for the HTML formatter.
  """

  require EEx

  def get_functions(modules) do
      Enum.filter modules.docs, &match?(%ExDoc.FunctionNode{type: :def}, &1)
  end

  def get_macros(modules) do
      Enum.filter modules.docs, &match?(%ExDoc.FunctionNode{type: :defmacro}, &1)
  end

  def get_callbacks(modules) do
      Enum.filter modules.docs, &match?(%ExDoc.FunctionNode{type: :defcallback}, &1)
  end

  # Get the full specs from a function, already in HTML form.
  defp get_specs(%ExDoc.FunctionNode{specs: specs}) when is_list(specs) do
    presence specs
  end

  defp get_specs(_node), do: nil

  # Convert markdown to HTML.
  defp to_html(nil), do: nil
  defp to_html(bin) when is_binary(bin), do: ExDoc.Markdown.to_html(bin)

  # Get the pretty name of a function node
  defp pretty_type(%ExDoc.FunctionNode{type: t}) do
    case t do
      :def          -> "function"
      :defmacro     -> "macro"
      :defcallback  -> "callback"
    end
  end

  # Get the first paragraph of the documentation of a node, if any.
  defp synopsis(nil), do: nil
  defp synopsis(doc) do
    String.split(doc, ~r/\n\s*\n/) |> hd |> String.strip() |> String.rstrip(?.)
  end

  defp presence([]),    do: nil
  defp presence(other), do: other

  defp h(binary) do
    escape_map = [{ ~r(&), "\\&amp;" }, { ~r(<), "\\&lt;" }, { ~r(>), "\\&gt;" }, { ~r("), "\\&quot;" }]
    Enum.reduce escape_map, binary, fn({ re, escape }, acc) -> Regex.replace(re, acc, escape) end
  end

  defp css(binary) do
    escape_map = [{ ~r(\.), "-" }, { ~r(&), "-" }, { ~r(<), "-" }, { ~r(>), "-" }, { ~r("), "" }]
    Enum.reduce escape_map, binary, fn({ re, escape }, acc) -> Regex.replace(re, acc, escape) end
  end

  templates = [
    layout_template: [:content, :config, :nodes, :module],
    index_template: [:config, :nodes, :has_readme],
    list_template: [:scope, :nodes, :config, :module],
    overview_template: [:config, :modules, :exceptions, :protocols],
    module_template: [:module, :config, :all],
    readme_template: [:config, :content],
    list_item_template: [:node, :module],
    overview_entry_template: [:node],
    summary_template: [:node],
    detail_template: [:node],
    type_detail_template: [:node],
  ]

  Enum.each templates, fn({ name, args }) ->
    filename = Path.expand("templates/#{name}.eex", __DIR__)
    EEx.function_from_file :def, name, filename, args
  end
end
