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

    local version_cmd = is_windows and ('"' .. dest .. '" --version >NUL 2>&1')
        or (dest .. " --version > /dev/null 2>&1")
    local test_result = os.execute(version_cmd)
    if test_result ~= 0 and test_result ~= true then
        error("aptos installation appears to be broken (`aptos --version` failed)")
    end
end
