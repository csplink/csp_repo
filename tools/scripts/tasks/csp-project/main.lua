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
import("cmake.cmakelists")
import("core.base.task")

function makers()
    -- LuaFormatter off
    return
    {
        cmake = cmakelists.main,
        cmakelists = cmakelists.main
    }
    -- LuaFormatter on
end

function _make(kind)
    local maps = makers()
    assert(maps[kind], "the project kind(%s) is not supported!", kind)
    maps[kind](option.get("outputdir"))
end

function main()
    task.run("config") -- config it first
    config.load()
    project.load_targets()
    _make(option.get("kind"))
    cprint("${color.success}create ok!")
end
