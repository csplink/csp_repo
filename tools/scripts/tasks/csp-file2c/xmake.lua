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
-- 2023-11-05     xqyjlj       initial version
--

task("csp-file2c")
do
    on_run("main")
    set_category("plugin")
    set_menu {
        usage = "xmake csp-file2c [options]",
        description = "Convert file to array of C files",
        options = {
            {"i",   "input",            "kv",   nil,                                        "Input file.",},
            {"o",   "output",           "kv",   nil,                                        "Output file.",},
            {"e",   "endian",           "kv",   "little",                                   "Memory endianness.",
                                                                                            "    - bug",
                                                                                            "    - little",},
            {"u",   "unit",             "kv",   4,                                          "Eemory unit size.",},
        }
    }
end
task_end()