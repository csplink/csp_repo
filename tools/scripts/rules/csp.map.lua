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
-- @file        csp.map.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-02-19     xqyjlj       initial version
--
rule("csp.map")
do
    on_config(function(target)
        import("core.project.config")
        local artifact_dir = path.join(config.buildir(), config.plat(), config.arch(), config.mode())

        if not os.exists(artifact_dir) then
            os.mkdir(artifact_dir)
        else
            if not os.isdir(artifact_dir) then
                os.rm(artifact_dir)
                os.mkdir(artifact_dir)
            end
        end

        local map = path.join(artifact_dir, target:name() .. ".map")
        target:add("ldflags", "-Wl,-Map=" .. map, {force = true})
    end)
end
rule_end()
