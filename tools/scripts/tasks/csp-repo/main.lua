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
import("lib.detect.find_tool")

local rootdir = path.absolute(path.join(os.scriptdir(), "..", "..", "..", ".."))
local packages_json_file = ""
local packages_json = {}

function load_packages_json()
    packages_json_file = path.join(option.get("repositories"), "packages.json")
    if os.isfile(packages_json_file) then
        packages_json = json.loadfile(packages_json_file)
    end
end

-- get download url from package xmake
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
        assert(table.contains(version_keys, version), "invalid version \"%s\" in %s:{\"%s\"}", version, packagename, table.concat(version_keys, "\", \""))

        instance:version_set(version)
        for _, url in ipairs(urls) do
            if not git.asgiturl(url) then
                rtn[filter.handle(url, instance)] = versions[version]
            end
        end
    end

    return rtn
end

-- check installed
function is_installed(packagename, version)
    local repositories_dir = option.get("repositories")
    local installed = false
    local outputdir = path.join(repositories_dir, packagename, version)

    if packages_json[packagename] and packages_json[packagename][version] and packages_json[packagename][version].installed then
        if os.isdir(path.join(outputdir, ".csplink")) then
            installed = true
        end
    end

    -- init packages json status
    if not packages_json[packagename] then
        packages_json[packagename] = {}
    end
    if not packages_json[packagename][version] then
        packages_json[packagename][version] = {}
    end
    packages_json[packagename][version].installed = installed

    return installed
end

-- get package info
function get_package_info(packagedir)
    local packagename = path.filename(packagedir)
    local packagefile = path.join(packagedir, "xmake.lua")
    local manifestfile = path.join(packagedir, "manifest.json")
    local packageinstance = package.load_from_repository(packagename, packagedir, {packagefile = packagefile})
    local on_load = packageinstance:get("load")
    if on_load then
        on_load(packageinstance)
    end
    local pkg = {}
    local urls = packageinstance:get("urls") or os.raise("%s urls is empty", packagename)
    local versions = packageinstance:get("versions") or {latest = "nil", sha = "unknown"}
    local description = packageinstance:get("description") or "unknown"
    local homepage = packageinstance:get("homepage") or "unknown"
    local license = packageinstance:get("license") or "unknown"

    if type(urls) == "table" then
        pkg["Urls"] = urls
    else
        pkg["Urls"] = {urls}
    end

    pkg["Description"] = description
    pkg["Homepage"] = homepage
    pkg["License"] = license

    if os.isfile(manifestfile) then
        manifest = json.loadfile(manifestfile)
        pkg["Company"] = manifest["Company"]
        pkg["Versions"] = manifest["Versions"]
    else
        pkg["Company"] = "unknown"
        pkg["Versions"] = {}
    end

    for version, version_info in pairs(pkg["Versions"]) do
        version_info["Sha"] = versions[version] or "unknown"
        if is_installed(packagename, version) then
            version_info["Installed"] = true
            if version_info["Sha"] == "unknown" then
                local git_tool = find_tool("git")
                if not git_tool then
                    os.raise("error: git not find")
                end
                local sha, _ = os.iorunv(git_tool.program, {"rev-parse", "HEAD"})
                local date, _ = os.iorunv(git_tool.program, {"log", "-1", "--date=format:%Y%m%d%H%M%S", "--format=%ad"})
                version_info["Sha"] = string.format("%s@%s", sha:trim(), date:trim())
            end
        else
            version_info["Installed"] = false
        end
    end

    -- add to kind
    if packageinstance:get("kind") then
        return packageinstance:get("kind"), packagename, pkg
    else
        return "library", packagename, pkg
    end
end

