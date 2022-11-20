--!csp build system based on xmake
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
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
-- Copyright (C) 2022-present xqyjlj<xqyjlj@126.com>, csplink.github.io
--
-- @author      xqyjlj
-- @file        install.lua
--

import("core.project.project")
import("core.project.config")
import("core.base.semver")
import("core.base.json")

local build_xmake = {}
local targets = {}
local rules = {}
local projectdir = path.absolute(os.projectdir())
local scriptdir = path.absolute(os.scriptdir())
local buildir = projectdir .. "/build"

function create_build_xmake(target)
    local build_xmake_path = buildir .. "/xmake.lua"
    build_xmake_path_template = scriptdir .. "/../../template/build_xmake.lua"
    local data = io.readfile(build_xmake_path_template)
    table.insert(build_xmake, data)
    update_build_xmake(target)
    data = table.concat(build_xmake, "\n") .. "\n"
    print("create %s", build_xmake_path)
    io.writefile(build_xmake_path, data)
end

function update_build_xmake(target)
    add_import(target)
    add_target(target, "csp_target")
    add_rule(target, "csp_rule")
end

function add_import(target)
    add_hal(target)
end

function add_hal(target)
    -- check value "hal"
    local hal_value = target:values("hal")
    assert(
        hal_value,
        'not find values: \'hal\', please check that hal has been set in the target with the same name as the project. \
           e.g. \'set_values("hal", "csp_hal_apm32f1|v0.0.1").\''
    )

    -- get original "hal" "version"
    local hal_array = hal_value:split("|")
    local hal = ""
    local version = "latest" -- default latest
    if #hal_array == 1 then -- set_values("hal", "csp_hal_apm32f1")
        hal = string.trim(hal_array[1])
    elseif #hal_array == 2 then -- set_values("hal", "csp_hal_apm32f1|v0.0.1")
        hal = string.trim(hal_array[1])
        version = string.trim(hal_array[2])
    else
        assert(false, "error value: '%s', please check hal`s value is correct.", hal_value)
    end

    -- use semver to parse version
    local configuration = json.loadfile(scriptdir .. "/../../../packages/hal/" .. hal .. "/config.json")
    local versions = configuration["versions"]
    version, source = semver.select(version, versions)
    print("use hal: '%s' version: '%s'", hal, version)

    -- insert hal`s target
    table.insert(targets, configuration["target"])
    -- insert hal`s rule
    table.insert(rules, configuration["rule"])

    -- check hal_path
    local haldir = target:values("haldir")
    local hal_path
    if haldir then
        hal_path = haldir
    else
        hal_path = scriptdir .. "/../../../repositories/hal/%s/%s"
    end

    -- insert "includes("/home/csplink/git/github/csplink/csp_hal_apm32f1/examples/get-started/hello_world/../../../package.lua")"
    hal_path = string.format(hal_path, hal, version)
    local includes = string.format('includes("%s/package.lua")', hal_path)
    table.insert(build_xmake, includes)

    -- insert "includes("/home/csplink/git/github/csplink/csp_hal_apm32f1/examples/get-started/hello_world/../../../tools/xmake/toolchains/arm-none-eabi.lua"))"
    local toolchain = target:values("toolchain")
    if toolchain then
        local includes = string.format('includes("%s/tools/xmake/toolchains/%s.lua")', hal_path, toolchain)
        table.insert(build_xmake, includes)
    end
end

function add_target(target, name)
    table.insert(build_xmake, "")
    table.insert(build_xmake, string.format('target("%s")', name))
    table.insert(build_xmake, "do")
    table.insert(build_xmake, '    set_kind("static")')
    -- start
    for _, k in pairs(targets) do
        table.insert(build_xmake, string.format('    add_deps("%s")', k))
        print("add target deps: %s", k)
    end
    -- end
    table.insert(build_xmake, "end")
    table.insert(build_xmake, "target_end()")
end

function add_rule(target, name)
    table.insert(build_xmake, "")
    table.insert(build_xmake, string.format('rule("%s")', name))
    table.insert(build_xmake, "do")
    -- start
    for _, k in pairs(rules) do
        table.insert(build_xmake, string.format('    add_deps("%s")', k))
        print("add rule deps: %s", k)
    end
    -- end
    table.insert(build_xmake, "end")
    table.insert(build_xmake, "rule_end()")
end

function main(target)
    create_build_xmake(target)
end
