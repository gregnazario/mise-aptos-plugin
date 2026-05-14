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

    -- Create bin/ in an OS-appropriate way. Unix supports `mkdir -p`; cmd.exe
    -- has no `-p` and errors if the directory exists, so suppress that.
    local bin_dir = path .. "/bin"
    if is_windows then
        local win_bin = bin_dir:gsub("/", "\\")
        os.execute('cmd /c if not exist "' .. win_bin .. '" mkdir "' .. win_bin .. '"')
    else
        os.execute("mkdir -p " .. bin_dir)
    end

    -- os.rename is portable across Unix and Windows; avoids the cmd vs sh split.
    local src = path .. "/" .. binary
    local dest = bin_dir .. "/" .. binary
    local moved, mv_err = os.rename(src, dest)
    if not moved then
        error("Failed to move " .. src .. " to " .. dest .. ": " .. tostring(mv_err))
    end

    if not is_windows then
        os.execute("chmod +x " .. dest)
    end

    -- Smoke-test the installed binary. Capture stdout+stderr so a failure
    -- surfaces *why* (missing libc symbol, ELF interp mismatch, ...) instead
    -- of just "broken". pipe:close() in mise's embedded Lua doesn't expose
    -- the child exit code, so detect success by matching the expected
    -- `aptos <semver>` prefix in the captured output.
    local probe_cmd = is_windows and ('"' .. dest .. '" --version 2>&1') or (dest .. " --version 2>&1")
    local pipe = io.popen(probe_cmd)
    if not pipe then
        error("aptos installation: could not spawn " .. dest .. " --version")
    end
    local probe_output = pipe:read("*a") or ""
    pipe:close()
    if not probe_output:match("^aptos %d+%.%d+%.%d+") then
        error("aptos installation broken (`aptos --version` did not print a version): " .. probe_output)
    end
end
