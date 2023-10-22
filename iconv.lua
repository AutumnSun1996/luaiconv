local iconv = {}

local tgtChar = '\0'
local tgtCharCode = tgtChar:byte(1)
--- decompress
---@param data string
---@return string
local function decompress(data)
    local decompressed = {}
    local i, size = 1, #data
    while i <= size do
        local byte = data:byte(i)
        if byte == tgtCharCode then
            local count = data:byte(i + 1) + 1
            table.insert(decompressed, string.rep(tgtChar, count))
            -- decompressed[#decompressed + 1] = string.rep(tgtChar, count)
            i = i + 2
        else
            table.insert(decompressed, string.char(byte))
            -- decompressed[#decompressed + 1] = string.char(byte)
            i = i + 1
        end
    end
    return table.concat(decompressed)
end

local dataMap = {}
--- load charset data
---@param name string
---@return string data
---@return string errmsg
local function loadData(name)
    local d = dataMap[name]
    if d == nil then
        local f, errmsg = io.open("data/" .. name .. ".bin", "rb")
        if f == nil then
            error(errmsg)
        else
            local data = decompress(f:read('a'))
            f:close()
            d = {
                data = data
            }
            dataMap[name] = d
            -- print('loaded', #data)
        end
    end
    return d.data, d.errmsg
end

---return bytes for given unicode
---@param unicode number
---@param codecData string
---@return string
local function encodeChar(unicode, codecData)
    -- 0x01 ~ 0x7f, map to 1 byte
    if unicode <= 0x7f then
        return string.char(unicode)
    end
    -- others, map to 2 bytes
    local offset = (unicode - 0x80) * 2 + 1
    -- print(string.format('unicode: %04x -> %04x', unicode, offset))
    local val = codecData:sub(offset, offset + 1)
    if val == '\0\0' or val == '' then
        -- not in target range, return +UXXXX
        val = string.format('+U%04X', unicode)
    end
    return val
end

--- Load UTF8 string to unicode array
---@param text string
---@return table
function iconv.Load(text)
    local result = {}
    local i, size = 1, #text
    while i <= size do
        local c1 = string.byte(text, i)
        local charcode
        if c1 < 128 then
            charcode = c1
            i = i + 1
        elseif c1 < 224 then
            local c2 = string.byte(text, i + 1)
            charcode = (c1 - 192) * 64 + (c2 - 128)
            i = i + 2
        elseif c1 < 240 then
            local c2 = string.byte(text, i + 1)
            local c3 = string.byte(text, i + 2)
            charcode = ((c1 - 224) * 4096 + (c2 - 128) * 64 + (c3 - 128))
            i = i + 3
        else
            local c2 = string.byte(text, i + 1)
            local c3 = string.byte(text, i + 2)
            local c4 = string.byte(text, i + 3)
            charcode = ((c1 - 240) * 262144 + (c2 - 128) * 4096 + (c3 - 128) * 64 + (c4 - 128))
            i = i + 4
        end
        table.insert(result, charcode)
    end
    return result
end

--- Load UTF8 string to unicode array
---@param unicodes table
---@param charset? string
---@return table
function iconv.Encode(unicodes, charset)
    local datamap = loadData(charset or 'gbk')
    local result = {}
    for _, charcode in ipairs(unicodes) do
        table.insert(result, encodeChar(charcode, datamap))
    end
    return table.concat(result)
end

---Convert given utf-8 string to GBK string
---@param text string
---@param charset? string
---@return string
function iconv.Transform(text, charset)
    return iconv.Encode(iconv.Load(text), charset)
end

return iconv
