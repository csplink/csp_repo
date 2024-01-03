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
-- @file        cmakelists.lua
--
-- Change Logs:
-- Date           Author       Notes
-- ------------   ----------   -----------------------------------------------
-- 2023-12-17     xqyjlj       initial version
--
--
import("core.project.project")
import("core.project.config")
import("core.base.semver")
import("core.base.hashset")
import("lib.detect.find_tool")

-- get minimal cmake version
function _get_cmake_minver()
    local cmake_minver = _g.cmake_minver
    if not cmake_minver then
        local cmake = find_tool("cmake", {version = true})
        if cmake and cmake.version then
            cmake_minver = semver.new(cmake.version)
        end
        if not cmake_minver or cmake_minver:gt("3.15.0") then
            cmake_minver = semver.new("3.15.0")
        end
        _g.cmake_minver = cmake_minver
    end
    return cmake_minver
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

-- escape path in flag
-- @see https://github.com/xmake-io/xmake/issues/3161
function _escape_path_in_flag(target, flag)
    if is_host("windows") and target:has_tool("cc", "cl") then
        -- e.g. /ManifestInput:xx, /def:xxx
        if flag:find(":", 1, true) then
            flag = _escape_path(flag)
        end
    end
    return flag
end

-- get enabled languages from targets
function _get_project_languages(targets)
    local languages = {}
    for _, target in table.orderpairs(targets) do
        for _, sourcekind in ipairs(target:sourcekinds()) do
            if sourcekind == "cc" then
                table.insert(languages, "C")
            elseif sourcekind == "cxx" then
                table.insert(languages, "CXX")
            elseif sourcekind == "as" then
                table.insert(languages, "ASM")
            end
        end
    end
    languages = table.unique(languages)
    return languages
end

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

-- get relative unix path
function _get_relative_unix_path(filepath, outputdir)
    filepath = _translate_path(filepath, outputdir)
    filepath = _escape_path(path.translate(filepath))
    return os.args(filepath)
end

-- get relative unix path to the cmake path
-- @see https://github.com/xmake-io/xmake/issues/2026
function _get_relative_unix_path_to_cmake(filepath, outputdir)
    filepath = _translate_path(filepath, outputdir)
    filepath = path.translate(filepath):gsub('\\', '/')
    if filepath and not path.is_absolute(filepath) then
        filepath = "${CMAKE_SOURCE_DIR}/" .. filepath
    end
    return os.args(filepath)
end

-- this sourcebatch is built?
function _sourcebatch_is_built(sourcebatch)
    -- we can only use rulename to filter them because sourcekind may be bound to multiple rules
    local rulename = sourcebatch.rulename
    if rulename == "c.build" or rulename == "c++.build" or rulename == "asm.build" then
        return true
    end
end

-- translate flag
function _translate_flag(flag, outputdir)
    if flag then
        if path.instance_of(flag) then
            flag = flag:clone():set(_get_relative_unix_path_to_cmake(flag:rawstr(), outputdir)):str()
        elseif path.is_absolute(flag) then
            flag = _get_relative_unix_path_to_cmake(flag, outputdir)
        elseif flag:startswith("-T") then
            flag = string.sub(flag, 3)
            flag = _get_relative_unix_path_to_cmake(flag, outputdir)
            flag = "-T" .. flag
        elseif flag:match("(.+)=(.+)") then
            local k, v = flag:match("(.+)=(.+)")
            if k and v then
                local need_convert = false
                if v:endswith(".map") then -- e.g. -Wl,-Map=xxx.map
                    need_convert = true
                end
                if need_convert then
                    flag = k .. "=" .. _get_relative_unix_path_to_cmake(v, outputdir)
                end
            end
        end
    end
    return flag
end

-- translate flags
function _translate_flags(flags, outputdir)
    if not flags then
        return
    end
    local result = {}
    for _, flag in ipairs(flags) do
        if type(flag) == "table" and not path.instance_of(flag) then
            for _, v in ipairs(flag) do
                table.insert(result, _translate_flag(v, outputdir))
            end
        else
            table.insert(result, _translate_flag(flag, outputdir))
        end
    end
    return result
end

