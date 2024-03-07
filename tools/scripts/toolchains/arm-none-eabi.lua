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
-- @file        arm-none-eabi.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-07-03     xqyjlj       initial version
--
toolchain("arm-none-eabi") -- add toolchain
do
    set_kind("cross") -- set toolchain kind
    set_description("The GNU Arm Embedded Toolchain.")

    on_load(function(toolchain)
        toolchain:load_cross_toolchain()
        toolchain:set("toolset", "cc", "arm-none-eabi-gcc")
        toolchain:set("toolset", "cxx", "arm-none-eabi-g++")
        toolchain:set("toolset", "ld", "arm-none-eabi-g++")
        toolchain:set("toolset", "ar", "arm-none-eabi-ar")
        toolchain:set("toolset", "as", "arm-none-eabi-gcc")
        toolchain:set("toolset", "objcopy", "arm-none-eabi-objcopy")
        toolchain:set("toolset", "size", "arm-none-eabi-size")

        toolchain:add("cxflags", "-mthumb", "-mthumb-interwork", "-ffunction-sections", "-fdata-sections", "-fno-common", "-fmessage-length=0", {force = true})
        toolchain:add("asflags", "-mthumb", "-mthumb-interwork", "-ffunction-sections", "-fdata-sections", "-fno-common", "-fmessage-length=0", "-x", " assembler-with-cpp",
                      {force = true})
        toolchain:add("ldflags", "-mthumb", "-mthumb-interwork", "-ffunction-sections", "-fdata-sections", "-fno-common", "-fmessage-length=0", "-Wl,--gc-sections",
                      "-Wl,--print-memory-usage", {force = true})
    end)
end
toolchain_end()
