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
-- @file        csp.bin.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-08-01     xqyjlj       initial version
--
rule("csp.cpu")
do
    on_config(function(target)
        import("core.project.config")
        local arch = config.get("arch")
        local cpu = config.get("cpu")
        assert(arch, "must configure project arch")
        assert(cpu, "must configure project cpu")

        if arch == "arm" then
            if cpu == "cortex-m3" then
                target:add("cxflags", "-mcpu=cortex-m3", {force = true})
                target:add("asflags", "-mcpu=cortex-m3", {force = true})
                target:add("ldflags", "-mcpu=cortex-m3", {force = true})
            else
                os.raise("unsupport cpu <" .. cpu .. ">")
            end
        else
            os.raise("unsupport arch <" .. arch .. ">")
        end

    end)
end
rule_end()
