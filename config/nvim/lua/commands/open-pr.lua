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

local function is_valid_result(result)
  return result
      and result.data
      and result.data.repository
      and result.data.repository.object
      and result.data.repository.object ~= vim.NIL
      and result.data.repository.object.associatedPullRequests
      and result.data.repository.object.associatedPullRequests.edges
      and result.data.repository.object.associatedPullRequests.edges[1]
      and result.data.repository.object.associatedPullRequests.edges[1].node
      and result.data.repository.object.associatedPullRequests.edges[1].node.number
end

local function run_command(cmd)
  local success, output = pcall(vim.fn.system, cmd)

  if not success then
    vim.api.nvim_err_writeln("エラーが発生しました: " .. output)
    return nil -- エラー時にはnilを返す
  end

  if output == "" then
    return nil
  end

  return output
end

-- 現在カーソルのある行のコミットハッシュをblameから取得する
local function get_commit_hash_at_cursor()
  local line_number = vim.fn.line(".")
  local file_path = vim.fn.expand("%:p")

  -- git blameを実行して該当行のコミットハッシュを取得
  local cmd = string.format("git blame -L %d,%d --porcelain %s", line_number, line_number, file_path)
  local output = run_command(cmd)

  if not output then
    vim.api.nvim_err_writeln("not found commit")
    return
  end

  if output == "" then
    return nil
  end

  -- コマンド出力からコミットハッシュを抽出
  for line in string.gmatch(output, "([a-f0-9]+)%s") do
    return line
  end

  vim.api.nvim_err_writeln("not found commit hash")
end

--[[
    現在のカーソルのある行のコミットハッシュからPRを特定して、
    存在する場合はブラウザで開くコマンド
  ]]
local function open_pr_from_hash()
  if vim.fn.executable(gh) == 0 then
    vim.api.nvim_err_writeln("not installed gh command")
    return
  end

  local commit_hash = get_commit_hash_at_cursor()

  local get_pr_cmd = string.format(
    '%s api graphql -F owner=":owner" -F repo=":repo" -F hash=%s -f %s',
    gh,
    commit_hash,
    find_pr_query
  )

  local output = run_command(get_pr_cmd)
  if not output then
    vim.qpi.nvim_error_writeln("GraphQL API 呼び出しに失敗しました")
    return
  end

  local result = vim.fn.json_decode(output)

  if not is_valid_result(result) then
    vim.api.nvim_err_writeln("not found pull request number")
    return
  end

  local prs = result.data.repository.object.associatedPullRequests.edges
  local pr_number = prs[1].node.number

  local open_pr_cmd = string.format("%s browse -- %s", gh, pr_number)

  run_command(open_pr_cmd)
end

vim.api.nvim_create_user_command("OpenPr", open_pr_from_hash, {})