-- get flags from target
-- @see https://github.com/xmake-io/xmake/issues/3594
function _get_flags_from_target(target, flagkind)
    local flags = _get_configs_from_target(target, flagkind)
    local extraconf = target:extraconf(flagkind)
    local sourcekind
    if flagkind == "cflags" then
        sourcekind = "cc"
    elseif flagkind == "cxxflags" or flagkind == "cxflags" then
        sourcekind = "cxx"
    elseif flagkind == "asflags" then
        sourcekind = "as"
    else
        raise("unknown flag kind %s", flagkind)
    end
    local toolinst = target:compiler(sourcekind)

    -- does this flag belong to this tool?
    -- @see https://github.com/xmake-io/xmake/issues/3022
    --
    -- e.g.
    -- for all: add_cxxflags("-g")
    -- only for clang: add_cxxflags("clang::-stdlib=libc++")
    -- only for clang and multiple flags: add_cxxflags("-stdlib=libc++", "-DFOO", {tools = "clang"})
    --
    local result = {}
    for _, flag in ipairs(flags) do
        local for_this_tool = true
        local flagconf = extraconf and extraconf[flag]
        if type(flag) == "string" and flag:find("::", 1, true) then
            for_this_tool = false
            local splitinfo = flag:split("::", {plain = true})
            local toolname = splitinfo[1]
            if toolname == toolinst:name() then
                flag = splitinfo[2]
                for_this_tool = true
            end
        elseif flagconf and flagconf.tools then
            for_this_tool = table.contains(table.wrap(flagconf.tools), toolinst:name())
        end
        if for_this_tool then
            table.insert(result, flag)
        end
    end
    return result
end

-- generate project info
function _generate_project(cmakelists, languages)
    local cmake_version = _get_cmake_minver()
    cmakelists:print([[# this is the build file for project %s
# it is autogenerated by the xmake build system.
# do not edit by hand.
]], project.name() or "")

    cmakelists:print("cmake_minimum_required(VERSION %s)", cmake_version)
    cmakelists:print("")
    for _, target in table.orderpairs(project.targets()) do
        _generate_toolchains(cmakelists, target)
        break
    end

    cmakelists:print("set(CMAKE_SYSTEM_NAME Generic)")
    cmakelists:print("set(CMAKE_SYSTEM_PROCESSOR %s)", config.get("arch"))

    cmakelists:print("")

    -- cmakelists:print("set(CMAKE_VERBOSE_MAKEFILE ON)")
    cmakelists:print("set(CMAKE_EXPORT_COMPILE_COMMANDS ON)")

    cmakelists:print("")

    cmakelists:print("# project")
    local project_name = project.name()
    if not project_name then
        for _, target in table.orderpairs(project.targets()) do
            project_name = target:name()
            break
        end
    end

    if project_name then
        local project_info = ""
        local project_version = project.version()
        if project_version then
            project_info = project_info .. " VERSION " .. project_version
        end
        if languages then
            cmakelists:print("project(%s%s LANGUAGES %s)", project_name, project_info, table.concat(languages, " "))
        else
            cmakelists:print("project(%s%s)", project_name, project_info)
        end
    end
end

-- generate toolchains
function _generate_toolchains(cmakelists, target)
    if config.get("toolchain") or target:get("toolchains") then
        cmakelists:print("# toolchains")
        local cc = target:tool("cc")
        if cc then
            cc = cc:gsub("\\", "/")
            cmakelists:print("set(CMAKE_C_COMPILER \"%s\")", cc)
            cmakelists:print("set(CMAKE_C_COMPILER_WORKS TRUE)")
        end
        local as, as_name = target:tool("as")
        if as then
            as = cc:gsub("\\", "/")
            cmakelists:print("set(CMAKE_ASM_COMPILER \"%s\")", as)
            cmakelists:print("set(CMAKE_ASM_COMPILER_WORKS TRUE)")
        end
        local cxx, cxx_name = target:tool("cxx")
        if cxx then
            if cxx_name == "clang" or cxx_name == "gcc" then
                local dir = path.directory(cxx)
                local name = path.filename(cxx)
                name = name:gsub("clang$", "clang++")
                name = name:gsub("clang%-", "clang++-")
                name = name:gsub("gcc$", "g++")
                name = name:gsub("gcc%-", "g++-")
                if dir ~= '.' then
                    cxx = path.join(dir, name)
                else
                    cxx = name
                end
            end
            cxx = cxx:gsub("\\", "/")
            cmakelists:print("set(CMAKE_CXX_COMPILER \"%s\")", cxx)
            cmakelists:print("set(CMAKE_CXX_COMPILER_WORKS TRUE)")
        end
        local toolchains = target:get("toolchains")
        if string.find(toolchains, "armcc") or string.find(toolchains, "armclang") then
            local fromelf, _ = target:tool("fromelf")
            if fromelf then
                fromelf = fromelf:gsub("\\", "/")
                cmakelists:print("set(CMAKE_FROMELF \"%s\")", fromelf)
            end
        else
            local objcopy, _ = target:tool("objcopy")
            if objcopy then
                objcopy = objcopy:gsub("\\", "/")
                cmakelists:print("set(CMAKE_OBJCOPY \"%s\")", objcopy)
            end
            local size, _ = target:tool("size")
            if size then
                size = size:gsub("\\", "/")
                cmakelists:print("set(CMAKE_SIZE \"%s\")", size)
            end
        end
        cmakelists:print("")
    end
