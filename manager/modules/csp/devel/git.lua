--!csp build system based on xmake
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- You may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2022-2023 xqyjlj<xqyjlj@126.com>
--
-- @author      xqyjlj
-- @file        git.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-01-05     xqyjlj       add get_builtinvars
-- 2023-01-02     xqyjlj       initial version
--

import("lib.detect.find_tool")

local git = find_tool("git")
local git_exec = ""
if not git then
    local csp_path = os.getenv("CSP_PATH")
    if not csp_path then
        raise("git not found!")
    else
        local exe = csp_path .. "/tools/mingit/cmd/git.exe"
        if os.exists(exe) then
            git_exec = exe
        else
            raise("git not found!")
        end
    end
else
    git_exec = "git"
end

function clone(dir, url, version)
    if version == "latest" then
        local command = git_exec .. " clone --depth=1 --recursive --shallow-submodules %s %s"
        os.vrun(string.format(command, url, dir))
    else
        local command = git_exec .. " clone --depth=1 --recursive --shallow-submodules --branch=%s %s %s"
        os.vrun(string.format(command, version, url, dir))
    end
    cprint('     the repository "%s" has been successfully cloned into "%s"', url, dir)
end

function submodule_sync(dir, version, opt)
    if version == "latest" then
        os.cd(dir)
        os.vrun(git_exec .. " submodule sync --recursive")
        if not opt or not opt["remote"] then
            os.vrun(git_exec .. " submodule update --init --recursive --force")
        elseif opt["remote"] then
            os.vrun(git_exec .. " submodule update --remote --recursive --force")
        end
        os.cd(os.projectdir())
    end
    cprint("     the submodule has been successfully synced")
end

function get_builtinvars(dir)
    os.cd(dir)
    local builtinvars = {}
    local cmds = {
        git_tag = git_exec .. " describe --tags",
        git_tag_long = git_exec .. " describe --tags --long",
        git_branch = git_exec .. " rev-parse --abbrev-ref HEAD",
        git_commit = git_exec .. " rev-parse --short HEAD",
        git_commit_long = git_exec .. " rev-parse HEAD",
        git_commit_date = git_exec .. " log -1 --date=format:%Y%m%d%H%M%S --format=%ad"
    }
    if git then
        for name, argv in pairs(cmds) do
            local result
            result =
                try {
                function()
                    return os.iorun(argv)
                end
            }
            if not result then
                result = "none"
            end
            builtinvars[name] = result:trim()
        end
    else
        builtinvars[name] = "not find git, please install git and add it to PATH."
    end
    os.cd(os.projectdir())
    return builtinvars
end
