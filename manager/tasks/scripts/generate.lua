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
-- @file        generate.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-01-06     xqyjlj       initial version
--

import("core.base.option")
import("core.project.project")
import("csp.base.logo")
import("csp.devel.git")

function generate_header()
    local header = {}
    for _, optname in pairs(table.orderkeys(project.options())) do
        local opt = project.options()[optname]
        if opt:info().showmenu then
            local info = {}
            local key = "/"

            -- init info object
            info.name = optname
            info.description = opt:info().description
            -- convert boolean to 1 and 0
            if opt:value() == true then
                info.value = 1
            elseif opt:value() == false then
                info.value = 0
            elseif opt:value() == nil then
                info.value = opt:info().default -- if opt:value() is nil, then use default
            else
                info.value = opt:value()
            end

            if opt:info().category then
                key = opt:info().category
            else
                key = "/" -- if not use set_category, then use default "/"
            end

            if not header[key] then
                header[key] = {} -- create new info table
            end

            header[key][info.name] = info
        end
    end
    return header
end

function generate_file(header)
    local t = {}
    local sdk_builtinvars = git.get_builtinvars(os.projectdir())

    table.insert(t, "/** ")
    for _, line in ipairs(logo.get_header():split("\n")) do
        table.insert(t, " " .. ("* " .. line):trim())
    end
    table.insert(t, " */\n") -- end

    -- macro
    table.insert(t, "#ifndef __CSP_CONFIG_H__")
    table.insert(t, "#define __CSP_CONFIG_H__")
    table.insert(t, "")
    for _, k in pairs(table.orderkeys(sdk_builtinvars)) do
        table.insert(t, "#define CSP_" .. k:upper() .. ' "' .. sdk_builtinvars[k] .. '"')
    end

    for _, mk in pairs(table.orderkeys(header)) do
        table.insert(t, "\n/* " .. mk .. " */")
        for _, k in pairs(table.orderkeys(header[mk])) do
            local description = ""
            local value = ""
            local v = header[mk][k]
            if v.description then
                description = " /* " .. v.description .. " */" -- add description
            end
            if type(v.value) == "string" then
                value = '"' .. v.value .. '"' -- string should be wrapped with ""
            else
                value = v.value
            end
            table.insert(t, "#define " .. k .. " " .. value .. description)
        end
    end
    table.insert(t, "\n#endif")
    return table.concat(t, "\n") .. "\n"
end

function main()
    local data = generate_file(generate_header())
    io.writefile("$(buildir)/csp_conf.h", data)
end
