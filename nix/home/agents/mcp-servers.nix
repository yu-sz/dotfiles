# 中立スキーマ。各エージェント形式への変換は mcp-lib.nix が行う
#   type          : "stdio" | "http"
#   command/args  : stdio
#   url/headers   : http
#   env           : リテラルの環境変数（秘匿値は書かない）
#   envVars       : 親環境から転送する環境変数名（値は zsh/eager/local.zsh で export）
#   bearerTokenEnv: Authorization: Bearer に使う環境変数名
#   agents        : 配布先（省略時は全エージェント）
{
  context7 = {
    type = "stdio";
    command = "npx";
    args = [
      "-y"
      "@upstash/context7-mcp"
    ];
  };
  playwright = {
    type = "stdio";
    command = "npx";
    args = [
      "-y"
      "@playwright/mcp@latest"
    ];
  };
  terraform = {
    type = "stdio";
    command = "docker";
    args = [
      "run"
      "-i"
      "--rm"
      "hashicorp/terraform-mcp-server"
    ];
  };
  aws-knowledge = {
    type = "http";
    url = "https://knowledge-mcp.global.api.aws";
  };
  sentry = {
    type = "http";
    url = "https://mcp.sentry.dev/mcp";
  };
}
