--- Returns download information for a specific Aptos CLI version
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#preinstall-hook
--- @param ctx {version: string, runtimeVersion: string} Context
--- @return table Version and download information
function PLUGIN:PreInstall(ctx) -- luacheck: ignore 212
    local http = require("http")

    local version = ctx.version
    -- Strict allowlist: only X.Y.Z semver. The version flows into both the
    -- download URL and the on-disk install path, so reject anything that
    -- could carry shell metacharacters or URL-path tricks before use.
    if not version:match("^%d+%.%d+%.%d+$") then
        error("Aptos CLI: refusing to install invalid version string: " .. tostring(version))
    end

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
--- Hard-fail on any failure mode so an install can't silently proceed without
--- checksum verification:
---   * HTTP error fetching SHA256SUMS
---   * Non-200 response
---   * SHA256SUMS present but missing a line for this archive
function fetch_sha256(http, base_url, archive) -- luacheck: ignore 121
    local resp, err = http.get({ url = base_url .. "/SHA256SUMS" })
    if err ~= nil then
        error("Aptos CLI: failed to fetch SHA256SUMS (" .. tostring(err) .. "). Refusing to install without checksum.")
    end
    if resp.status_code ~= 200 then
        error(
            "Aptos CLI: SHA256SUMS returned HTTP "
                .. tostring(resp.status_code)
                .. ". Refusing to install without checksum."
        )
    end
    for line in resp.body:gmatch("[^\r\n]+") do
        local hash, file = line:match("^(%x+)%s+(.+)$")
        if hash and file == archive then
            return hash
        end
    end
    error("Aptos CLI: archive '" .. archive .. "' not listed in SHA256SUMS. Refusing to install without checksum.")
end
