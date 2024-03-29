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
package("csp_hal_apm32f1")
do
    set_homepage("https://github.com/csplink/csp_hal_apm32f1")
    set_description("APM32F1 SDK.")
    set_kind("library")
    set_license("Apache-2.0")

    add_urls("https://github.com/csplink/csp_hal_apm32f1/archive/$(version).tar.gz")
    add_urls("https://github.com/csplink/csp_hal_apm32f1.git")
    add_urls("https://gitlab.com/csplink/csp_hal_apm32f1.git")
    add_urls("https://gitee.com/csplink/csp_hal_apm32f1.git")
    add_urls("https://e.coding.net/csplink/csplink/csp_hal_apm32f1.git")

    add_versions("v0.0.1", "ea1f9967d8b35a184dafe39783d574046a2e65407f825f56c6c42727f8d5660f")

    on_install(function(package)
        import("package.tools.xmake").install(package)
    end)

    on_test(function(package)
        assert(os.isfile(path.join(package:installdir("lib"), "libcsp_hal_apm32f1.a")))
    end)
end
package_end()
