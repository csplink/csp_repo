-- !csp build system based on xmake
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
-- 2023-01-02     xqyjlj       initial version
--
add_rules("mode.debug", "mode.release")

set_project("sample_project") -- set project name
set_version("0.0.0") -- set version
set_xmakever("2.7.2")
add_repositories("local-repo ../../")

includes("../../scripts/xmake.lua")
local default_config = csp_get_default_flags("cpu_cortex_m3")
local cflags = default_config.cflags
local asflags = default_config.asflags
local ldflags = default_config.ldflags

add_requires("csp_hal_apm32f1", {configs = {cflags = cflags, asflags = asflags}, debug = true})

if not get_config("sdk") then
    set_config("sdk", "D:/Users/xqyjlj/Documents/csplink/toolchains/gcc-arm-none-eabi-10-2020-q4-major") -- set toolchain directory
end

set_toolchains("arm-none-eabi") -- set toolchains

target("sample_project")
do
    set_kind("binary")
    set_languages("c99")
    set_extension(".elf")

    add_packages("csp_hal_apm32f1")

    add_files("main.c")

    add_rules("csp_map", "csp_bin")

    table.insert(ldflags, "-T./linkscripts/gcc/APM32F103xE.lds")
    add_cflags(cflags, {force = true})
    add_asflags(asflags, {force = true})
    add_ldflags(ldflags, {force = true})
end
target_end()
