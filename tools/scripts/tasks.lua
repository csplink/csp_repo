--
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
-- @file        tasks.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-02-22     xqyjlj       add sdk
-- 2023-02-21     xqyjlj       initial version
--
set_xmakever("2.7.2")

task("csp_repo")
do
    on_run("tasks/on_run")
    set_category("plugin")
    set_menu {
        usage = "xmake csp_repo [options]",
        description = "csp repo plugin",
        options = {
            {nil,   "sdks",             "k",    nil,        "get sdk list."},
            {nil,   "sdk",              "kv",   nil,        "get sdk info."},
        }
    }
end
task_end()
