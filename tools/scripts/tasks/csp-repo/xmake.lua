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
-- @file        xmake.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2024-01-03     xqyjlj       initial version
--
task("csp-repo")
do
    on_run("main")
    set_category("plugin")
    -- LuaFormatter off
    set_menu {
        usage = "xmake csp-repo [options]",
        description = "Manage package repositories.",
        options = {
            {"l",   "list",             "kv",   nil,        "List all installed packages.",
                                                            "    - json",
                                                            "    - table",},
            {"d",   "dump",             "kv",   nil,        "Dump all packages.",
                                                            "    - json",
                                                            "    - table",},
            {nil,   "install",          "kv",   nil,        "Install the packages.",
                                                            "e.g.",
                                                            "    - xmake csp-repo --install=csp_hal_apm32f1@latest -r {dir}"},
            {nil,   "uninstall",        "kv",   nil,        "Uninstall the installed packages.",
                                                            "e.g.",
                                                            "    - xmake csp-repo --uninstall=csp_hal_apm32f1@latest -r {dir}"},
            {"r",   "repositories",     "kv",   nil,        "Set the repositories dir."},

        }
    }
    -- LuaFormatter on
end
task_end()
