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
-- @file        flags.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-02-16     xqyjlj       initial version
--
set_xmakever("2.7.2")

for _, file in ipairs(os.files(path.join(os.scriptdir(), "flags", "*lua"))) do
    includes(file)
end

function csp_get_default_flags(name)
    if name == "cpu_cortex_m3" then
        return cpu_cortex_m3_flags()
    else
        return {cflags = {}, asflags = {}, ldflags = {}}
    end
end