function dump_table()
    local packagelist = {toolchain = {}, library = {}}
    local repositories_dir = option.get("repositories")
    local installed_list = nil
    local dump_type = option.get("dump")

    if dump_type == "json" or dump_type == "table" then
        -- load package xmake
        for _, packagedir in ipairs(os.dirs(path.join(rootdir, "packages", "*", "*"))) do
            local package_type, package_name, package_info = get_package_info(packagedir)
            packagelist[package_type][package_name] = package_info
        end
        if dump_type == "json" then
            print(json.encode(packagelist))
        else
            print(packagelist)
        end
    else
        local dump_package = ""
        local list = dump_type:split("#")
        assert(#list == 2, "invalid input \"%s\"", dump_type)
        local dump_package = list[1]
        dump_type = list[2]
        local packagedir = path.join(rootdir, "packages", dump_package:sub(1, 1), dump_package)
        local package_type, package_name, package_info = get_package_info(packagedir)
        packagelist[package_type][package_name] = package_info

        if dump_type == "json" then
            print(json.encode(packagelist))
        else
            print(packagelist)
        end
    end

    return packagelist
end

function install(packagename, version)
    local repositories_dir = option.get("repositories")
    local urls = get_download_url(packagename, version)
    local outputdir = path.join(repositories_dir, packagename, version)

    -- get fast url
    local download_urls = table.orderkeys(urls)
    fasturl.add(download_urls)
    download_urls = fasturl.sort(download_urls)
    local url = download_urls[1]

    -- check installed
    local installed = is_installed(packagename, version)

    -- install
    if not installed then
        -- frist rm output dir
        os.tryrm(outputdir)

        if git.asgiturl(url) then
            -- git clone
            print("git clone from %s", url)
            git.clone(url, {recursive = true, longpaths = true, outputdir = outputdir})
        else
            local pkg_file = path.join(repositories_dir, packagename, (path.filename(url):gsub("%?.+$", "")))
            -- frist rm package file
            os.tryrm(pkg_file)
            print("download from %s", url)

            -- http download
            http.download(url, pkg_file)
            local sourcehash = urls[url]
            local sha256 = hash.sha256(pkg_file)
            if sha256 == sourcehash then
                local tmp = path.join(repositories_dir, ".tmp")
                print("extract file %s to %s", pkg_file, tmp)
                archive.extract(pkg_file, tmp)
                local filedirs = os.filedirs(path.join(tmp, "*"))
                if #filedirs == 1 and os.isdir(filedirs[1]) then
                    os.mv(filedirs[1], outputdir)
                    os.rm(tmp)
                else
                    os.mv(tmp, outputdir)
                end
            else
                os.raise("unmatched checksum, current hash(%s) != original hash(%s)", sha256:sub(1, 8), sourcehash:sub(1, 8))
            end
        end

        -- mkdir .csplink
        if os.isdir(outputdir) and not os.isdir(path.join(outputdir, ".csplink")) then
            os.mkdir(path.join(outputdir, ".csplink"))
        end

        -- check installed
        if os.isdir(path.join(outputdir, ".csplink")) then
            installed = true
        end
        if installed then
            packages_json[packagename][version].installed = true
            print("%s@%s install successful", packagename, version)
        else
            os.raise("%s@%s install failed", packagename, version)
        end
    else
        print("%s@%s already installed", packagename, version)
    end

    -- update packages.json
    json.savefile(packages_json_file, packages_json)
end

function update()
    local packagename = option.get("update")
    local repositories_dir = option.get("repositories")
    local installed = is_installed(packagename, "latest")
    local git_tool = find_tool("git")
    if not git_tool then
        os.raise("error: git not find")
    end

    local url, _ = os.iorunv(git_tool.program, {"remote", "get-url", "origin"})

    -- update
    if installed then
        local outputdir = path.join(repositories_dir, packagename, "latest")
        print("update form %s", url:trim())
        git.pull({repodir = outputdir})
        print("%s@%s update successful", packagename, "latest")
    else
        os.raise("%s@%s not yet installed", packagename, "latest")
    end
end

function uninstall(packagename, version)
    local repositories_dir = option.get("repositories")

    -- check installed
    local installed = is_installed(packagename, version)

    --  uninstalled
    if installed then
        os.rm(path.join(repositories_dir, packagename, version))

        -- check installed
        if not os.isdir(path.join(outputdir, ".csplink")) then
            installed = false
        end
        if not installed then
            packages_json[packagename][version].installed = false
            print("%s@%s uninstall successful", packagename, version)
        else
            os.raise("%s@%s uninstall failed", packagename, version)
        end
    else
        os.raise("%s@%s not yet installed", packagename, version)
    end

    -- update packages.json
    json.savefile(packages_json_file, packages_json)
end

function main()
    config.load()
    project.load_targets()

    assert(option.get("repositories"), "must set repositories dir")

    if option.get("dump") then
        load_packages_json()
        dump_table()
    elseif option.get("install") then
        local value = option.get("install")
        local list = value:split("@")
        assert(#list == 2, "invalid input \"%s\", eq. xmake csp-repo --install=csp_hal_apm32f1@latest -r {dir}", value)
        local packagename = list[1]
        local version = list[2]
        load_packages_json()
        install(packagename, version)
    elseif option.get("update") then
        load_packages_json()
        update()
    elseif option.get("uninstall") then
        local value = option.get("uninstall")
        local list = value:split("@")
        assert(#list == 2, "invalid input \"%s\", eq. xmake csp-repo --uninstall=csp_hal_apm32f1@latest -r {dir}", value)
        local packagename = list[1]
        local version = list[2]
        load_packages_json()
        uninstall(packagename, version)
    end
end
