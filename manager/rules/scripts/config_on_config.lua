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
-- @file        config_on_config.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-01-06     xqyjlj       fix can`t import tasks.scripts.generate
-- 2023-01-06     xqyjlj       use generate
-- 2023-01-05     xqyjlj       use logo
-- 2023-01-02     xqyjlj       initial version
--

import("core.base.option")
import("core.project.project")
import("csp.base.logo")

import("..tasks.scripts.generate")

-- export
function save()
    local configs = {}
    for _, optname in pairs(table.orderkeys(project.options())) do
        local opt = project.options()[optname]
        if opt:info().showmenu then
            configs[optname] = opt:value()
        end
    end
    return io.save("csp.conf", configs, {orderkeys = true})
end

function main(target)
    if not option.get("menu") then
        return
    end

    logo.show()
    cprint("${bright green}config complete!")

    save() -- export config to ${projectdir}/csp.conf
    generate.main()
end
