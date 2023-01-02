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
-- Copyright (C) 2022-present xqyjlj<xqyjlj@126.com>
--
-- @author      xqyjlj
-- @file        install.lua
--

import("core.project.project")
import("core.project.config")
import("core.base.json")
import("csp.base.semver")
import("csp.base.realdir")

local build_xmake = {}
local targets = {}
local rules = {}
local options = {}
local projectdir = string.gsub(path.absolute(os.projectdir()), "\\", "/")
local scriptdir = string.gsub(path.absolute(os.scriptdir()), "\\", "/")
local package_haldir = scriptdir .. "/../../../packages/hal"
local buildir = projectdir .. "/build"

function create_build_xmake(target)
    local build_xmake_path = buildir .. "/csplink.lua"
    build_xmake_path_template = scriptdir .. "/../../template/build_xmake.lua"
    local data = io.readfile(build_xmake_path_template)
    table.insert(build_xmake, data)
    update_build_xmake(target)
    data = table.concat(build_xmake, "\n")
    cprint("     generate '${bright magenta}%s${clear}'", build_xmake_path)
    io.writefile(build_xmake_path, data)
end

function update_build_xmake(target)
    add_import(target)
    cprint("${yellow}  => create build xmake ......")
    add_target(target, "csp_target")
    add_rule(target, "csp_rule")
    add_option(target, "csp_option")
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
    local hal, version, configuration = semver.hal(hal_value)

    -- insert hal`s target
    table.insert(targets, configuration["target"])
    -- insert hal`s rule
    table.insert(rules, configuration["rule"])
    -- insert hal`s option
    table.insert(options, configuration["option"])
    -- check hal_path
    local haldir = target:values("haldir")
    if haldir then
        haldir = realdir.main(haldir)
    else
        haldir = realdir.main(scriptdir .. "/../../../repositories/hal") .. "/%s/%s"
    end

    -- insert "includes("/home/csplink/git/github/csplink/csp_hal_apm32f1/csplink.lua")"
    table.insert(build_xmake, "-- hal_package")
    haldir = string.format(haldir, hal, version)
    local includes = string.format('includes("%s/csplink.lua")', haldir)
    table.insert(build_xmake, includes)

    -- insert "includes("/home/csplink/git/github/csplink/csp_repo/manager/toolchains/arm-none-eabi.lua"))"
    local toolchain = target:values("toolchain")
    if toolchain then
        table.insert(build_xmake, "-- toolchain")
        local toolchain_dir = realdir.main(scriptdir .. "/../../toolchains")
        local includes = string.format('includes("%s/%s.lua")', toolchain_dir, toolchain)
        table.insert(build_xmake, includes)
        table.insert(build_xmake, "")
    end
end

function add_target(target, name)
    table.insert(build_xmake, "")
    table.insert(build_xmake, "-- this target is a collection of library targets")
    table.insert(build_xmake, string.format('target("%s")', name))
    table.insert(build_xmake, "do")
    table.insert(build_xmake, '    set_kind("object")')
    -- start
    for index in pairs(table.orderkeys(targets)) do
        table.insert(build_xmake, string.format('    add_deps("%s")', targets[index]))
        cprint("     add target deps: '${bright magenta}%s${clear}'", targets[index])
    end
    -- end
    table.insert(
        build_xmake,
        [[
    after_clean(
        function(target)
            os.tryrm("build/.deps")
            os.tryrm("build/.gens")
            os.tryrm("build/.objs")
        end
    )]]
    )
    table.insert(build_xmake, "end")
    table.insert(build_xmake, "target_end()")
    table.insert(build_xmake, "")
end

function add_rule(target, name)
    table.insert(build_xmake, "")
    table.insert(build_xmake, "-- this rule is a collection of library rules")
    table.insert(build_xmake, string.format('rule("%s")', name))
    table.insert(build_xmake, "do")
    -- start
    table.insert(build_xmake, '    add_deps("csp_sys_config")')
    for index in pairs(table.orderkeys(rules)) do
        table.insert(build_xmake, string.format('    add_deps("%s")', rules[index]))
        cprint("     add rule deps:   '${bright magenta}%s${clear}'", rules[index])
    end
    -- end
    table.insert(build_xmake, "end")
    table.insert(build_xmake, "rule_end()")
    table.insert(build_xmake, "")
end

function add_option(target, name)
    table.insert(build_xmake, "")
    table.insert(build_xmake, "-- this option is a collection of library options")
    table.insert(build_xmake, string.format('option("%s")', name))
    table.insert(build_xmake, "do")
    table.insert(build_xmake, "    set_default(true)")
    table.insert(build_xmake, "    set_showmenu(false)")
    -- start
    for index in pairs(table.orderkeys(options)) do
        table.insert(build_xmake, string.format('    add_deps("%s")', options[index]))
        cprint("     add option deps: '${bright magenta}%s${clear}'", options[index])
    end
    -- end
    table.insert(
        build_xmake,
        [[
    after_check(
        function(option)
            for _, dep_opt in pairs(option:orderdeps()) do
                option:add("defines", dep_opt:get("defines"))
            end
        end
    )]]
    )
    table.insert(build_xmake, "end")
    table.insert(build_xmake, "option_end()")
    table.insert(build_xmake, "")
end

function main()
    local target = project.target(project.name())
    assert(target, "not find target:'%s', please check your project name and target name are the same.", project.name())
    create_build_xmake(target)
end
