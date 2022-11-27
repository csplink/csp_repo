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

set_xmakever("2.7.2")

for _, dir in ipairs(os.dirs("/*")) do
    file = dir .. "/xmake.lua"
    if os.exists(file) then
        includes(file)
    end
end