end

-- generate target: phony
function _generate_target_phony(cmakelists, target)
    cmakelists:print("# target phony")
    cmakelists:printf("add_custom_target(%s", target:name())
    local deps = target:get("deps")
    if deps then
        cmakelists:write(" DEPENDS")
        for _, dep in ipairs(deps) do
            cmakelists:write(" " .. dep)
        end
    end
    cmakelists:print(")")
    cmakelists:print("")
end

-- generate rule bin<hex>
function _generate_rule_bin(cmakelists, target, outputdir)
    cmakelists:print("add_custom_command(TARGET %s POST_BUILD", target:name())
    local toolchains = target:get("toolchains")
    if string.find(toolchains, "armcc") or string.find(toolchains, "armclang") then
        cmakelists:print("    COMMAND ${CMAKE_FROMELF} --bin %s/%s --output %s/%s.bin", targetdir, target:filename(),
                         targetdir, target:name())
        cmakelists:print("    COMMAND ${CMAKE_FROMELF} --i32 %s/%s --output %s/%s.hex", targetdir, target:filename(),
                         targetdir, target:name())
    else
        local targetdir = _get_relative_unix_path_to_cmake(target:targetdir(), outputdir)
        cmakelists:print("    COMMAND ${CMAKE_OBJCOPY} -O binary %s/%s %s/%s.bin", targetdir, target:filename(),
                         targetdir, target:name())
        cmakelists:print("    COMMAND ${CMAKE_OBJCOPY} -O ihex %s/%s %s/%s.hex", targetdir, target:filename(),
                         targetdir, target:name())
        cmakelists:print("    COMMAND ${CMAKE_SIZE} --format=berkeley %s/%s", targetdir, target:filename())
    end
    cmakelists:print(")")
end

-- generate rule<only csp command>
function _generate_rule(cmakelists, target, outputdir)
    local rules = target:get("rules")
    if rules and table.contains(rules, "csp.bin") then
        -- generate rule bin<hex>
        _generate_rule_bin(cmakelists, target, outputdir)
    end
end

-- generate target: binary
function _generate_target_binary(cmakelists, target, outputdir)
    cmakelists:print("# target binary <%s>", target:name())
    cmakelists:print("add_executable(%s \"\")", target:name())
    cmakelists:print("set_target_properties(%s PROPERTIES OUTPUT_NAME \"%s\")", target:name(), target:filename())
    cmakelists:print("set_target_properties(%s PROPERTIES RUNTIME_OUTPUT_DIRECTORY \"%s\")", target:name(),
                     _get_relative_unix_path_to_cmake(target:targetdir(), outputdir))
    _generate_rule(cmakelists, target, outputdir)
end

-- generate target: static
function _generate_target_static(cmakelists, target, outputdir)
    cmakelists:print("# target static <%s>", target:name())
    cmakelists:print("add_library(%s STATIC \"\")", target:name())
    cmakelists:print("set_target_properties(%s PROPERTIES OUTPUT_NAME \"%s\")", target:name(), target:basename())
    cmakelists:print("set_target_properties(%s PROPERTIES ARCHIVE_OUTPUT_DIRECTORY \"%s\")", target:name(),
                     _get_relative_unix_path_to_cmake(target:targetdir(), outputdir))
