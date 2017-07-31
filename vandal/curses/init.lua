--[[
    Copyright (c) 2017 Alexandru-Mihai Maftei. All rights reserved.


    Developed by: Alexandru-Mihai Maftei
    aka Vercas
    http://vercas.com | https://github.com/vercas/Vandal

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to
    deal with the Software without restriction, including without limitation the
    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
    sell copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

      * Redistributions of source code must retain the above copyright notice,
        this list of conditions and the following disclaimers.
      * Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimers in the
        documentation and/or other materials provided with the distribution.
      * Neither the names of Alexandru-Mihai Maftei, Vercas, nor the names of
        its contributors may be used to endorse or promote products derived from
        this Software without specific prior written permission.


    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    WITH THE SOFTWARE.

    ---

    You may also find the text of this license in "LICENSE.md".
]]

if not vandal.curses then vandal.curses = { } else error "wut?" end
local curses = vandal.curses

local c = require "vandal/ffi/curses"
local tk = require "vandal/ffi/termkey"
local window = require "vandal/curses/window_class"
local inev = require "vandal/input_event_class"
local types = require "vandal/utils/types"
local ffi = require "ffi"
require "vandal/ffi/misc"

curses.window = window

function curses.initialize(ui)
    if ui.initialized then
        error "Vandal error: curses interface is already initialized."
    end

    ui.initialized = true

    c.setlocale(c.LC_CTYPE, "")

    curses.tk = tk.termkey_new(ffi.C.fileno(ffi.C.stdin), 0)

    if curses.tk == nil or curses.tk == 0 then
        error "Vandal error: Failed to initialize termkey."
    end

    curses.tkk = ffi.new "TermKeyKey[1]"

    ui.main_window = window(c.initscr(), false)
    --c.raw()
    c.cbreak()
    c.nonl()
    c.noecho()
    ui.main_window:c_keypad(true)
    ui.main_window:c_meta(true)

    if c.has_colors() then
        c.start_color()
        c.use_default_colors()

        curses.pair_count = c.COLOR_PAIRS
        curses.color_count = c.COLORS
    else
        curses.color_count = 0
    end

    ui.has_colors = curses.color_count > 1
end

function curses.finalize(ui)
    c.endwin()
    tk.termkey_destroy(curses.tk)
    c.freeconsole()
end

--[[
function curses.read_char(timeout)
    local tType = types.assert({ "nil", "number", "boolean" }, timeout, "timeout")

    if tType == "number" then
        if not types.is_integer(timeout) then
            error "Vandal error: `timeout` value given to `read_char` must be an integer."
        end

        c.timeout(timeout)
    elseif tType == "boolean" then
        c.timeout(timeout and 0 or -1)
    end

    local res = c.getch()

    if res == c.KEY_RESIZE and curses.main_window then
        curses.main_window:redraw()
    end

    if res == -1 then
        return false
    elseif res == c.KEY_RESIZE then
        return inev(IET_RESIZE)
    else
        local key, cp = ui.KEY_to_codepoint(res)

        if not key then
            --  No key means more keys are required to build a codepoint.

            return false
        end

        return inev(IET_KB, key, cp)
    end
end

curses.get_key = c.get_key

function curses.get_key_name(val)
    return ffi.string(c.keyname(val))
end

function ui.KEY_to_codepoint(key)
    if key >= 32 and key < 127 then
        return key, string.char(key)
    elseif key == 10 or key == c.KEY_ENTER then
        return key, "\n"
    elseif key == 9 then
        return key, "\t"
    end

    return key
end

for k, v in c.pairs() do
    if type(k) == "string" and k == k:upper() and (tonumber(v) or type(v) == "function") then
        --print(k, v)

        curses[k] = v
    end
end--]]

