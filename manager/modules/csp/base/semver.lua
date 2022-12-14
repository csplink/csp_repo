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
-- @file        semver.lua
--

import("core.base.json")

local scriptdir = string.gsub(path.absolute(os.scriptdir()), "\\", "/")
local package_haldir = scriptdir .. "/../../../../packages/hal"

function hal(hal_value)
    local hal_array = hal_value:split("@")
    local hal = ""
    local version = "latest" -- default latest
    if #hal_array == 1 then -- "csp_hal_apm32f1"
        hal = string.trim(hal_array[1])
    elseif #hal_array == 2 then -- "csp_hal_apm32f1@v0.0.1"
        hal = string.trim(hal_array[1])
        version = string.trim(hal_array[2])
    else
        assert(false, "error value: '%s', please check hal`s value is correct.", hal_value)
    end
    -- use semver to parse version
    local json_path = path.translate(package_haldir .. "/" .. hal .. ".json")
    local configuration = json.loadfile(json_path)
    local versions = table.orderkeys(configuration["versions"])
    if not table.contains(versions, "latest") then
        table.insert(versions, "latest")
    end
    version, source = import("core.base.semver").select(version, versions)
    cprint("${yellow}  => ${clear}${yellow}parsing hal and version ......")
    cprint("     use hal: '${bright magenta}%s${clear}' ", hal)
    cprint("     version: '${bright magenta}%s${clear}'", version)
    return hal, version, configuration
end
