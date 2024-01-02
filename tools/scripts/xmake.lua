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
-- @file        xmake.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-12-17     xqyjlj       initial version
--
set_xmakever("2.8.6")

local dir = ""
local rcfiles = os.getenv("XMAKE_RCFILES")
if rcfiles then
    dir = path.directory(rcfiles) .. "/"
end

add_repositories("csp-repo " .. dir .. "../..")

includes(dir .. "flags.lua")
includes(dir .. "modules.lua")
includes(dir .. "options.lua")
includes(dir .. "rules.lua")
includes(dir .. "toolchains.lua")
includes(dir .. "tasks.lua")
