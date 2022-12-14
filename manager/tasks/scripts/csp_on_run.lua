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
-- @file        csp_on_run.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-01-06     xqyjlj       add generate
-- 2023-01-03     xqyjlj       fix can not get-hal
-- 2023-01-02     xqyjlj       initial version
--

import("core.project.project")
import("core.project.config")
import("core.base.option")

import("install")
import("get_hal")
import("generate")

local install_flag = false
local hal_value = ""
local generate_flag = false

function main()
    if option.get("install") then
        install_flag = true
        generate_flag = true
    elseif option.get("get-hal") then
        hal_value = option.get("get-hal")
    elseif option.get("generate") then
        generate_flag = true
    end

    if install_flag then
        install.main()
    end
    if hal_value:trim() ~= "" then
        get_hal.main(hal_value)
    end
    if generate_flag then
        generate.main()
    end
end
