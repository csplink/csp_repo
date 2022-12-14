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
-- @file        change_objdir.lua
--

import("core.project.config")

function main(target, sourcebatch, opt)
    if target:values("targetdir") then
        local targetdir = path.absolute(target:values("targetdir"))
        os.cd(targetdir)
        targetdir = os.curdir()
        os.cd(os.projectdir())
        objectfiles = {}
        dependfiles = {}
        sourcefiles = {}
        for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
            local abs_sourcefile = path.absolute(sourcefile)
            if sourcefile:len() > abs_sourcefile:len() then
                table.insert(sourcefiles, abs_sourcefile)
            else
                table.insert(sourcefiles, sourcefile)
            end
            sourcefile = path.relative(abs_sourcefile, targetdir)
            local objectfile = string.format("build/.objs/%s/%s/%s.o", target:name(), config.mode(), sourcefile)
            local dependfile = string.format("build/.deps/%s/%s/%s.o.d", target:name(), config.mode(), sourcefile)
            table.insert(objectfiles, objectfile)
            table.insert(dependfiles, dependfile)
        end
        sourcebatch.objectfiles = objectfiles
        sourcebatch.dependfiles = dependfiles
        sourcebatch.sourcefiles = sourcefiles
    end
    import("private.action.build.object").build(target, sourcebatch, opt)
end