end

-- generate target dependencies
function _generate_target_dependencies(cmakelists, target)
    local _deps = target:get("deps")
    local deps = {}
    if _deps then
        for _, dep in ipairs(_deps) do
            if target:dep(dep):kind() ~= "object" then
                table.insert(deps, dep)
            end
        end
    end

    if #deps > 0 then
        cmakelists:printf("add_dependencies(%s", target:name())
        for _, dep in ipairs(deps) do
            cmakelists:write(" " .. dep)
        end
        cmakelists:print(")")
    end
end

-- generate target include directories
function _generate_target_include_directories(cmakelists, target, outputdir)
    local includedirs = _get_configs_from_target(target, "includedirs")
    if #includedirs > 0 then
        local access_type = target:kind() == "headeronly" and "INTERFACE" or "PRIVATE"
        cmakelists:print("target_include_directories(%s %s", target:name(), access_type)
        for _, includedir in ipairs(includedirs) do
            cmakelists:print("    " .. _get_relative_unix_path(includedir, outputdir))
        end
        cmakelists:print(")")
    end
    local includedirs_interface = target:get("includedirs", {interface = true})
    if includedirs_interface then
        cmakelists:print("target_include_directories(%s INTERFACE", target:name())
        for _, headerdir in ipairs(includedirs_interface) do
            cmakelists:print("    " .. _get_relative_unix_path(headerdir, outputdir))
        end
        cmakelists:print(")")
    end
end

-- generate target compile definitions
function _generate_target_compile_definitions(cmakelists, target)
    local defines = _get_configs_from_target(target, "defines")
    if #defines > 0 then
        cmakelists:print("target_compile_definitions(%s PRIVATE", target:name())
        for _, define in ipairs(defines) do
            cmakelists:print("    " .. define)
        end
        cmakelists:print(")")
    end
end

-- generate target source files flags
function _generate_target_sourcefiles_flags(cmakelists, target, sourcefile, name, outputdir)
    local fileconfig = target:fileconfig(sourcefile)
    if fileconfig then
        local flags = _get_flags_from_fileconfig(fileconfig, outputdir, name)
        if flags and #flags > 0 then
            cmakelists:print(
                "set_source_files_properties(" .. _get_relative_unix_path_to_cmake(sourcefile, outputdir) ..
                    " PROPERTIES COMPILE_OPTIONS")
            local flagstrs = {}
            for _, flag in ipairs(flags) do
                if name == "cxxflags" then
                    table.insert(flagstrs, "$<$<COMPILE_LANGUAGE:CXX>:" .. flag .. ">")
                elseif name == "cflags" then
                    table.insert(flagstrs, "$<$<COMPILE_LANGUAGE:C>:" .. flag .. ">")
                elseif name == "cxflags" then
                    table.insert(flagstrs, "$<$<COMPILE_LANGUAGE:C>:" .. flag .. ">")
                    table.insert(flagstrs, "$<$<COMPILE_LANGUAGE:CXX>:" .. flag .. ">")
                end
            end
            cmakelists:print("    \"%s\"", table.concat(flagstrs, ";"))
            cmakelists:print(")")
        end
    end
end

-- generate target compile options
function _generate_target_compile_options(cmakelists, target, outputdir)
    local cflags = _get_flags_from_target(target, "cflags")
    local cxflags = _get_flags_from_target(target, "cxflags")
    local cxxflags = _get_flags_from_target(target, "cxxflags")
    if #cflags > 0 or #cxflags > 0 or #cxxflags > 0 then
        cmakelists:print("target_compile_options(%s PRIVATE", target:name())
        for _, flag in ipairs(_translate_flags(cflags, outputdir)) do
            flag = _escape_path_in_flag(target, flag)
            cmakelists:print("    $<$<COMPILE_LANGUAGE:C>:" .. flag .. ">")
        end
        for _, flag in ipairs(_translate_flags(cxflags, outputdir)) do
            flag = _escape_path_in_flag(target, flag)
            cmakelists:print("    $<$<COMPILE_LANGUAGE:C>:" .. flag .. ">")
            cmakelists:print("    $<$<COMPILE_LANGUAGE:CXX>:" .. flag .. ">")
        end
        for _, flag in ipairs(_translate_flags(cxxflags, outputdir)) do
            flag = _escape_path_in_flag(target, flag)
            cmakelists:print("    $<$<COMPILE_LANGUAGE:CXX>:" .. flag .. ">")
        end
        cmakelists:print(")")
    end

    -- generate cflags/cxxflags for the specific source files
    for _, sourcebatch in table.orderpairs(target:sourcebatches()) do
        if _sourcebatch_is_built(sourcebatch) then
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                _generate_target_sourcefiles_flags(cmakelists, target, sourcefile, "cxxflags", outputdir)
                _generate_target_sourcefiles_flags(cmakelists, target, sourcefile, "cflags", outputdir)
                _generate_target_sourcefiles_flags(cmakelists, target, sourcefile, "cxflags", outputdir)
            end
        end
    end
