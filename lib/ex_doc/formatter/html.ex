defmodule ExDoc.Formatter.HTML do
  @moduledoc """
  Provide HTML-formatted documentation
  """

  alias ExDoc.Formatter.HTML.Templates
  alias ExDoc.Formatter.HTML.Autolink

  @doc """
  Generate HTML documentation for the given modules
  """
  def run(modules, config)  do
    output = Path.expand(config.output)
    :ok = File.mkdir_p output

    generate_assets(output, config)

    all = Autolink.all(modules)
    page = &generate_page(&1, all, output, config)
    has_readme = config.readme && generate_readme(config)

    generate_index(page, all, output, config, has_readme)
    generate_module_pages(page, all, output, config)

    Path.join(config.output, "index.html")
  end

  defp generate_page(content, all, output, config) do
    nodes = %{ modules:    filter_list(:modules, all),
               exceptions: filter_list(:exceptions, all),
               protocols:  filter_list(:protocols, all)}

    Templates.layout_template(content, config, nodes)
  end

  defp generate_module_pages(page, all, output, config) do
    Enum.each all, &generate_module_page(&1, page, all, output, config)
  end


  defp generate_index(page, all, output, config, has_readme) do
    content = page.(Templates.index_template(config, all, has_readme))

    :ok = File.write("#{output}/index.html", content)
  end

  defp generate_overview(modules, exceptions, protocols, output, config) do
    content = Templates.overview_template(config, modules, exceptions, protocols)
    :ok = File.write("#{output}/overview.html", content)
  end

  defp assets do
    [{ templates_path("css/*.css"), "css" },
     { templates_path("js/*.js"), "js" }]
  end

  defp generate_assets(output, _config) do
    Enum.each assets, fn({ pattern, dir }) ->
      output = "#{output}/#{dir}"
      File.mkdir output

      Enum.map Path.wildcard(pattern), fn(file) ->
        base = Path.basename(file)
        File.copy file, "#{output}/#{base}"
      end
    end
  end

  defp generate_readme(config) do
    case File.read("README.md") do
      {:ok, content} ->
        readme_html = Templates.readme_template(config, content)
        String.replace(readme_html, "<pre><code>",
                                    "<pre class=\"codeblock\"><code>")
      _ -> false
    end
  end

  @doc false
  # Helper to split modules into different categories.
  #
  # Public so that code in Template can use it.
  def categorize_modules(nodes) do
    [modules: filter_list(:modules, nodes),
     exceptions: filter_list(:exceptions, nodes),
     protocols: filter_list(:protocols, nodes)]
  end

  defp filter_list(:modules, nodes) do
    Enum.filter nodes, &match?(%ExDoc.ModuleNode{type: x} when not x in [:exception, :protocol, :impl], &1)
  end

  defp filter_list(:exceptions, nodes) do
    Enum.filter nodes, &match?(%ExDoc.ModuleNode{type: x} when x in [:exception], &1)
  end

  defp filter_list(:protocols, nodes) do
    Enum.filter nodes, &match?(%ExDoc.ModuleNode{type: x} when x in [:protocol], &1)
  end

  defp generate_module_page(node, page, modules, output, config) do
    content = page.(Templates.module_template(node, config, modules))
    File.write("#{output}/#{node.id}.html", content)
  end

  defp templates_path(other) do
    Path.expand("html/templates/#{other}", __DIR__)
  end
end
