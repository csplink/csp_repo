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
-- 2023-03-04     xqyjlj       adapt to XMAKE_RCFILES
-- 2023-02-21     xqyjlj       add tasks
-- 2023-02-19     xqyjlj       initial version
--
set_xmakever("2.7.2")

local dir = ""
local rcfiles = os.getenv("XMAKE_RCFILES")
if rcfiles then
    dir = path.directory(rcfiles) .. "/"
end

add_repositories("csp-repo " .. dir .. "../../repo")

includes(dir .. "flags.lua")
includes(dir .. "rules.lua")
includes(dir .. "toolchains.lua")
includes(dir .. "tasks.lua")