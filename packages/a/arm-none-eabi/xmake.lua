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

    local versions = {["v10.2.1"] = "10-2020-q4-major", ["v10.3.1"] = "10.3-2021.10"}

    if is_host("windows") then
        add_urls(
            "https://github.com/csplink/toolchains/releases/download/arm-none-eabi/gcc-arm-none-eabi-$(version)-win32.zip",
            {
                version = function(version)
                    return versions[version:rawstr()]
                end
            })
        add_versions("v10.2.1", "90057b8737b888c53ca5aee332f1f73c401d6d3873124d2c2906df4347ebef9e")
        add_versions("v10.3.1", "d287439b3090843f3f4e29c7c41f81d958a5323aecefcf705c203bfd8ae3f2e7")
    elseif is_host("linux") then
        add_urls(
            "https://github.com/csplink/toolchains/releases/download/arm-none-eabi/gcc-arm-none-eabi-$(version)-x86_64-linux.tar.bz2",
            {
                version = function(version)
                    return versions[version:rawstr()]
                end
            })
        add_versions("v10.2.1", "21134caa478bbf5352e239fbc6e2da3038f8d2207e089efc96c3b55f1edcd618")
        add_versions("v10.3.1", "97dbb4f019ad1650b732faffcc881689cedc14e2b7ee863d390e0a41ef16c9a3")
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
