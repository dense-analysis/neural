local function is_windows()
    return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

local function get_path_separator()
    return is_windows() and "\\" or "/"
end

local function get_script_path()
    local path_sep = get_path_separator()
    local script_path = debug.getinfo(1).source:match("@?(.*)" .. path_sep)

    return script_path or ""
end

local function run_command(command)
    local status, _, code = os.execute(command)

    require('notify').notify('Command: ' .. command .. ' || status: ' .. status, 'info')
    require('notify').notify('status: ' .. status, 'info')

    if status == false then
        error("Command failed: " .. command .. ". Exit code: " .. tostring(code))
    end
end

local function setup()
    local python = is_windows() and "python" or "python3"
    local sep = get_path_separator()
    local script_path = get_script_path()
    local venv_path = script_path .. sep .. "python3" .. sep .. "venv"

    -- Create virtual environment if it does not exist.
    if vim.fn.isdirectory(venv_path) == 0 then
        run_command(python .. " -m venv " .. venv_path)
    end

    -- Install requirements via pip
    local pip_cmd = venv_path .. (is_windows() and sep .. "Scripts" .. sep .. "pip" or sep .. "bin" .. sep .. "pip")
    local requirements_path = script_path .. sep .. "python3" .. sep .. "requirements.txt"

    run_command(pip_cmd .. " install -r " .. requirements_path)
end

setup()

local function setup()
    local setup_script = debug.getinfo(1).source:match("@?(.*/)") .. "setup.sh"

    if vim.fn.filereadable(setup_script) == 1 then
        local status, _, code = os.execute("sh " .. build_script_path)
        if status == false then
            error("Failed to execute build script. Exit code: " .. tostring(code))
        end
    else
        error("Build script not found: " .. build_script_path)
    end
end

setup()
