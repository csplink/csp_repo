--
-- Licensed under the GNU General Public License v. 3 (the "License")
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
-- Copyright (C) 2023-2024 xqyjlj<xqyjlj@126.com>
--
-- @author      xqyjlj
-- @file        main.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2024-01-03     xqyjlj       initial version
--
import("core.project.config")
import("core.base.option")
import("core.base.json")
import("core.project.project")
import("core.package.package")
import("private.action.require.impl.utils.filter")
import("devel.git")
import("net.fasturl")
import("net.http")
import("utils.archive")

local rootdir = path.absolute(path.join(os.scriptdir(), "..", "..", "..", ".."))

function get_download_url(packagename, version)
    version = version or "latest"
    local packagedir = path.join(rootdir, "packages", string.sub(packagename, 1, 1), packagename)
    local packagefile = path.join(packagedir, "xmake.lua")

    local instance = package.load_from_repository(packagename, packagedir, {packagefile = packagefile})
    local on_load = instance:get("load")
    if on_load then
        on_load(instance)
    end

    local urls = instance:urls()
    if instance:is_precompiled() then
        instance:fallback_build()
        local urls_raw = instance:urls()
        if urls_raw then
            urls = table.join(urls, urls_raw)
        end
    end

    local rtn = {}
    if version == "latest" then
        for _, url in ipairs(urls) do
            local u = git.asgiturl(url)
            if u then
                rtn[u] = ""
            end
        end
    else
        local versions = instance:get("versions")
        local version_keys = table.orderkeys(versions)
        assert(table.contains(version_keys, version), "invalid version \"%s\" in %s:{\"%s\"}", version, packagename,
               table.concat(version_keys, "\", \""))

        instance:version_set(version)
        for _, url in ipairs(urls) do
            if not git.asgiturl(url) then
                rtn[filter.handle(url, instance)] = versions[version]
            end
        end
    end

    return rtn
end

function list_table(repositories_dir)
    local list = {}
    for _, packagedir in ipairs(os.dirs(path.join(repositories_dir, "*"))) do
        local hal = path.relative(packagedir, repositories_dir)
        if not list[hal] then
            list[hal] = {}
        end
        for _, versiondir in ipairs(os.dirs(path.join(packagedir, "*"))) do
            local version = path.relative(versiondir, packagedir)
            if os.isdir(path.join(versiondir, ".git")) then
                local sha = git.lastcommit({repodir = versiondir})
                list[hal][version] = sha
            else
                list[hal][version] = ""
            end
        end
    end
    return list
end

function dump_table()
    local packagelist = {toolchain = {}, library = {}}
    for _, packagedir in ipairs(os.dirs(path.join(rootdir, "packages", "*", "*"))) do
        local packagename = path.filename(packagedir)
        local packagefile = path.join(packagedir, "xmake.lua")
        local packageinstance = package.load_from_repository(packagename, packagedir, {packagefile = packagefile})
        local on_load = packageinstance:get("load")
        if on_load then
            on_load(packageinstance)
        end
        local pkg = {}
        local urls = packageinstance:get("urls") or os.raise("%s urls is empty", packagename)
        local versions = packageinstance:get("versions") or {latest = "nil"}
        local description = packageinstance:get("description") or "unknown"
        local homepage = packageinstance:get("homepage") or "unknown"
        local license = packageinstance:get("license") or "unknown"

        if type(urls) == "table" then
            pkg["urls"] = urls
        else
            pkg["urls"] = {urls}
        end

        pkg["versions"] = packageinstance:get("versions") or {latest = "nil"}
        pkg["description"] = description
        pkg["homepage"] = homepage
        pkg["license"] = license

        if packageinstance:get("kind") then
            packagelist[packageinstance:get("kind")][packagename] = pkg
        else
            packagelist["library"][packagename] = pkg
        end
    end
    return packagelist
end

function is_installed(packagename, version, repositories_dir)
    return os.isdir(path.join(repositories_dir, packagename, version))
end

function install(packagename, version, repositories_dir)
    local urls = get_download_url(packagename, version)
    local outputdir = path.join(repositories_dir, packagename, version)
    local download_urls = table.orderkeys(urls)
    fasturl.add(download_urls)
    download_urls = fasturl.sort(download_urls)
    local url = download_urls[1]
    if git.asgiturl(url) then
        git.clone(url, {recursive = true, longpaths = true, outputdir = outputdir})
    else
        local file = path.join(repositories_dir, packagename, (path.filename(url):gsub("%?.+$", "")))
        http.download(url, file)
        local sourcehash = urls[url]
        local sha256 = hash.sha256(file)
        if sha256 == sourcehash then
            local tmp = repositories_dir .. ".tmp"
            archive.extract(file, tmp)
            local filedirs = os.filedirs(path.join(tmp, "*"))
            if #filedirs == 1 and os.isdir(filedirs[1]) then
                os.mv(filedirs[1], outputdir)
                os.rm(tmp)
            else
                os.mv(tmp, outputdir)
            end
        else
            raise("unmatched checksum, current hash(%s) != original hash(%s)", sha256:sub(1, 8), sourcehash:sub(1, 8))
        end
    end
end

function uninstall(packagename, version, repositories_dir)
    if is_installed(packagename, version, repositories_dir) then
        os.rm(path.join(repositories_dir, packagename, version))
    end
end

function main()
    config.load()
    project.load_targets()

    if option.get("list") then
        assert(option.get("repositories"), "must set repositories dir")
        local value = option.get("list")
        if value == "json" then
            local list = list_table(option.get("repositories"))
            print(json.encode(list))
        elseif value == "table" then
            local list = list_table(option.get("repositories"))
            print(list)
        else
            assert(false, "invalid type \"%s\"", value)
        end
    elseif option.get("dump") then
        local value = option.get("dump")
        if value == "json" then
            local list = dump_table()
            print(json.encode(list))
        elseif value == "table" then
            local list = dump_table()
            print(list)
        else
            assert(false, "invalid type \"%s\"", value)
        end
    elseif option.get("install") then
        assert(option.get("repositories"), "must set repositories dir")
        local value = option.get("install")
        local list = value:split("@")
        assert(#list == 2, "invalid input \"%s\", eq. xmake csp-repo --install=csp_hal_apm32f1@latest -r {dir}", value)
        local packagename = list[1]
        local version = list[2]
        install(packagename, version, option.get("repositories"))
    elseif option.get("uninstall") then
        assert(option.get("repositories"), "must set repositories dir")
        local value = option.get("uninstall")
        local list = value:split("@")
        assert(#list == 2, "invalid input \"%s\", eq. xmake csp-repo --uninstall=csp_hal_apm32f1@latest -r {dir}", value)
        local packagename = list[1]
        local version = list[2]
        uninstall(packagename, version, option.get("repositories"))
    end
end
