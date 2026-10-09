# wulin_agent -- an AI assistant over the app's grids: a chat (a toolbar drawer and the /wulin_agent
# page) and an MCP endpoint for external clients, both exposing grid CRUD and custom actions as tools.
# Every tool is gated by the user's wulin_permits permissions, which is why it needs that component.
# The engine draws its own routes and appends its own migrations, so nothing here mounts or copies
# either.

wulin_vendor "wulin_agent"

# The chat UI is React, and the gem ships its source rather than a bundle. Its package.json joins the
# workspaces so React and the rest install into node_modules, and the app's own esbuild bundles the
# .esm.js entry like any other component's.
wulin_workspace "vendor/gems/wulin_agent"
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
# initializer below reads them -- so a deploy changes YAML rather than Ruby, and re-applying this
# template (which rewrites the initializer) loses nothing.
wulin_app_config <<~YAML
  # wulin_agent:
  #   toolbar_enabled: true      # false: reach the assistant from the menu only
  #   thinking_effort: high      # reasoning effort; levels depend on the model (none..max on gpt-6-luna)
  #   temperature: 0.7           # non-reasoning models only; the agent drops it for models that refuse it
  #   mcp_allowed_hosts:         # hostnames /wulin_agent/mcp answers on once deployed
  #     - your-app.example.com
YAML

wulin_post do
  file "config/initializers/wulin_agent.rb", <<~RB, force: true
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

  # API keys are secrets, so only their names are written: empty, in the committed .env.example
  # and in .env. The app runs in a container that reads .env through compose -- a variable exported
  # in a shell never reaches it. A Wulin Studio build has no channel for secrets yet, so it ships
  # with these empty and the assistant reports that no key is set.
  keys = <<~ENV
    # wulin_agent: the key for WULIN_AGENT_MODEL's provider (OpenAI gpt-6-luna by default)
    OPENAI_API_KEY=
    ANTHROPIC_API_KEY=
    GEMINI_API_KEY=
  ENV
  %w[.env.example .env].each do |path|
    next if !File.exist?(path) || File.read(path).include?("OPENAI_API_KEY=")

    append_to_file path, "\n#{keys}"
  end
end

wulin_note "wulin_agent: put the AI key in .env (OPENAI_API_KEY, or ANTHROPIC_API_KEY / GEMINI_API_KEY with WULIN_AGENT_MODEL) -- the container reads .env, not your shell; until it is set every chat turn answers with an error"
wulin_note "wulin_agent: /wulin_agent/mcp runs write tools without asking -- issue MCP tokens only to trusted clients, and list the deployed hostnames under wulin_agent.mcp_allowed_hosts in config/app_config.yml"
