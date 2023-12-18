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
-- @file        main.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-12-17     xqyjlj       initial version
--
-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.base.task")

function main()
    local input_file = option.get("input")
    local output_file = option.get("output")

    assert(input_file, "must set input file")
    assert(os.isfile(input_file), string.format("%s is not file or not exists", input_file))

    if not output_file then
        output_file = path.basename(input_file) .. ".c"
        output_file = path.join(path.directory(input_file), output_file)
    end

    array_name = path.basename(output_file)

    local ifile = io.open(input_file, "rb")
    local ofile = io.open(output_file, "w+")
    local isize = os.filesize(input_file)
    local chunk_size = 1024
    if ifile and ofile then
        ofile:printf('const unsigned char %s[%d] = {\n    ', array_name, isize)
        while true do
            local read_size;

            if isize > chunk_size then
                read_size = chunk_size
            else
                read_size = isize
            end

            local chunk = ifile:read(read_size)
            if not chunk then
                break
            end

            for i = 1, #chunk do
                local byte = string.byte(chunk, i)
                ofile:printf('0x%02x, ', byte);
                if not (i % 16) then
                    ofile:printf('\n    ')
                end
            end

            isize = isize - read_size

            if not isize then
                break
            end
        end
    end
    ifile:close()
    ofile:printf('\n}')
    ofile:close()
end
