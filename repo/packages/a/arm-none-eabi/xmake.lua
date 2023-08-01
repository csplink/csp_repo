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
-- Copyright (C) 2023-2023 xqyjlj<xqyjlj@126.com>
--
-- @author      xqyjlj
-- @file        xmake.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-07-03     xqyjlj       initial version
--
package("arm-none-eabi")
do
    set_kind("toolchain")
    set_homepage("https://developer.arm.com/downloads/-/gnu-rm")
    set_description("The GNU Arm Embedded Toolchain.")

    if is_host("windows") then
        add_urls(
            "https://github.com/csplink/toolchains/releases/download/arm-none-eabi/gcc-arm-none-eabi-$(version)-win32.zip")
        add_versions("10-2020-q4-major", "90057b8737b888c53ca5aee332f1f73c401d6d3873124d2c2906df4347ebef9e")
    elseif is_host("linux") then
        add_urls(
            "https://github.com/csplink/toolchains/releases/download/arm-none-eabi/gcc-arm-none-eabi-$(version)-x86_64-linux.tar.bz2")
        add_versions("10-2020-q4-major", "21134caa478bbf5352e239fbc6e2da3038f8d2207e089efc96c3b55f1edcd618")
    end

    on_install("@windows", "@linux|x86_64", function(package)
        os.vcp("*", package:installdir(), {rootdir = ".", symlink = true})
        package:addenv("PATH", "bin")
    end)

    on_test(function(package)
        local gcc = "arm-none-eabi-gcc"
        if is_host("windows") then
            gcc = gcc .. ".exe"
        end
        local file = os.tmpfile() .. ".c"
        io.writefile(file, "int main(int argc, char** argv) {return 0;}")
        os.vrunv(gcc, {"-c", file})
    end)
end