end

-- generate target warnings
function _generate_target_warnings(cmakelists, target)
    local flags_gcc = {
        none = "-w",
        less = "-Wall",
        more = "-Wall",
        all = "-Wall",
        allextra = "-Wall -Wextra",
        error = "-Werror"
    }
    local warnings = target:get("warnings")
    if warnings then
        for _, warn in ipairs(warnings) do
            cmakelists:print("target_compile_options(%s PRIVATE %s)", target:name(), flags_gcc[warn])
        end
    end
end

-- generate target exceptions
function _generate_target_exceptions(cmakelists, target)
    local flags_gcc = {cxx = "-fcxx-exceptions", ["no-cxx"] = "-fno-cxx-exceptions"}
    local exceptions = target:get("exceptions")
    if exceptions then
        for _, exception in ipairs(exceptions) do
            cmakelists:print("target_compile_options(%s PRIVATE %s)", target:name(), flags_gcc[exception])
        end
    end
end

-- generate target languages
function _generate_target_languages(cmakelists, target)
    local features = {
        c89 = "C_STANDARD 89",
        c99 = "C_STANDARD 99",
        c11 = "C_STANDARD 11",
        cxx98 = "CXX_STANDARD 98",
        cxx11 = "CXX_STANDARD 11",
        cxx14 = "CXX_STANDARD 14",
        cxx17 = "CXX_STANDARD 17",
        cxx20 = "CXX_STANDARD 20",
        cxx23 = "CXX_STANDARD 23"
    }
    local languages = target:get("languages")
    if languages then
        for _, lang in ipairs(languages) do
            local has_ext = false
            if lang:startswith("gnu") then
                lang = lang:sub(4)
                has_ext = true
            end
            local feature = features[lang] or (features[lang:replace("++", "xx")])
            if feature then
                cmakelists:print("set_target_properties(%s PROPERTIES", target:name())
                cmakelists:print("    %s", feature)
                cmakelists:print("    CXX_EXTENSIONS %s", has_ext and "ON" or "OFF")
                cmakelists:print(")")
            end
        end
    end
end

-- generate target optimization
function _generate_target_optimization(cmakelists, target)
    local flags_gcc = {
        none = "-O0",
        fast = "-O1",
        faster = "-O2",
        fastest = "-O3",
        smallest = "-Os",
        aggressive = "-Ofast"
    }
    local optimization = target:get("optimize")
    if optimization then
        cmakelists:print("target_compile_options(%s PRIVATE %s)", target:name(), flags_gcc[optimization])
    end
end

-- generate target symbols
function _generate_target_symbols(cmakelists, target)
    local symbols = target:get("symbols")
    if symbols then
        local flags_gcc = {}
        local levels = hashset.from(table.wrap(symbols))
        if levels:has("debug") then
            table.insert(flags_gcc, "-g")
        end
        if levels:has("hidden") then
            table.insert(flags_gcc, "-fvisibility=hidden")
        end
        if #flags_gcc > 0 then
            cmakelists:print("target_compile_options(%s PRIVATE %s)", target:name(), table.concat(flags_gcc, " "))
        end
    end
end

-- generate target link libraries
function _generate_target_link_libraries(cmakelists, target, outputdir)
    -- add links
    local links = _get_configs_from_target(target, "links")
    if #links > 0 then
        cmakelists:print("target_link_libraries(%s PRIVATE", target:name())
        for _, link in ipairs(links) do
            cmakelists:print("    " .. link)
        end
        cmakelists:print(")")
    end
end

