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
-- @file        cpu_cortex_m3.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-02-16     xqyjlj       initial version
--
set_xmakever("2.7.2")

function cpu_cortex_m3_flags()
    return {
        cflags = {
            "-mcpu=cortex-m3", "-mthumb", "-mthumb-interwork", "-ffunction-sections", "-fdata-sections", "-fno-common",
            "-fmessage-length=0"
        },
        asflags = {
            "-mcpu=cortex-m3", "-mthumb", "-mthumb-interwork", "-ffunction-sections", "-fdata-sections", "-fno-common",
            "-fmessage-length=0", "-x assembler-with-cpp"
        },
        ldflags = {
            "-mcpu=cortex-m3", "-mthumb", "-mthumb-interwork", "-Wl,--gc-sections", "-Wl,--print-memory-usage"
        }
    }
end
