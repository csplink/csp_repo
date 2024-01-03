--
-- Licensed under the GNU General Public License v. 3 (the "License")
-- You may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     https://www.gnu.org/licenses/gpl-3.0.html
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2023-2024 xqyjlj<xqyjlj@126.com>
--
-- @author      xqyjlj
-- @file        main.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2024-01-03     xqyjlj       initial version
--
import("core.project.config")
import("core.base.option")
import("core.project.project")
import("core.package.package")
import("private.action.require.impl.utils.filter")
import("devel.git")

function get_download_url(packagename, version)
    version = version or "latest"
    local rootdir = path.absolute(path.join(os.scriptdir(), "..", "..", "..", ".."))
    local packagedir = path.join(rootdir, "packages", string.sub(packagename, 1, 1), packagename)
    local packagefile = path.join(packagedir, "xmake.lua")

    local instance = package.load_from_repository(packagename, packagedir, {packagefile = packagefile})
    local on_load = instance:get("load")
    if on_load then
        on_load(instance)
    end

    local urls = instance:urls()
    if instance:is_precompiled() then
        instance:fallback_build()
        local urls_raw = instance:urls()
        if urls_raw then
            urls = table.join(urls, urls_raw)
        end
    end

    local rtn = {}
    if version == "latest" then
        for _, url in ipairs(urls) do
            local u = git.asgiturl(url)
            if u then
                table.insert(rtn, u)
            end
        end
    else
        local versions = instance:get("versions")
        local version_keys = table.orderkeys(versions)
        assert(table.contains(version_keys, version), "invalid version \"%s\" in {\"%s\"}", version,
               table.concat(version_keys, "\", \""))

        instance:version_set(version)
        for _, url in ipairs(urls) do
            if not git.asgiturl(url) then
                table.insert(rtn, filter.handle(url, instance))
            end
        end
    end

    return rtn
end

function main()
    config.load()
    project.load_targets()

    if option.get("list") then
    end
end
