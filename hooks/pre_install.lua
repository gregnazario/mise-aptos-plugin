--- Returns download information for a specific Aptos CLI version
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#preinstall-hook
--- @param ctx {version: string, runtimeVersion: string} Context
--- @return table Version and download information
function PLUGIN:PreInstall(ctx) -- luacheck: ignore 212
    local http = require("http")

    local version = ctx.version
    local triple = resolve_target_triple()
    local archive = "aptos-cli-" .. version .. "-" .. triple .. ".zip"
    local base_url = "https://github.com/aptos-labs/aptos-cli-releases/releases/download/aptos-cli-v" .. version
    local url = base_url .. "/" .. archive

    local sha256 = fetch_sha256(http, base_url, archive)

    return {
        version = version,
        url = url,
        sha256 = sha256,
        note = "Downloading Aptos CLI " .. version .. " (" .. triple .. ")",
    }
end

--- Map RUNTIME.osType / RUNTIME.archType to the Rust target triple used in
--- aptos-cli-releases asset filenames.
--- Linux: defaults to glibc 2.31+ (-unknown-linux-gnu). Set
--- MISE_APTOS_LINUX_COMPAT=1 for the older-glibc (-compat) build.
function resolve_target_triple() -- luacheck: ignore 121
    local os_name = tostring(RUNTIME.osType):lower()
    local arch = tostring(RUNTIME.archType):lower()

    if os_name == "darwin" then
        if arch == "arm64" then
            return "aarch64-apple-darwin"
        elseif arch == "amd64" or arch == "x86_64" then
            return "x86_64-apple-darwin"
        end
    elseif os_name == "linux" then
        local compat = os.getenv("MISE_APTOS_LINUX_COMPAT")
        local suffix = (compat == "1" or compat == "true") and "-compat" or ""
        if arch == "amd64" or arch == "x86_64" then
            return "x86_64-unknown-linux-gnu" .. suffix
        elseif arch == "arm64" or arch == "aarch64" then
            return "aarch64-unknown-linux-gnu" .. suffix
        end
    elseif os_name == "windows" then
        if arch == "amd64" or arch == "x86_64" then
            return "x86_64-pc-windows-msvc"
        end
    end

    error("Aptos CLI: unsupported platform " .. os_name .. "/" .. arch)
end

--- Fetch the SHA256SUMS file for the release and return the hash for `archive`.
--- Returns nil (not an error) if the file or line is missing, so installation
--- can still proceed for older releases that lack the manifest.
function fetch_sha256(http, base_url, archive) -- luacheck: ignore 121
    local resp, err = http.get({ url = base_url .. "/SHA256SUMS" })
    if err ~= nil or resp.status_code ~= 200 then
        return nil
    end
    for line in resp.body:gmatch("[^\r\n]+") do
        local hash, file = line:match("^(%x+)%s+(.+)$")
        if hash and file == archive then
            return hash
        end
    end
    return nil
end
