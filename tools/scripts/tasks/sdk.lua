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
-- @file        sdk.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-02-22     xqyjlj       initial version
--
import("core.base.json")

import("packages")

function main(name)
    for _, pkg in pairs(packages()["sdks"]) do
        if pkg.name == name then
            local info = {}
            info.name = pkg.name
            info.description = pkg.instance:description()
            info.license = pkg.instance:license()
            info.urls = pkg.instance:urls()
            info.homepage = pkg.instance:get("homepage")
            info.kind = pkg.instance:kind()
            info.deps = pkg.instance:deps()
            info.versions = pkg.instance:versions()
            info.configs = pkg.instance:configs()
            print(info)
            vprint(json.encode(info))
        end
    end
end
