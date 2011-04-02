--According to Brendon it downloads this from
--http://blendogames.com/atomzombiesmasher/mods/Example_Mod.txt,
--but more likely it's just cloned from the data.

--All of these file paths assume Windows.

--Assumptions made in this default:
--  Steam was installed to the default directory
--  The Lua interpreter is the same architecture as the Steam installer (x86)
local programfiles = os.getenv "ProgramFiles"

local steamcommon = steamcommon or programfiles..[[\Steam\steamapps\common]]

--Assumptions made in this default:
--  Atom Zombie Smasher is coming from Steam
local azsdata = azsdata or steamcommon..[[\atomzombiesmasher\data]]
local azscontent = azsdata .. [[\content]]
--azscontentdata is the section with the manifest in it
local azscontentdata = azscontent .. [[\data]]
local azsmanifest = azscontentdata .. [[\manifest.txt]]

local appdata = os.getenv "APPDATA"
local modspath = appdata..[[\AtomZombieData\mods\]]

local manifestio={}

local function modmanifest(modname)
  modname = modname or "example_mod"
  local modpath = modspath..modname
  local modmanifest = modpath..[[\manifest.txt]]
  return modmanifest
end

local function parse(file, hooks)
  local function callhook(name,...)
    if hooks[name] then return hooks[name](...) end
  end

  local src
    --If the file parameter is a string, then treat it as a filename.
  if type(file) == "string" then
    src = assert(io.open(file,'r'))
  --Otherwise, treat it as a handle.
  else
    src = file
  end


  --using a while instead of lines()
  --because the loop reads in extra lines
  --when it hits DESCRIPTION
  local line = src:read"*l"
  local lineno = 0
  while line do
    lineno = lineno +1
    --if this line starts with a comment
    if string.match(line,"^//") then
      callhook("comment",line)
    --if this line is all whitespace or blank
    elseif string.match(line,"^%s*$") then
      callhook("whitespace",line)
    else
      --do a normal keyword parse
      local var, space, value, trail =
        string.match(line, "^([%u%d_]+)(%s*)(.-)(%s*)$")

      --special case for description
      if var=="DESCRIPTION" then
        --save the current position so we can come back
        --in the event there isn't a single curly brace in the whole file
        local safety = src:seek()
        local safelineno = lineno
        --An error message if description parses wrong.
        local eoferr = nil

        --the buffer for text between the description and the
        --opening brace (should really just be a newline)
        local leadspace={}
        --the buffer for the text in the description
        local dlines={}

        --don't parse the part of this line with DESCRIPTION
        line = space..value..trail

        local function seek(brace, buft, errmsg)
          local pattern = string.gsub(
            "^([^S]*)(S?)(.*)$", 'S', brace)

          --while the description has not begun
          --and there's still file left
          while line do
            --eat everything until you find an open curly brace
            local pre, brace, post =
              string.match(line,pattern)

            --add everything before the brace to the collection
            --of lead whitespace (check it later)
            buft[#buft+1]=pre

            if brace=="" then
              line = src:read'*l'
            else
              line = post
              return
            end
          end

          --if reaching this point having run out of lines
          --and no function ran out of lines before,
          --set the error to post
          if not eoferr then
            eoferr=errmsg
          end
        end

        seek('{',leadspace,
          "No opening brace for description found before end of file")
        seek('}',dlines,
          "No closing brace for description found before end of file")

        --if we couldn't find something
        if eoferr then
          --return the error
          callhook("error",eoferr)
          --reset the file to where it was before
          --we span off into nothingness
          src:seek("set",safety)
          lineno=safelineno

        --if we found everything with no errors
        else
          local leadspace = table.concat(leadspace,'\n')
          --whitespace is stripped inside the braces as well
          local predspace, desc, postdspace = string.match(
            table.concat(dlines,'\n'),"^(%s*)(.-)(%s*)$")
          local trail = line

          callhook("description", desc,
            leadspace, predspace, postdspace, trail)

        end
      --if there was a regular match
      elseif var then
        callhook("var",var,value,space,trail)
      else
        callhook("error",string.format(
          "Invalid line at %i: %s",lineno,line))
      end

    end --keyword parsing "else" case

    --Line parsed.
    --Advance one line.
    line = src:read'*l'
  end --line loop
end

function manifestio.read(file)
  local vars={}
  local errors={}
  local hooks={}

  function hooks.var(k, v)
    local vnum = tonumber(v)
    vars[k] = vnum or v
  end
  function hooks.description(v)
    vars.DESCRIPTION = v
  end
  function hooks.error(msg)
    errors[#errors+1]=msg
  end

  parse(file or azsmanifest,hooks)
  return vars, errors
end

function manifestio.write(vars,file,base)
  local out
  --If the output parameter is a string, then treat it as a filename.
  if type(file) == "string" then
    out = io.open(file,'w')
  --Otherwise, treat it as a handle.
  else
    out = file
  end

  local function copy(line)
    --Just print line verbatim.
    out:write(line,"\n")
  end

  local hooks={comment=copy,whitespace=copy}

  function hooks.var(k, v)
    --Approaches to whitespace:
    --1. Preserve the whitespace of the original file
    --   (add a third "space" parameter to this hook to get it).
    --2. Make all defined variables line up by making them
    --   line up to the end of the longest key (go through the table,
    --   find the longest key, make the space string.rep(
    --     ' ',math.max(#longest-#k,0)+1)
    --3. Just put a single space. The one I'm going with.
    local space = ' '
    --If this var wasn't defined (whoops!), default it to what was read
    local val = vars[k] or v

    --If this var is a number and the source had a dot in it,
    --output it in floating-point format to match what was
    --theoretically a floating-point number
    if type(val) and string.find(v,'%.') then
      val = string.format("%.1f", val)
    end
    --otherwise, just let Lua handle the format

    out:write(k,space,val,'\n')
  end

  function hooks.description(desc)
    --This function completely ignores the original
    --formatting of the description because
    --it would just be gratuitous.
    out:write("DESCRIPTION\n{\n",desc,"\n}\n")
  end

  function hooks.error()
    --Print blank lines in place of poorly formed lines in the base
    --(of which there should be none).
    out:write('\n')
  end

  parse(base or azsmanifest,hooks)
end

return manifestio
