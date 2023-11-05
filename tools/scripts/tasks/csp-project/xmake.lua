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
-- @file        xmake.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-10-19     xqyjlj     initial version
--

task("csp-project")
do
    on_run("main")
    set_category("plugin")
    set_menu {
        usage = "xmake csp-project [options]",
        description = "Generate the project file.",
        options = {
            {"k",   "kind",             "kv",   "cmake",                                    "Set the project kind.",
                                                                                            "    - cmake",
                                                                                            "    - cmakelists",},
            {nil,   "outputdir",        "v",    ".",                                        "Set the output directory."},
        }
    }
end
task_end()
