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
-- @file        csp_bin.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-02-19     xqyjlj       initial version
--
rule("csp.bin")
do
    after_link(function(target)
        import("core.project.config")
        local artifact_dir = path.join(config.buildir(), config.plat(), config.arch(), config.mode())
        local objcopy, _ = target:tool("objcopy")
        local size, _ = target:tool("size")

        if objcopy then
            local hex = path.join(artifact_dir, target:name() .. ".hex")
            os.vrunv(objcopy, {"-O", "ihex", target:targetfile(), hex})
            local bin = path.join(artifact_dir, target:name() .. ".bin")
            os.vrunv(objcopy, {"-O", "binary", target:targetfile(), bin})
        end
        if size then
            os.vexecv(size, {"--format=berkeley", target:targetfile()})
            -- os.vexecv(size, {"--format=sysv", target:targetfile()})
        end
    end)
end
rule_end()
