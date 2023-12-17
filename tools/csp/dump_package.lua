import("lib.detect.find_tool")
import("core.package.package")
import("core.base.json")

local packagelist = {toolchain = {}, library = {}}

function init_packagelist()
    for _, packagedir in ipairs(os.dirs(path.absolute(
                                            path.join(os.scriptdir(), "..", "..", "repo", "packages", "*", "*")))) do
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
end

function usage()

end



function dump_json()
    local jsonstr = json.encode(packagelist)
    print(jsonstr)
end

function main(...)
    local args = {...}

    if table.contains(args, "--help") or table.contains(args, "-h") then
        usage()
    elseif table.contains(args, "--json") then
        init_packagelist()
        dump_json()
    elseif table.contains(args, "--dump") then
        init_packagelist()
        print(packagelist)
    else
        usage()
    end
end
