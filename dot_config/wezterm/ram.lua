local wezterm = require('wezterm')

local last_update_time = 0
local last_result = ''

local is_windows = string.find(wezterm.target_triple, 'windows') ~= nil
local is_linux = string.find(wezterm.target_triple, 'linux') ~= nil
local is_darwin = string.find(wezterm.target_triple, 'darwin') ~= nil
local is_freebsd = string.find(wezterm.target_triple, 'freebsd') ~= nil

return {
  default_opts = {
    throttle = 3,
    icon = wezterm.nerdfonts.cod_server,
    use_pwsh = false,
  },
  update = function(_, opts)
    opts = opts or {}
    local throttle = opts.throttle or 3
    local current_time = os.time()

    if current_time - last_update_time < throttle then
      return last_result
    end

    local ram_str = ""

    if is_linux then
      -- 直接读取 /proc/meminfo，无子进程开销，高性能 (0ms 延迟)
      local f = io.open("/proc/meminfo", "r")
      if f then
        local content = f:read("*a")
        f:close()
        local total_kb = content:match("MemTotal:%s+(%d+)")
        local avail_kb = content:match("MemAvailable:%s+(%d+)")
        if total_kb and avail_kb then
          local used_gb = (tonumber(total_kb) - tonumber(avail_kb)) / 1024 / 1024
          ram_str = string.format("%.2f GB", used_gb)
        end
      end
    elseif is_windows then
      local success, result = wezterm.run_child_process({
        'powershell.exe',
        '-NoProfile',
        '-Command',
        '(Get-CimInstance Win32_OperatingSystem | ForEach-Object { ($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / 1mb })',
      })
      if success and result then
        local num = tonumber(result:match('[%d%.]+'))
        if num then
          ram_str = string.format("%.2f GB", num)
        end
      end
    elseif is_darwin then
      local success, result = wezterm.run_child_process({ 'vm_stat' })
      if success and result then
        local page_size = tonumber(result:match('page size of (%d+) bytes'))
        local anonymous_pages = tonumber(result:match('Anonymous pages:%s+(%d+)'))
        local pages_purgeable = tonumber(result:match('Pages purgeable:%s+(%d+)'))
        local wired_memory = tonumber(result:match('Pages wired down:%s+(%d+)'))
        local compressed_memory = tonumber(result:match('Pages occupied by compressor:%s+(%d+)'))

        if page_size and anonymous_pages and pages_purgeable and wired_memory and compressed_memory then
          local app_memory = anonymous_pages - pages_purgeable
          local used_memory = (app_memory + wired_memory + compressed_memory) * page_size / (1024 * 1024 * 1024)
          ram_str = string.format('%.2f GB', used_memory)
        end
      end
    elseif is_freebsd then
      local success, result = wezterm.run_child_process({
        'sysctl',
        '-n',
        'hw.pagesize',
        'vm.stats.vm.v_free_count',
        'vm.stats.vm.v_inactive_count',
        'vm.stats.vm.v_active_count',
        'vm.stats.vm.v_wire_count',
        'vm.stats.vm.v_laundry_count',
      })
      if success and result then
        local pg_sz, mem_free, mem_inact, mem_act, mem_wired, mem_laundry =
          result:match('(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)')
        if pg_sz and mem_wired and mem_act and mem_laundry then
          local used = tonumber(mem_wired) + tonumber(mem_act) + tonumber(mem_laundry)
          used = tonumber(pg_sz) * used / (1024 * 1024 * 1024)
          ram_str = string.format('%.2f GB', used)
        end
      end
    end

    if ram_str ~= "" then
      last_update_time = current_time
      last_result = ram_str
    end

    return last_result
  end,
}
