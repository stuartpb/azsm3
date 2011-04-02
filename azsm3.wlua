local iup = require "iuplua"
local manifestio = require "manifestio"
local azsm3controls = require "azsm3controls"

--The Atom Zombie Smasher manifest variables.
local vars = manifestio.read()

--Create a new control context with these variables.
local ctrl = azsm3controls.new(vars)

local function tabpairs(t)
  local targs={}
  for i=1, #t do
    targs[i]=t[i][2]
    targs[string.format("TABTITLE%i", i-1)] = t[i][1]
  end
  return iup.tabs(targs)
end

local dlg = iup.dialog{
  title="Atom Zombie Smasher, MMM!",
  rastersize="400x600";
  tabpairs{
    {"General",
      iup.vbox{
        iup.label{title="Mod name:"},
        ctrl:text"MODNAME",
        iup.label{title="Author:"},
        ctrl:text"AUTHOR",
        iup.label{title="Description:"},
        ctrl:description"DESCRIPTION"
      }
    },
    {"City/World Generation",
      iup.vbox{
        iup.label{title="City width:"},
        ctrl:minmax("GAME_CITY%sWIDTH"),
        iup.label{title="City height:"},
        ctrl:minmax("GAME_CITY%sHEIGHT"),
        iup.label{title="Building size:"},
        ctrl:minmax("%sBUILDINGSIZE"),
        iup.label{title="Building height:"},
        ctrl:minmax("%sBUILDINGHEIGHT"),
        iup.label{title="Building health:"},
        ctrl:minmax("GAME_BLD_%sHEALTH"),
        iup.label{title="City population at outbreak level:"},
        ctrl:multilevel("CITYPOP_LVL%i",3),
        iup.label{title="Scientist population at outbreak level:"},
        ctrl:multilevel("SCIPOP_LVL%i",3),
        iup.hbox{
          iup.label{title="Maximum number of territories:"},
          ctrl:spin("GEO_MAXCITIES"),
        },
        iup.label{title="Worldmap dimensions:"},
        iup.hbox{
          iup.label{title="Width:"},
          ctrl:spin("GEO_WIDTH"),
          iup.label{title="Height:"},
          ctrl:spin("GEO_HEIGHT"),
        },
        iup.hbox{
          iup.label{title="Minimum buffer between cities:"},
          ctrl:spin("GEO_CITYBUFFER"),
        },
        iup.hbox{
          iup.label{title="Minimum buffer between world edge and cities:"},
          ctrl:spin("GEO_BORDERBUFFER"),
        },
        iup.hbox{
          iup.label{title="Clamp the city size scalers to this max population:"},
          --TODO: Toggle to lock in sync with CITYPOP_LVL3
          ctrl:spin("GAME_CITYPOPULATIONCLAMP"),
        },
        iup.label{title="Dotted border color:"},
        ctrl:color"GEOBORDERCOLOR_%s",
        iup.label{title="Human-owned territory color:"},
        ctrl:color"GEOHUMANCOLOR_%s",
        iup.label{title="Unclaimed territory color:"},
        ctrl:color"GEOUNCLAIMEDCOLOR_%s",
        iup.label{title="Zeppelin color:"},
        ctrl:color"GEOZEPPELINCOLOR_%s",
      }--vbox
    },--City/World Generation
    {"People Stats",
      iup.vbox{
        iup.label{title="Human wander move speed:"},
        ctrl:speed("HUMANSPEED",0,10),
        iup.label{title="Human evacuation run speed:"},
        ctrl:speed("HUMANEVACUATIONSPEED",0,10),
        iup.label{title="Human run-away-from-zombies panic speed:"},
        ctrl:speed("HUMANPANICSPEED",0,10),
        iup.label{title="Zombie base speed:"},
        ctrl:speed("ZOMBIESPEED",0,10),
        iup.label{title="Casual zombie speed modifier:"},
        ctrl:speed("ZOMBIESPEED_CASUAL_MODIFIER",0,10),
        iup.label{title="Hardcore zombie speed modifier:"},
        ctrl:speed("ZOMBIESPEED_HARDCORE_MODIFIER",-10,0),
        iup.label{title="Human color:"},
        ctrl:color"HUMANCOLOR_%s",
        iup.label{title="Zed color:"},
        ctrl:color"ZOMBIECOLOR_%s",
        iup.label{title="Super Zed color:"},
        ctrl:color"SUPERZOMBIECOLOR_%s",
        iup.label{title="Human blood decal color:"},
        ctrl:color"HUMANBLOODCOLOR_%s",
        iup.label{title="Human animated bloodspurt color:"},
        ctrl:color"HUMANBLOODSPURTCOLOR_%s",
        iup.label{title="Zombie blood decal color:"},
        ctrl:color"ZOMBIEBLOODCOLOR_%s",
        iup.label{title="Zombie animated bloodspurt color:"},
        ctrl:color"ZOMBIEBLOODSPURTCOLOR_%s",

      }
    },
  }
}

dlg:show()

iup.MainLoop()