-- generate target link directories
function _generate_target_link_directories(cmakelists, target, outputdir)
    local linkdirs = _get_configs_from_target(target, "linkdirs")
    if #linkdirs > 0 then
        local cmake_minver = _get_cmake_minver()
        if cmake_minver:ge("3.13.0") then
            cmakelists:print("target_link_directories(%s PRIVATE", target:name())
            for _, linkdir in ipairs(linkdirs) do
                cmakelists:print("    " .. _get_relative_unix_path(linkdir, outputdir))
            end
            cmakelists:print(")")
        else
            cmakelists:print("target_link_libraries(%s PRIVATE", target:name())
            for _, linkdir in ipairs(linkdirs) do
                cmakelists:print("    -L" .. _get_relative_unix_path(linkdir, outputdir))
            end
            cmakelists:print(")")
        end
    end
end

-- generate target link options
function _generate_target_link_options(cmakelists, target, outputdir)
    local ldflags = _get_configs_from_target(target, "ldflags")
    local shflags = _get_configs_from_target(target, "shflags")
    if #ldflags > 0 or #shflags > 0 then
        local flags = {}
        for _, flag in ipairs(table.unique(table.join(ldflags, shflags))) do
            table.insert(flags, _translate_flag(flag, outputdir))
        end
        if #flags > 0 then
            local cmake_minver = _get_cmake_minver()
            if cmake_minver:ge("3.13.0") then
                cmakelists:print("target_link_options(%s PRIVATE", target:name())
            else
                cmakelists:print("target_link_libraries(%s PRIVATE", target:name())
            end
            for _, flag in ipairs(flags) do
                flag = _escape_path_in_flag(target, flag)
                cmakelists:print("    " .. flag)
            end
            cmakelists:print(")")
        end
    end
end

-- generate target sources
function _generate_target_sources(cmakelists, target, outputdir)
    cmakelists:print("target_sources(%s PRIVATE", target:name())
    for _, sourcebatch in table.orderpairs(target:sourcebatches()) do
        if _sourcebatch_is_built(sourcebatch) then
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                cmakelists:print("    " .. _get_relative_unix_path(sourcefile, outputdir))
            end
        end
    end
    for _, headerfile in ipairs(target:headerfiles()) do
        cmakelists:print("    " .. _get_relative_unix_path(headerfile, outputdir))
    end
    cmakelists:print(")")
end

-- generate target<object> sources
function _generate_target_object_sources(cmakelists, target, outputdir)
    local deps = {}
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
        cmakelists:print("target_sources(%s PRIVATE # target<%s>", target:name(), dep_target:name())
        for _, sourcebatch in table.orderpairs(dep_target:sourcebatches()) do
            if _sourcebatch_is_built(sourcebatch) then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    cmakelists:print("    " .. _get_relative_unix_path(sourcefile, outputdir))
                end
            end
        end
        for _, headerfile in ipairs(dep_target:headerfiles()) do
            cmakelists:print("    " .. _get_relative_unix_path(headerfile, outputdir))
        end
        cmakelists:print(")")
    end
end