function curses.poll(ui, timeout)
    local tType = types.assert({ "nil", "number", "boolean" }, timeout, "timeout")

    if tType == "number" then
        if timeout < 0 then
            error "Vandal error: `timeout` value given to `poll` must be positive."
        end
    else
        timeout = (timeout ~= false) and -1 or 0
    end

    if timeout >= 0 then
        local res = tk.termkey_advisereadable(curses.tk)
        ERR("adv1\t", tostring(res))

        if res == tk.TERMKEY_RES_NONE then
            if timeout > 0 then
                ffi.C.usleep(math.floor(timeout * 1000))
            end

            res = tk.termkey_advisereadable(curses.tk)
            ERR("adv2\t", tostring(res))
        end

        if res == tk.TERMKEY_RES_ERROR then
            return false, ffi.errno()
        end

        local stop = 5

        while res == tk.TERMKEY_RES_AGAIN and stop > 0 do
            res = tk.termkey_getkey(curses.tk, curses.tkk)
            ERR("get\t", tostring(res))

            if res == tk.TERMKEY_RES_AGAIN then
                --  Incomplete sequence? Read moar from the input stream.

                res = tk.termkey_advisereadable(curses.tk)
                ERR("adv3\t", tostring(res))

                stop = stop - 1
            else
                break
            end

            --  This will continue and 
        end

        if res ~= tk.TERMKEY_RES_KEY then
            return false, (res == tk.TERMKEY_RES_ERROR) and ffi.errno() or nil
        end
    else
        repeat
            local res = tk.termkey_waitkey(curses.tk, curses.tkk)
            ERR("wait\t", tostring(res))

            if res == tk.TERMKEY_RES_EOF or res == tk.TERMKEY_RES_ERROR then
                return false
            end

            --  Otherwise, it's "partial" and the function's just called again.
        until res == tk.TERMKEY_RES_KEY
    end

    return curses.tkk_to_event(ui, curses.tkk[0])
end

function curses.tkk_to_event(ui, tkk)
    ERR(tkk.type, "\t", tkk.modifiers, "\t", ffi.string(tkk.utf8))

    --if      tkk.type == tk.TERMKEY_TYPE_UNICODE    then ERR("\tcodepoint\t", tonumber(tkk.code.codepoint))
    --elseif  tkk.type == tk.TERMKEY_TYPE_KEYSYM     then ERR("\tsymbol\t", tkk.code.sym)
    --end

    if not curses.tkk_buf then curses.tkk_buf = ffi.new "char[64]" end

    local sz = tk.termkey_strfkey(curses.tk, curses.tkk_buf, 64, tkk, tk.TERMKEY_FORMAT_MOUSE_POS)
    local fkey = ffi.string(curses.tkk_buf, sz)

    ERR("\t", fkey)

    if tkk.type == tk.TERMKEY_TYPE_KEYSYM then
        if tkk.code.sym == tk.TERMKEY_SYM_REFRESH then
            if ui.main_window then
                ui.main_window:redraw()
            end

            return inev(IET_RESIZE)
        else
            --ERR("\tconv\t", curses.tkk_syms[tonumber(tkk.code.sym)], "\t", ui.KEY_names[curses.tkk_syms[tonumber(tkk.code.sym)] or ui.KEY_UNKNOWN])

            return inev(IET_KB, curses.tkk_syms[tonumber(tkk.code.sym)] or ui.KEY_UNKNOWN)
        end
    elseif tkk.type == tk.TERMKEY_TYPE_UNICODE then
        return inev(IET_KB, ui.KEY_CODEPOINT, tkk.code.codepoint, ffi.string(tkk.utf8))
    end

    return false
end

