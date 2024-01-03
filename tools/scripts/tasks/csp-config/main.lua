--
-- Licensed under the GNU General Public License v. 3 (the "License");
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
-- Copyright (C) 2023-2023 xqyjlj<xqyjlj@126.com>
--
-- @author      xqyjlj
-- @file        main.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-12-17     xqyjlj       initial version
--
-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.base.task")
import("lib.detect.find_tool")

function main(opt)
    task.run("config") -- config it first
    local cfgfile = ".xmake.cfg"
    local args = {"config", "--export=" .. cfgfile}
    local xmake = find_tool("xmake")
    local unneeded = {"verbose", "diagnosis", "menu", "yes", "quiet"}
    if not xmake then
        os.raise("xmake not find")
    end

    for name, value in pairs(option.options()) do
        value = tostring(value):trim()
        if value ~= "" then
            if type(name) == "number" then
                table.insert(args, value)
            else
                if not table.contains(unneeded, name) then
                    table.insert(args, "--" .. name .. "=" .. value)
                end
            end
        end
    end

    if os.isfile(path.join(os.projectdir(), ".xmake.cfg")) then
        table.insert(args, "--import=" .. cfgfile)
    end

    if option.get("menu") then
        table.insert(args, "--menu")
    end

    args = table.unique(args)

    os.vexecv(xmake.program, args)
end
