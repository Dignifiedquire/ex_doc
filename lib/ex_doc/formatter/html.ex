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
    has_readme = config.readme && generate_readme(output, config)

    all = Autolink.all(modules)
    modules    = filter_list(:modules, all)
    exceptions = filter_list(:exceptions, all)
    protocols  = filter_list(:protocols, all)

    generate_index(modules, all, exceptions, protocols, output, config, has_readme)
    generate_overview(modules, exceptions, protocols, output, config)

    Path.join(config.output, "index.html")
  end

  defp generate_index(modules, all, exceptions, protocols, output, config, has_readme) do
    modules_list = generate_list(:modules, modules, all, output, config, has_readme)
    exceptions_list = generate_list(:exceptions, exceptions, all, output, config, has_readme)
    protocols_list = generate_list(:protocols, protocols, all, output, config, has_readme)

    content = Templates.index_template(config, modules_list, exceptions_list, protocols_list, has_readme)
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

  defp generate_readme(output, config) do
    File.rm("#{output}/README.html")
    write_readme(output, File.read("README.md"), config)
  end

  defp write_readme(output, {:ok, content}, config) do
    readme_html = Templates.readme_template(config, content)
    # Allow using nice codeblock syntax for readme too.
    readme_html = String.replace(readme_html, "<pre><code>",
                                 "<pre class=\"codeblock\"><code>")
    File.write("#{output}/README.html", readme_html)
    true
  end

  defp write_readme(_, _, _) do
    false
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

  defp generate_list(scope, nodes, all, output, config, has_readme) do
    Enum.each nodes, &generate_module_page(&1, all, output, config)
    Templates.list_page(scope, nodes, config, has_readme)
  end

  defp generate_module_page(node, modules, output, config) do
    content = Templates.module_page(node, config, modules)
    File.write("#{output}/#{node.id}.html", content)
  end

  defp templates_path(other) do
    Path.expand("html/templates/#{other}", __DIR__)
  end
end
