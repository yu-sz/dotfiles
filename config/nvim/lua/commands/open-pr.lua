local gh = "gh"

local find_pr_query = ([[query='
        query($repo:String!, $owner:String!, $hash:String) {
          repository(name: $repo, owner: $owner) {
            object(expression: $hash) {
              ... on Commit {
                associatedPullRequests(first: 10) {
                  edges {
                    node {
                      number,
                      title,
                      author { login },
                      createdAt,
                    }
                  }
                }
              }
            }
          }
        }'
  ]]):gsub("\n", "")

---@param result table|nil json_decode 済みの GraphQL レスポンス
---@return boolean
local function is_valid_result(result)
  return (
    result
    and result.data
    and result.data.repository
    and result.data.repository.object
    and result.data.repository.object ~= vim.NIL
    and result.data.repository.object.associatedPullRequests
    and result.data.repository.object.associatedPullRequests.edges
    and result.data.repository.object.associatedPullRequests.edges[1]
    and result.data.repository.object.associatedPullRequests.edges[1].node
    and result.data.repository.object.associatedPullRequests.edges[1].node.number
  ) ~= nil
end

---@param cmd string
---@return string|nil コマンド出力（失敗・空出力時は nil）
local function run_command(cmd)
  local success, output = pcall(vim.fn.system, cmd)

  if not success then
    vim.notify("エラーが発生しました: " .. output, vim.log.levels.ERROR)
    return nil -- エラー時にはnilを返す
  end

  if output == "" then
    return nil
  end

  return output
end

-- 現在カーソルのある行のコミットハッシュをblameから取得する
---@return string|nil
local function get_commit_hash_at_cursor()
  local line_number = vim.fn.line(".")
  local file_path = vim.fn.expand("%:p")

  -- git blameを実行して該当行のコミットハッシュを取得
  local cmd = string.format("git blame -L %d,%d --porcelain %s", line_number, line_number, file_path)
  local output = run_command(cmd)

  if not output then
    vim.notify("not found commit", vim.log.levels.WARN)
    return
  end

  if output == "" then
    return nil
  end

  -- コマンド出力からコミットハッシュを抽出
  for line in string.gmatch(output, "([a-f0-9]+)%s") do
    return line
  end

  vim.notify("not found commit hash", vim.log.levels.WARN)
end

--[[
    現在のカーソルのある行のコミットハッシュからPRを特定して、
    存在する場合はブラウザで開くコマンド
  ]]
local function open_pr_from_hash()
  if vim.fn.executable(gh) == 0 then
    vim.notify("not installed gh command", vim.log.levels.ERROR)
    return
  end

  local commit_hash = get_commit_hash_at_cursor()
  if not commit_hash then
    return
  end

  local get_pr_cmd =
    string.format('%s api graphql -F owner=":owner" -F repo=":repo" -F hash=%s -f %s', gh, commit_hash, find_pr_query)

  local output = run_command(get_pr_cmd)
  if not output then
    vim.notify("GraphQL API 呼び出しに失敗しました", vim.log.levels.ERROR)
    return
  end

  local ok, result = pcall(vim.json.decode, output)
  if not ok then
    vim.notify("GraphQL レスポンスの JSON 解析に失敗しました", vim.log.levels.ERROR)
    return
  end

  if not is_valid_result(result) then
    vim.notify("not found pull request number", vim.log.levels.WARN)
    return
  end

  local prs = result.data.repository.object.associatedPullRequests.edges
  local pr_number = prs[1].node.number

  local open_pr_cmd = string.format("%s browse -- %s", gh, pr_number)

  run_command(open_pr_cmd)
end

vim.api.nvim_create_user_command("OpenPr", open_pr_from_hash, { desc = "Open PR associated with the commit at cursor" })
