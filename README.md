# luaiconv
basic charset conversion in pure lua

usage (refer to [check.lua](check.lua)):
```lua
local iconv = require('iconv')

local result = iconv.Transform('あぃ', 'gbk')
-- '\xa4\xa2\xa4\xa3'
```
