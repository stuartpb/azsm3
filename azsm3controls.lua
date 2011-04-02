local iup = require "iuplua"
local cd = require "cdlua"
require "iupluacd"

local azsm3c = {}
local meta={__index=azsm3c}

function azsm3c.new(vars)
  return setmetatable({vars=vars},meta)
end

function azsm3c:text(var)
  local vars=self.vars
  return iup.text{
    expand="horizontal",
    value=vars[var], tip=var,
    action=function(self) vars[var]=self.value end
  }
end

function azsm3c:description(var)
  local vars=self.vars
  return iup.text{
    expand="yes",
    multiline="yes",
    value=vars[var], tip=var,
    action=function(self) vars[var]=self.value end
  }
end

function azsm3c:spin(var, max, min)
  local vars=self.vars
  local function update(self) vars[var]=tonumber(self.value) end

  return iup.text{
    spin="yes", spinmax=max, spinmin=min,
    tip=var, value=vars[var], --spinvalue=vars[var],
    action=update, spin_cb=update
  }
end

function azsm3c:minmax(format, low, high)
  local function spin(limit)
    return self:spin(string.format(format,limit), low, high)
  end

  local min = spin"MIN"
  local max = spin"MAX"

  return iup.hbox{
    iup.label{title="Min:"},
    min,
    iup.label{title="Max:"},
    max
  }
end

function azsm3c:multilevel(format, levels, low, high)
  local function spin(level)
    return self:spin(string.format(format,level), low, high)
  end

  local args={}
  for i=1, levels do
    args[#args+1]=iup.label{title=string.format("%i:",i)}
    args[#args+1]=spin(i)
  end
  return iup.hbox(args)
end

function azsm3c:color(format)
  local vars=self.vars
  local function varchan(channel)
    return string.format(format,channel)
  end

  local c={
    R=vars[varchan'R'] or 0,
    G=vars[varchan'G'] or 0,
    B=vars[varchan'B'] or 0,
  }

  local function colorstring()
    return string.format("%i %i %i", c.R, c.G, c.B)
  end

  local preview=iup.canvas{
    bgcolor=colorstring(), rastersize="20x20", expand="no"}

  local spins={}

  local function getcolor()
    local function update(channel,value)
      c[channel] = value
      vars[varchan(channel)] = value
      spins[channel].value = value
    end
    local r,g,b = iup.GetColor(iup.CURRENT,iup.CURRENT,c.R,c.G,c.B)
    if r and g and b then
      update('R',r)
      update('G',g)
      update('B',b)
      preview.bgcolor = colorstring()
    end
  end

  function preview:button_cb(but,pressed)
    if but==iup.BUTTON1 and pressed==0 then
      getcolor()
    end
  end

  local function makespin(channel)
    local var = varchan(channel)
    local function update(self)
      local value = self.value
      c[channel] = value
      vars[var] = value
      preview.bgcolor = colorstring()
    end

    spins[channel]=iup.text{
      spin="yes", spinmax=255, spinmin=0,
      tip=var, value=c[channel], --spinvalue=c[channel],
      action=update, spin_cb=update
    }
  end

  makespin'R'
  makespin'G'
  makespin'B'

  return iup.hbox{
    iup.label{title="R:"},
    spins.R,
    iup.label{title="G:"},
    spins.G,
    iup.label{title="B:"},
    spins.B,
    preview
  }
end

return azsm3c