curses.tkk_syms = {
    [tk.TERMKEY_SYM_UNKNOWN] = ui.KEY_UNKNOWN,
    [tk.TERMKEY_SYM_NONE] = ui.KEY_NONE,

    [tk.TERMKEY_SYM_BACKSPACE] = ui.KEY_BACKSPACE,
    [tk.TERMKEY_SYM_TAB] = ui.KEY_TAB,
    [tk.TERMKEY_SYM_ENTER] = ui.KEY_ENTER,
    [tk.TERMKEY_SYM_ESCAPE] = ui.KEY_ESCAPE,

    [tk.TERMKEY_SYM_SPACE] = ui.KEY_SPACE,
    [tk.TERMKEY_SYM_DEL] = ui.KEY_DELETE,

    [tk.TERMKEY_SYM_UP] = ui.KEY_UP,
    [tk.TERMKEY_SYM_DOWN] = ui.KEY_DOWN,
    [tk.TERMKEY_SYM_LEFT] = ui.KEY_LEFT,
    [tk.TERMKEY_SYM_RIGHT] = ui.KEY_RIGHT,
    --[tk.TERMKEY_SYM_BEGIN] = ui.KEY_BEGIN,
    --[tk.TERMKEY_SYM_FIND] = ui.KEY_FIND,
    [tk.TERMKEY_SYM_INSERT] = ui.KEY_INSERT,
    [tk.TERMKEY_SYM_DELETE] = ui.KEY_DELETE,
    --[tk.TERMKEY_SYM_SELECT] = ui.KEY_SELECT,
    [tk.TERMKEY_SYM_PAGEUP] = ui.KEY_PAGEUP,
    [tk.TERMKEY_SYM_PAGEDOWN] = ui.KEY_PAGEDOWN,
    [tk.TERMKEY_SYM_HOME] = ui.KEY_HOME,
    [tk.TERMKEY_SYM_END] = ui.KEY_END,

    --[[
    [tk.TERMKEY_SYM_CANCEL] = ui.KEY_CANCEL,
    [tk.TERMKEY_SYM_CLEAR] = ui.KEY_CLEAR,
    [tk.TERMKEY_SYM_CLOSE] = ui.KEY_CLOSE,
    [tk.TERMKEY_SYM_COMMAND] = ui.KEY_COMMAND,
    [tk.TERMKEY_SYM_COPY] = ui.KEY_COPY,
    [tk.TERMKEY_SYM_EXIT] = ui.KEY_EXIT,
    [tk.TERMKEY_SYM_HELP] = ui.KEY_HELP,
    [tk.TERMKEY_SYM_MARK] = ui.KEY_MARK,
    [tk.TERMKEY_SYM_MESSAGE] = ui.KEY_MESSAGE,
    [tk.TERMKEY_SYM_MOVE] = ui.KEY_MOVE,
    [tk.TERMKEY_SYM_OPEN] = ui.KEY_OPEN,
    [tk.TERMKEY_SYM_OPTIONS] = ui.KEY_OPTIONS,
    [tk.TERMKEY_SYM_PRINT] = ui.KEY_PRINT,
    [tk.TERMKEY_SYM_REDO] = ui.KEY_REDO,
    [tk.TERMKEY_SYM_REFERENCE] = ui.KEY_REFERENCE,
    [tk.TERMKEY_SYM_REFRESH] = ui.KEY_REFRESH,
    [tk.TERMKEY_SYM_REPLACE] = ui.KEY_REPLACE,
    [tk.TERMKEY_SYM_RESTART] = ui.KEY_RESTART,
    [tk.TERMKEY_SYM_RESUME] = ui.KEY_RESUME,
    [tk.TERMKEY_SYM_SAVE] = ui.KEY_SAVE,
    [tk.TERMKEY_SYM_SUSPEND] = ui.KEY_SUSPEND,
    [tk.TERMKEY_SYM_UNDO] = ui.KEY_UNDO,--]]

    [tk.TERMKEY_SYM_KP0] = ui.KEY_NUM0,
    [tk.TERMKEY_SYM_KP1] = ui.KEY_NUM1,
    [tk.TERMKEY_SYM_KP2] = ui.KEY_NUM2,
    [tk.TERMKEY_SYM_KP3] = ui.KEY_NUM3,
    [tk.TERMKEY_SYM_KP4] = ui.KEY_NUM4,
    [tk.TERMKEY_SYM_KP5] = ui.KEY_NUM5,
    [tk.TERMKEY_SYM_KP6] = ui.KEY_NUM6,
    [tk.TERMKEY_SYM_KP7] = ui.KEY_NUM7,
    [tk.TERMKEY_SYM_KP8] = ui.KEY_NUM8,
    [tk.TERMKEY_SYM_KP9] = ui.KEY_NUM9,
    [tk.TERMKEY_SYM_KPENTER] = ui.KEY_NUM_ENTER,
    [tk.TERMKEY_SYM_KPPLUS] = ui.KEY_NUM_PLUS,
    [tk.TERMKEY_SYM_KPMINUS] = ui.KEY_NUM_MINUS,
    [tk.TERMKEY_SYM_KPMULT] = ui.KEY_NUM_MULTIPLY,
    [tk.TERMKEY_SYM_KPDIV] = ui.KEY_NUM_DIVIDE,
    [tk.TERMKEY_SYM_KPCOMMA] = ui.KEY_NUM_COMMA,
    [tk.TERMKEY_SYM_KPPERIOD] = ui.KEY_NUM_PERIOD,
    [tk.TERMKEY_SYM_KPEQUALS] = ui.KEY_NUM_EQUALS,

    [tk.TERMKEY_N_SYMS] = ui.KEY_UNKNOWN
}

return setmetatable({ }, { __index = curses, __newindex = function() error "Vandal error: Cannot modify `vandal.curses` table." end })

