import("core.project.project")
import("core.project.config")
import("core.base.semver")
import("core.base.hashset")
import("lib.detect.find_tool")
import("core.base.json")
import("lib.detect.find_file")

-- 导出宏定义、头文件路径、库文件、启动文件

-- get configs from target
function _get_configs_from_target(target, name)
    local values = {}
    if name:find("flags", 1, true) then
        table.join2(values, target:toolconfig(name))
    end
    for _, value in ipairs((target:get_from(name, "*"))) do
        table.join2(values, value)
    end
    if not name:find("flags", 1, true) then -- for includedirs, links ..
        table.join2(values, target:toolconfig(name))
    end
    return table.unique(values)
end

-- tranlate path
function _translate_path(filepath, outputdir)
    filepath = path.translate(filepath)
    if filepath == "" then
        return ""
    end
    if path.is_absolute(filepath) then
        if filepath:startswith(project.directory()) then
            return path.relative(filepath, outputdir)
        end
        return filepath
    else
        return path.relative(path.absolute(filepath), outputdir)
    end
end

-- escape path
function _escape_path(filepath)
    if is_host("windows") then
        filepath = filepath:gsub('\\', '/')
    end
    return filepath
end

-- this sourcebatch is built?
function _sourcebatch_is_built(sourcebatch)
    -- we can only use rulename to filter them because sourcekind may be bound to multiple rules
    local rulename = sourcebatch.rulename
    if rulename == "c.build" or rulename == "c++.build" or rulename == "asm.build" then
        return true
    end
end

-- generate target<object> sources
function _generate_target_object_sources(target, outputdir)
    local deps = {}
    local object_sources = {}
    local local_target = target
    local local_deps = target:get("deps")

    if local_deps == nil then
        return
    end

    if type(local_deps) ~= "table" then
        local_deps = {local_deps}
    end

    while (#local_deps > 0) do
        local dep = local_deps[1]
        local_target = local_target:dep(dep)
        if local_target:kind() == "object" then
            table.insert(deps, local_target)
        end
        table.remove(local_deps, 1)
        local _deps = local_target:get("deps")
        if _deps and type(_deps) ~= "table" then
            _deps = {_deps}
        end
        if _deps then
            local_deps = table.join(local_deps, _deps)
        end
    end

    for _, dep_target in ipairs(deps) do
        for _, sourcebatch in table.orderpairs(dep_target:sourcebatches()) do
            if _sourcebatch_is_built(sourcebatch) then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    table.insert(object_sources, _get_relative_unix_path(sourcefile, outputdir))
                end
            end
        end
        for _, headerfile in ipairs(dep_target:headerfiles()) do
            table.insert(object_sources, _get_relative_unix_path(headerfile, outputdir))
        end
    end

    return object_sources
end

-- get relative unix path
function _get_relative_unix_path(filepath, outputdir)
    filepath = _translate_path(filepath, outputdir)
    filepath = _escape_path(path.translate(filepath))
    return os.args(filepath)
end

local _export_project = function(outputdir)
    local config_json = {}
    for _, target in table.orderpairs(project.targets()) do
        local targetkind = target:kind()
        if targetkind == "object" then
            goto continue
        end
        local defines = target:get("defines")
        config_json["Defines"] = defines

        config_json["CoreSrc"] = {}
        for _, sourcebatch in table.orderpairs(target:sourcebatches()) do
            if _sourcebatch_is_built(sourcebatch) then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    table.insert(config_json["CoreSrc"], _get_relative_unix_path(sourcefile, outputdir))
                end
            end
        end

        config_json["LibSrc"] = {}
        config_json["LibSrc"] = _generate_target_object_sources(target, outputdir)

        config_json["IncludePath"] = {}
        local includedirs = _get_configs_from_target(target, "includedirs")
        if #includedirs > 0 then
            local access_type = target:kind() == "headeronly" and "INTERFACE" or "PRIVATE"
            for _, includedir in ipairs(includedirs) do
                table.insert(config_json["IncludePath"], _get_relative_unix_path(includedir, outputdir))
            end
            
        end
        local includedirs_interface = target:get("includedirs", { interface = true })
        if includedirs_interface then
            for _, headerdir in ipairs(includedirs_interface) do
                table.insert(config_json["IncludePath"], _get_relative_unix_path(headerdir, outputdir))
            end
        end

        ::continue::
    end
    local config_json_str = json.encode(config_json)
    return config_json_str
end

function main(outputdir)
    local oldir = os.cd(os.projectdir())
    local json_str = _export_project(outputdir)
    local json_file = io.open(path.join(outputdir, "temp.json"), "w")
    json_file:write(json_str)
    json_file:close()

    local XMAKE_RCFILES = path.directory(os.getenv("XMAKE_RCFILES"))
    XMAKE_RCFILES = path.join(XMAKE_RCFILES, "tasks/csp-project/mdk")

    local csp2mdk_command;
    if is_host("windows") then
        csp2mdk_command = find_file("csp2mdk.exe", XMAKE_RCFILES)
    else
        csp2mdk_command = find_file("csp2mdk", XMAKE_RCFILES)
    end

    local target_name = function ()
        for _, target in table.orderpairs(project.targets()) do
            local targetkind = target:kind()
            if targetkind == "binary" then
                return target:name()
            end
        end
    end
    local target_name = target_name()

    os.runv(csp2mdk_command, {"--csp", target_name .. ".csp", "--output", outputdir  })

    os.rm(path.join(outputdir, "temp.json"))
    os.cd(oldir)
end
