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
-- @file        get_hal.lua
--

import("net.fasturl")
import("devel.git.checkurl")
import("lib.detect.find_tool")
import("csp.base.semver")
import("csp.base.realdir")
import("csp.devel.git")

local scriptdir = string.gsub(path.absolute(os.scriptdir()), "\\", "/")
local package_haldir = scriptdir .. "/../../../packages/hal"
local repository_haldir = scriptdir .. "/../../../repositories/hal"
package_haldir = realdir.main(package_haldir)
repository_haldir = realdir.main(repository_haldir)

function main(hal_value)
    local hal, version, configuration = semver.hal(hal_value)
    local hal_path = string.format("%s/%s/%s", repository_haldir, hal, version)
    cprint("${yellow}  => ${clear}${yellow}download hal package to this computer ......")
    if not os.exists(hal_path) then
        local urls = configuration["repositories"]
        for _, url in ipairs(configuration["versions"][version]) do
            table.insert(urls, url)
        end
        fasturl.add(urls)
        urls = fasturl.sort(urls)
        local url = urls[1]
        if checkurl.main(url) then
            git.clone(hal_path, url, version)
        end
    else
        cprint('     hal: "${bright magenta}%s@%s${clear}" is already installed:', hal, version)
        cprint('          "%s"', hal_path)
        cprint("${yellow}  => ${clear}${yellow}sync submodule ......")
        git.submodule_sync(hal_path, version)
    end
end
