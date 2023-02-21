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
-- @file        packages.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-02-21     xqyjlj       initial version
--
import("core.package.package")
import("core.platform.platform")

local packages_dir = path.join(os.scriptdir(), "..", "..", "packages")

function main(opt)
    local packages = {}
    for _, package_dir in ipairs(os.dirs(path.join(packages_dir, "*", "*"))) do
        local package_name = path.filename(package_dir)
        local package_file = path.join(package_dir, "xmake.lua")
        local instance = package.load_from_repository(package_name, nil, package_dir, package_file)
        local basename = instance:get("base")
        if instance and basename then
            local basedir = path.join("packages", basename:sub(1, 1):lower(), basename:lower())
            local basefile = path.join(basedir, "xmake.lua")
            instance._BASE = package.load_from_repository(basename, nil, basedir, basefile)
        end
        if instance then
            local description = instance:description()
            local type_name = "unknown"
            if description:startswith("sdks: ") then
                type_name = "sdks"
            end
            packages[type_name] = packages[type_name] or {}
            table.insert(packages[type_name], {
                name = instance:name(),
                instance = instance,
                type = type_name
            })
        end
    end
    for _, packages_type in pairs(packages) do
        table.sort(packages_type, function(a, b)
            return a.name < b.name
        end)
    end
    return packages
end
