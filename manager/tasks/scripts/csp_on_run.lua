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
-- 2023-01-02     xqyjlj       initial version
--

import("core.project.project")
import("core.project.config")
import("core.base.option")

import("install")
import("get_hal")

local install_flag = false
local hal_value = ""

function main()
    if option.get("install") then
        install_flag = true
    elseif option.get("get-hal") then
        hal_value = option.get("get-hal")
    end

    if install_flag == true then
        install.main()
    end
    if not hal_value:trim() == "" then
        get_hal.main(hal_value)
    end
end
