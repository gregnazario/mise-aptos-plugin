--- Returns a list of available versions for the Aptos CLI
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#available-hook
--- Source: https://github.com/aptos-labs/aptos-cli-releases/releases
--- @param ctx {args: string[]} Context (args = user arguments)
--- @return table[] List of available versions
function PLUGIN:Available(ctx) -- luacheck: ignore 212
    local http = require("http")
    local json = require("json")

    local repo_url = "https://api.github.com/repos/aptos-labs/aptos-cli-releases/releases?per_page=100"

    local resp, err = http.get({ url = repo_url })
    if err ~= nil then
        error("Failed to fetch Aptos CLI releases: " .. err)
    end
    if resp.status_code ~= 200 then
        error("GitHub API returned status " .. resp.status_code .. ": " .. resp.body)
    end

    local releases = json.decode(resp.body)
    local result = {}

    for _, release in ipairs(releases) do
        if not release.draft then
            local tag = release.tag_name or ""
            -- Tag format: aptos-cli-v9.2.0 -> 9.2.0
            local version = tag:gsub("^aptos%-cli%-v", "")
            if version ~= "" and version ~= tag then
                local note = nil
                if release.prerelease then
                    note = "pre-release"
                end
                table.insert(result, {
                    version = version,
                    note = note,
                })
            end
        end
    end

    return result
end