-- generate target source groups
-- @see https://github.com/xmake-io/xmake/issues/1149
function _generate_target_source_groups(cmakelists, target, outputdir)
    local filegroups = target:get("filegroups")
    for _, filegroup in ipairs(filegroups) do
        local files = target:extraconf("filegroups", filegroup, "files") or "**"
        local mode = target:extraconf("filegroups", filegroup, "mode")
        local rootdir = target:extraconf("filegroups", filegroup, "rootdir")
        assert(rootdir, "please set root directory, e.g. add_filegroups(%s, {rootdir = 'xxx'})", filegroup)
        local sources = {}
        local recurse_sources = {}
        if path.is_absolute(rootdir) then
            rootdir = _get_relative_unix_path(rootdir, outputdir)
        else
            rootdir = string.format("${CMAKE_CURRENT_SOURCE_DIR}/%s", _get_relative_unix_path(rootdir, outputdir))
        end
        for _, filepattern in ipairs(files) do
            if filepattern:find("**", 1, true) then
                filepattern = filepattern:gsub("%*%*", "*")
                table.insert(recurse_sources, _get_relative_unix_path(path.join(rootdir, filepattern), outputdir))
            else
                table.insert(sources, _get_relative_unix_path(path.join(rootdir, filepattern), outputdir))
            end
        end
        if #sources > 0 then
            cmakelists:print("FILE(GLOB %s_GROUP_SOURCE_LIST %s)", target:name(), table.concat(sources, " "))
            if mode and mode == "plain" then
                cmakelists:print("source_group(%s FILES ${%s_GROUP_SOURCE_LIST})",
                                 _get_relative_unix_path(filegroup, outputdir), target:name())
            else
                cmakelists:print("source_group(TREE %s PREFIX %s FILES ${%s_GROUP_SOURCE_LIST})", rootdir,
                                 _get_relative_unix_path(filegroup, outputdir), target:name())
            end
        end
        if #recurse_sources > 0 then
            cmakelists:print("FILE(GLOB_RECURSE %s_GROUP_RECURSE_SOURCE_LIST %s)", target:name(),
                             table.concat(recurse_sources, " "))
            if mode and mode == "plain" then
                cmakelists:print("source_group(%s FILES ${%s_GROUP_RECURSE_SOURCE_LIST})",
                                 _get_relative_unix_path(filegroup, outputdir), target:name())
            else
                cmakelists:print("source_group(TREE %s PREFIX %s FILES ${%s_GROUP_RECURSE_SOURCE_LIST})", rootdir,
                                 _get_relative_unix_path(filegroup, outputdir), target:name())
            end
        end
    end
end

-- generate target
function _generate_target(cmakelists, target, outputdir)
    local targetkind = target:kind()
    if targetkind == "object" then
        return
    end

    cmakelists:print("")
    cmakelists:print("################################################################################################")
    cmakelists:print("")

    if target:is_phony() then
        return _generate_target_phony(cmakelists, target)
    elseif targetkind == "binary" then
        _generate_target_binary(cmakelists, target, outputdir)
    elseif targetkind == "static" then
        _generate_target_static(cmakelists, target, outputdir)
        -- elseif targetkind == "shared" then
        --     _generate_target_shared(cmakelists, target, outputdir)
        -- elseif targetkind == 'headeronly' then
        --     _generate_target_headeronly(cmakelists, target)
        --     _generate_target_include_directories(cmakelists, target, outputdir)
        --     return

    else
        raise("unknown target kind %s", target:kind())
    end

    -- generate target dependencies
    _generate_target_dependencies(cmakelists, target)

    -- generate target include directories
    _generate_target_include_directories(cmakelists, target, outputdir)

    -- ageneratedd target compile definitions
    _generate_target_compile_definitions(cmakelists, target)

    -- generate target compile options
    _generate_target_compile_options(cmakelists, target, outputdir)

    -- generate target warnings
    _generate_target_warnings(cmakelists, target)

    -- generate target exceptions
    _generate_target_exceptions(cmakelists, target)

    -- generate target languages
    _generate_target_languages(cmakelists, target)

    -- generate target optimization
    _generate_target_optimization(cmakelists, target)

    -- generate target symbols
    _generate_target_symbols(cmakelists, target)

    -- generate target link libraries
    _generate_target_link_libraries(cmakelists, target, outputdir)

    -- generate target link directories
    _generate_target_link_directories(cmakelists, target, outputdir)

    -- generate target link options
    _generate_target_link_options(cmakelists, target, outputdir)

    -- generate target sources
    _generate_target_sources(cmakelists, target, outputdir)

    -- generate target<object> sources
    _generate_target_object_sources(cmakelists, target, outputdir)

    -- generate target source groups
    _generate_target_source_groups(cmakelists, target, outputdir)

    -- end
end

-- generate cmakelists
function _generate_cmakelists(cmakelists, outputdir)

    -- generate project info
    _generate_project(cmakelists, _get_project_languages(project.targets()))

    -- generate targets
    for _, target in table.orderpairs(project.targets()) do
        _generate_target(cmakelists, target, outputdir)
    end
end

function main(outputdir)
    -- enter project directory
    local oldir = os.cd(os.projectdir())

    -- open the cmakelists
    local cmakelists = io.open(path.join(outputdir, "CMakeLists.txt"), "w")

    -- generate cmakelists
    _generate_cmakelists(cmakelists, outputdir)

    -- close the cmakelists
    cmakelists:close()
    os.cd(oldir)
end
