local iconv = require('iconv')

local function show(c)
    print(string.format('%q', c))
    local cs = {}
    for i = 1, #c do
        local b = c:byte(i)
        table.insert(cs, string.format("%02x(%d)", b, b))
    end
    print(#c .. ": " .. table.concat(cs, ', '))
end

local function check(text, charset, expected)
    local res = iconv.Transform(text, charset)
    if res ~= expected then
        show(res)
        error('not match: ' .. charset)
    end
end

check('あぃ', 'gbk', '\xa4\xa2\xa4\xa3')
check('あぃ', 'big5', '\xc6\xa6\xc6\xa7')
check('あぃ', 'shift_jis', '\x82\xa0\x82\xa1')
print('All Check Passed')
