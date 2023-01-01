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
-- Copyright (C) 2022-present xqyjlj<xqyjlj@126.com>
--
-- @author      xqyjlj
-- @file        arm-none-eabi.lua
--

set_xmakever("2.7.2")

if not get_config("sdk") then
    set_config("sdk", "/opt/gcc-arm-none-eabi-10-2020-q4-major") -- set toolchain directory
end
toolchain("arm-none-eabi") -- add toolchain
do
    set_kind("cross") -- set toolchain kind
    set_description("arm embedded compiler")
    set_toolset("cc", "arm-none-eabi-gcc")
    set_toolset("ld", "arm-none-eabi-gcc")
    set_toolset("ar", "arm-none-eabi-ar")
    set_toolset("as", "arm-none-eabi-gcc")
end
toolchain_end()
set_toolchains("arm-none-eabi") -- set toolchains
set_config("plat", "cross")
set_config("compiler", "gcc")
set_config("prefix", "arm-none-eabi-")
