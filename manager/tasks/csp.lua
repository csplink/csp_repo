--!csp build system based on xmake
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
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
-- Copyright (C) 2022-present xqyjlj<xqyjlj@126.com>, csplink.github.io
--
-- @author      xqyjlj
-- @file        csp.lua
--

set_xmakever("2.7.2")

task("csp")
do
    on_run("scripts/csp_on_run")
    set_category("plugin")
    -- 设置插件的命令行选项，这里没有任何参数选项，仅仅显示插件描述
    set_menu {
        usage = "xmake csp [options]",
        description = "CSP build system options",
        options = {
            {"i",   "install",       "k",    nil,        "init this project and install packages to this computer"},
        }
    }
end
task_end()
