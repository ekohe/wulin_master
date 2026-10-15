# wulin_agent -- an AI assistant over the app's grids: a chat (a toolbar drawer and the /wulin_agent
# page) and an MCP endpoint for external clients, both exposing grid CRUD and custom actions as tools.
# Every tool is gated by the user's wulin_permits permissions, which is why it needs that component.
# The engine draws its own routes and appends its own migrations, so nothing here mounts or copies
# either.

wulin_vendor "wulin_agent"

# The chat UI is React, and the gem ships its source rather than a bundle. Its package.json joins the
# workspaces so its packages install into node_modules, and the app's own esbuild bundles the .esm.js
# entry like any other component's. React itself is a peer of the gem: the app depends on it, so the
# bundle holds one React, at the version the app chooses.
wulin_workspace "vendor/gems/wulin_agent"
wulin_npm "react" => "^19.0.0", "react-dom" => "^19.0.0"
wulin_js "../../vendor/gems/wulin_agent/app/javascript/wulin_agent.esm.js"

# Plain CSS, @use'd without its extension so dart-sass loads it as a module rather than leaving a
# CSS @import for the browser to fetch.
wulin_sass '@use "../../../vendor/gems/wulin_agent/app/assets/stylesheets/wulin_agent"'

# The page is a route, not a WulinMaster screen, so the item names it by URL.
wulin_menu <<~RB
  submenu "Assistant" do
    item "Assistant", url: "/wulin_agent", icon: :cognition
  end
RB

# Settings live in config/app_config.yml under wulin_agent, as every component's do, and the
# initializer below reads them -- so a deploy changes YAML rather than Ruby.
wulin_app_config <<~YAML
  # wulin_agent:
  #   toolbar_enabled: true      # false: reach the assistant from the menu only
  #   thinking_effort: high      # reasoning effort; levels depend on the model (none..max on gpt-6-luna)
  #   temperature: 0.7           # non-reasoning models only; the agent drops it for models that refuse it
  #   mcp_allowed_hosts:         # hostnames /wulin_agent/mcp answers on once deployed
  #     - your-app.example.com
YAML

wulin_post do
  file "config/initializers/wulin_agent.rb", <<~RB unless File.exist?("config/initializers/wulin_agent.rb")
    # frozen_string_literal: true

    # Settings live in config/app_config.yml under the wulin_agent key. API keys do not:
    # they are secrets, read from the environment (.env) or Rails credentials.
    agent = (defined?(APP_CONFIG) && APP_CONFIG["wulin_agent"]) || {}

    WulinAgent.setup do |config|
      config.toolbar_enabled = agent["toolbar_enabled"] != false
      config.temperature = agent["temperature"] unless agent["temperature"].nil?
      config.thinking_effort = agent["thinking_effort"].presence
      config.mcp_allowed_hosts = Array(agent["mcp_allowed_hosts"])
    end
  RB

  # API keys are secrets, so only their names are written, empty, into .env.example and .env. The
  # engine reads them at boot from the environment -- an empty value counts as unset -- and falls back
  # to Rails credentials. Whatever starts the app supplies them: an export on a local machine (bin/dev
  # does not read .env), .env under docker compose, or the environment a deploy or an orchestrator
  # gives the container. Changing one means restarting the app.
  keys = <<~ENV
    # wulin_agent: the key for WULIN_AGENT_MODEL's provider (OpenAI gpt-6-luna when it is empty)
    OPENAI_API_KEY=
    ANTHROPIC_API_KEY=
    GEMINI_API_KEY=
    WULIN_AGENT_MODEL=
  ENV
  %w[.env.example .env].each do |path|
    next if !File.exist?(path) || File.read(path).include?("OPENAI_API_KEY=")

    append_to_file path, "\n#{keys}"
  end
end

wulin_note "wulin_agent: the AI key is read at boot -- OPENAI_API_KEY, or ANTHROPIC_API_KEY / GEMINI_API_KEY with WULIN_AGENT_MODEL. Export it on a local machine, put it in .env under docker compose, or inject it into the container's environment; Rails credentials (openai.api_key, ...) work too. Until one is set every chat turn answers with an error"
wulin_note "wulin_agent: /wulin_agent/mcp runs write tools without asking -- issue MCP tokens only to trusted clients, and list the deployed hostnames under wulin_agent.mcp_allowed_hosts in config/app_config.yml"
