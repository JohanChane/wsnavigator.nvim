Log = {}
Log.__index = Log


function Log:new(_opts)
  local self = setmetatable({}, Log)

  _opts = _opts or {}

  function self:log(title, msg, opts)
    if not _opts.enable then
      return
    end

    opts = opts or {}

    if opts.print_msg_only then
      print(msg)
      return
    end

    local info = debug.getinfo(2, 'Sln')
    local source = info and info.source or 'unknown source'
    local currentline = info and info.currentline or 'unknown line'
    local name = info and info.name or 'unknown function'

    local filename = source:match('^.+/(.+)$') or source
    local timestamp = os.date('%M:%S')

    print(string.format('## %s [%s:%s:%s] %s', timestamp, filename, currentline, name, title))
    if msg then
      print('### msg')
      print(msg)
    end
    if opts.inspect then
      print('### inspect')
      opts.inspect()
    end
  end

  return self
end

return {
  Log = Log
}
