--- Performs additional setup after installation
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#postinstall-hook
--- mise auto-extracts the .zip from pre_install, leaving an `aptos` binary
--- (or `aptos.exe` on Windows) at the install root. We move it into bin/.
--- @param ctx {rootPath: string, runtimeVersion: string, sdkInfo: table} Context
function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    local path = sdkInfo.path

    local is_windows = tostring(RUNTIME.osType):lower() == "windows"
    local binary = is_windows and "aptos.exe" or "aptos"

    os.execute("mkdir -p " .. path .. "/bin")

    local src = path .. "/" .. binary
    local dest = path .. "/bin/" .. binary

    local mv_cmd
    if is_windows then
        mv_cmd = 'move /Y "' .. src .. '" "' .. dest .. '"'
    else
        mv_cmd = "mv " .. src .. " " .. dest .. " && chmod +x " .. dest
    end

    local result = os.execute(mv_cmd)
    if result ~= 0 and result ~= true then
        error("Failed to install aptos binary from " .. src)
    end

    -- Smoke-test the installed binary. Capture stdout+stderr so a failure
    -- surfaces *why* (missing libc symbol, ELF interp mismatch, ...) instead
    -- of just "broken".
    local probe_cmd = is_windows and ('"' .. dest .. '" --version 2>&1') or (dest .. " --version 2>&1")
    local pipe = io.popen(probe_cmd)
    if not pipe then
        error("aptos installation: could not spawn " .. dest .. " --version")
    end
    local probe_output = pipe:read("*a") or ""
    local ok, _, code = pipe:close()
    if not ok then
        error(
            "aptos installation appears to be broken (`aptos --version` exited "
                .. tostring(code)
                .. "): "
                .. probe_output
        )
    end
end
