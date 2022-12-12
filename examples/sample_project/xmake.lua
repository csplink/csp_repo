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
-- @file        xmake.lua
--

--! In order to build this project, you need to set CSP_REPO in your env,
-- e.g. :
--      powershell: $env:CSP_REPO="D:\Users\xqyjlj\Documents\git\github\csplink\csp_repo"
--      cmd:        set CSP_REPO="D:\Users\xqyjlj\Documents\git\github\csplink\csp_repo"
--      bash:       export CSP_REPO="/home/csplink/git/github/csplink/csp_repo"
-- see more: https://csplink.github.io/#/zh-cn/packages/getting_started

add_rules("mode.debug", "mode.release")

set_project("sample_project") -- set project name
set_version("0.0.0") -- set version
set_xmakever("2.7.2")

local csp_repo = os.getenv("CSP_REPO")
if not csp_repo then
    print("please check 'CSP_REPO' in your path")
end

includes(csp_repo .. "/csplink.lua")

add_cflags(
    "-mcpu=cortex-m3",
    "-mthumb",
    "-mthumb-interwork",
    "-ffunction-sections",
    "-fdata-sections",
    "-fno-common",
    "-fmessage-length=0",
    "-Wall",
    "-Werror",
    {force = true}
)

add_asflags(
    "-mcpu=cortex-m3",
    "-mthumb",
    "-mthumb-interwork",
    "-ffunction-sections",
    "-fdata-sections",
    "-fno-common",
    "-fmessage-length=0",
    "-Wall",
    "-Werror",
    "-x assembler-with-cpp",
    {force = true}
)

add_ldflags(
    "-mcpu=cortex-m3",
    "-mthumb",
    "-mthumb-interwork",
    "-Wl,--gc-sections",
    "-T../../../linkscripts/gcc/APM32F103xE.lds",
    {force = true}
)

target("sample_project")
do
    set_kind("binary")
    set_languages("c99")
    set_extension(".elf")
    set_values("hal", "csp_hal_apm32f1@latest")
    set_values("toolchain", "arm-none-eabi")
    add_deps("csp_target")
    add_rules("csp_rule")
    add_options("csp_option")
    add_files("main.c")
end
target_end()
