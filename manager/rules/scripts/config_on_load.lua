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
-- @file        config_on_load.lua
--

import("core.base.option")
import("core.project.config")
import("core.project.project")

-- import
function main(target)
    if option.get("menu") then -- if use menu then pass
        return
    end

    if os.isfile("csp.conf") then
        local import_configs = io.load("csp.conf")
        if import_configs then
            for _, k in pairs(table.orderkeys(import_configs)) do
                if config.get(k) then
                    config.set(k, import_configs[k], {force = true})
                end
            end
        end
    end
end
