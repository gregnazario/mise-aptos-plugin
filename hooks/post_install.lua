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
    local sep = is_windows and "\\" or "/"

    -- Normalize joined paths to the native separator. sdkInfo.path on Windows
    -- already uses backslashes; mixing in forward slashes from string joins
    -- confuses os.rename on this Lua build.
    local function join(a, b)
        local joined = a .. sep .. b
        if is_windows then
            return (joined:gsub("/", "\\"))
        end
        return joined
    end

    local bin_dir = join(path, "bin")
    local src = join(path, binary)
    local dest = join(bin_dir, binary)

    -- Create bin/. cmd.exe is already the shell for os.execute on Windows,
    -- so use cmd built-ins directly (no `cmd /c` prefix). mkdir on Unix
    -- needs -p; on Windows we guard with `if not exist` so re-runs don't
    -- error out.
    if is_windows then
        os.execute('if not exist "' .. bin_dir .. '" mkdir "' .. bin_dir .. '"')
    else
        os.execute("mkdir -p " .. bin_dir)
    end

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
