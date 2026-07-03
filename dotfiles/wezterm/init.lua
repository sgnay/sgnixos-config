local wezterm = require 'wezterm'

-- 简单合并函数
local function simple_merge(...)
  local result = {}
  for i = 1, select('#', ...) do
    local t = select(i, ...)
    if t then
      for k, v in pairs(t) do
        result[k] = v
      end
    end
  end
  return result
end

-- 加载模块
local modules = {
  'appearance',
  'window', 
  'behavior',
  'keymaps',
}

local final_config = {}

for _, module_name in ipairs(modules) do
  local ok, module_config = pcall(require, module_name)
  if ok then
    -- 特殊处理keys数组
    if module_config.keys then
      final_config.keys = final_config.keys or {}
      for _, keymap in ipairs(module_config.keys) do
        table.insert(final_config.keys, keymap)
      end
    end
    
    -- 合并其他配置
    for k, v in pairs(module_config) do
      if k ~= 'keys' then
        final_config[k] = v
      end
    end
  else
    wezterm.log_warn('Module ' .. module_name .. ' not found')
  end
end

return final_config
