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
import("core.package.package")
import("private.action.require.impl.utils.filter")
import("devel.git")

function main()
    -- show urls
    for _, packagedir in ipairs(os.dirs(path.absolute(path.join(os.scriptdir(), "..", "packages", "*", "*")))) do
        local packagename = path.filename(packagedir)
        local packagefile = path.join(packagedir, "xmake.lua")
        local packageinstance = package.load_from_repository(packagename, packagedir, {packagefile = packagefile})
        local on_load = packageinstance:get("load")
        if on_load then
            on_load(packageinstance)
        end
        -- show urls
        local instance = packageinstance
        local urls = instance:urls()
        if instance:is_precompiled() then
            instance:fallback_build()
            local urls_raw = instance:urls()
            if urls_raw then
                urls = table.join(urls, urls_raw)
            end
        end
        -- print(packageinstance:get("versions"))

        if urls and #urls > 0 then
            cprint("      -> ${color.dump.string_quote}urls${clear}:")
            for _, url in ipairs(urls) do
                for version, _ in pairs(packageinstance:get("versions")) do
                    instance:version_set(version)
                    print("         -> %s", filter.handle(url, instance))
                    if git.asgiturl(url) then
                        local url_alias = instance:url_alias(url)
                        cprint("            -> ${yellow}%s",
                               instance:revision(url_alias) or instance:tag() or instance:version_str())
                    else
                        local sourcehash = instance:sourcehash(instance:url_alias(url))
                        if sourcehash then
                            cprint("            -> ${yellow}%s", sourcehash)
                        end
                    end
                end
            end
        end
    end
end
