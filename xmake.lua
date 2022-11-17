set_xmakever("2.7.2")

for _, dir in ipairs(os.dirs(os.scriptdir() .. "/*")) do
    file = dir .. "/xmake.lua"
    if os.exists(file) then includes(file) end
end
