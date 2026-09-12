{ lib }:
let
  allAgents = [
    "claude"
    "codex"
    "gemini"
  ];
  forAgent = agent: lib.filterAttrs (_: s: builtins.elem agent (s.agents or allAgents));
  compact = lib.filterAttrs (_: v: v != { } && v != [ ] && v != null);
  envRef = name: "\${${name}}";
  envAttrs = s: (s.env or { }) // lib.genAttrs (s.envVars or [ ]) envRef;
  bearer =
    s: lib.optionalAttrs (s ? bearerTokenEnv) { Authorization = "Bearer ${envRef s.bearerTokenEnv}"; };
in
{
  # Claude Code: plugin .mcp.json（${VAR} 展開）
  toClaude = servers: {
    mcpServers = lib.mapAttrs (
      _: s:
      compact (
        if s.type == "http" then
          {
            type = "http";
            inherit (s) url;
            headers = (s.headers or { }) // bearer s;
          }
        else
          {
            type = "stdio";
            inherit (s) command;
            args = s.args or [ ];
            env = envAttrs s;
          }
      )
    ) (forAgent "claude" servers);
  };

  # Gemini CLI: settings.json mcpServers（settings.json 全体で ${VAR} 展開）
  toGemini = servers: {
    mcpServers = lib.mapAttrs (
      _: s:
      compact (
        if s.type == "http" then
          {
            httpUrl = s.url;
            headers = (s.headers or { }) // bearer s;
          }
        else
          {
            inherit (s) command;
            args = s.args or [ ];
            env = envAttrs s;
          }
      )
    ) (forAgent "gemini" servers);
  };

  # Codex: config.toml [mcp_servers]（env_vars / bearer_token_env_var で env 参照）
  toCodex = servers: {
    mcp_servers = lib.mapAttrs (
      _: s:
      compact (
        if s.type == "http" then
          {
            inherit (s) url;
            http_headers = s.headers or { };
            bearer_token_env_var = s.bearerTokenEnv or null;
          }
        else
          {
            inherit (s) command;
            args = s.args or [ ];
            env = s.env or { };
            env_vars = s.envVars or [ ];
          }
      )
    ) (forAgent "codex" servers);
  };
}
