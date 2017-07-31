if not vandal.ffi then
    vandal.ffi = { }
elseif vandal.ffi.curses then
    error "wut?"
end

local bit = require "bit"
require "vandal/utils/stdlib_ext"

local decls = [[
typedef unsigned long chtype;
typedef void* FILE;
typedef chtype attr_t;
typedef struct
{
    int x;
    int y;
    short button[3];
    int changes;
    short xbutton[6];
} MOUSE_STATUS;
typedef unsigned long mmask_t;
typedef struct
{
        short id;
        int x, y, z;
        mmask_t bstate;
} MEVENT;
typedef struct _win
{
    int   _cury;
    int   _curx;
    int   _maxy;
    int   _maxx;
    int   _begy;
    int   _begx;
    int   _flags;
    chtype _attrs;
    chtype _bkgd;
    bool  _clear;
    bool  _leaveit;
    bool  _scroll;
    bool  _nodelay;
    bool  _immed;
    bool  _sync;
    bool  _use_keypad;
    chtype **_y;
    int   *_firstch;
    int   *_lastch;
    int   _tmarg;
    int   _bmarg;
    int   _delayms;
    int   _parx, _pary;
    struct _win *_parent;
} WINDOW;
typedef struct
{
    bool  alive;
    bool  autocr;
    bool  cbreak;
    bool  echo;
    bool  raw_inp;
    bool  raw_out;
    bool  audible;
    bool  mono;
    bool  resized;
    bool  orig_attr;
    short orig_fore;
    short orig_back;
    int   cursrow;
    int   curscol;
    int   visibility;
    int   orig_cursor;
    int   lines;
    int   cols;
    unsigned long _trap_mbe;
    unsigned long _map_mbe_to_key;
    int   mouse_wait;
    int   slklines;
    WINDOW *slk_winptr;
    int   linesrippedoff;
    int   linesrippedoffontop;
    int   delaytenths;
    bool  _preserve;
    int   _restore;
    bool  save_key_modifiers;
    bool  return_key_modifiers;
    bool  key_code;
    short line_color;
} SCREEN;
extern  int          LINES;
extern  int          COLS;
extern  WINDOW       *stdscr;
extern  WINDOW       *curscr;
extern  SCREEN       *SP;
extern  MOUSE_STATUS Mouse_status;
extern  int          COLORS;
extern  int          COLOR_PAIRS;
extern  int          TABSIZE;
extern  chtype       acs_map[];
extern  char         ttytype[];
int     addch(const chtype);
int     addchnstr(const chtype *, int);
int     addchstr(const chtype *);
int     addnstr(const char *, int);
int     addstr(const char *);
int     attroff(chtype);
int     attron(chtype);
int     attrset(chtype);
int     attr_get(attr_t *, short *, void *);
int     attr_off(attr_t, void *);
int     attr_on(attr_t, void *);
int     attr_set(attr_t, short, void *);
int     baudrate(void);
int     beep(void);
int     bkgd(chtype);
void    bkgdset(chtype);
int     border(chtype, chtype, chtype, chtype, chtype, chtype, chtype, chtype);
int     box(WINDOW *, chtype, chtype);
bool    can_change_color(void);
int     cbreak(void);
int     chgat(int, attr_t, short, const void *);
int     clearok(WINDOW *, bool);
int     clear(void);
int     clrtobot(void);
int     clrtoeol(void);
int     color_content(short, short *, short *, short *);
int     color_set(short, void *);
int     copywin(const WINDOW *, WINDOW *, int, int, int, int, int, int, int);
int     curs_set(int);
int     def_prog_mode(void);
int     def_shell_mode(void);
int     delay_output(int);
int     delch(void);
int     deleteln(void);
void    delscreen(SCREEN *);
int     delwin(WINDOW *);
WINDOW *derwin(WINDOW *, int, int, int, int);
int     doupdate(void);
WINDOW *dupwin(WINDOW *);
int     echochar(const chtype);
int     echo(void);
int     endwin(void);
char    erasechar(void);
int     erase(void);
void    filter(void);
int     flash(void);
int     flushinp(void);
chtype  getbkgd(WINDOW *);
int     getch(void);
int     getnstr(char *, int);
int     getstr(char *);
WINDOW *getwin(FILE *);
int     halfdelay(int);
bool    has_colors(void);
bool    has_ic(void);
bool    has_il(void);
int     hline(chtype, int);
void    idcok(WINDOW *, bool);
int     idlok(WINDOW *, bool);
void    immedok(WINDOW *, bool);
int     inchnstr(chtype *, int);
int     inchstr(chtype *);
chtype  inch(void);
int     init_color(short, short, short, short);
int     init_pair(short, short, short);
WINDOW *initscr(void);
int     innstr(char *, int);
int     insch(chtype);
int     insdelln(int);
int     insertln(void);
int     insnstr(const char *, int);
int     insstr(const char *);
int     instr(char *);
int     intrflush(WINDOW *, bool);
bool    isendwin(void);
bool    is_linetouched(WINDOW *, int);
bool    is_wintouched(WINDOW *);
char   *keyname(int);
int     keypad(WINDOW *, bool);
char    killchar(void);
int     leaveok(WINDOW *, bool);
char   *longname(void);
int     meta(WINDOW *, bool);
int     move(int, int);
int     mvaddch(int, int, const chtype);
int     mvaddchnstr(int, int, const chtype *, int);
int     mvaddchstr(int, int, const chtype *);
int     mvaddnstr(int, int, const char *, int);
int     mvaddstr(int, int, const char *);
int     mvchgat(int, int, int, attr_t, short, const void *);
int     mvcur(int, int, int, int);
int     mvdelch(int, int);
int     mvderwin(WINDOW *, int, int);
int     mvgetch(int, int);
int     mvgetnstr(int, int, char *, int);
int     mvgetstr(int, int, char *);
int     mvhline(int, int, chtype, int);
chtype  mvinch(int, int);
int     mvinchnstr(int, int, chtype *, int);
int     mvinchstr(int, int, chtype *);
int     mvinnstr(int, int, char *, int);
int     mvinsch(int, int, chtype);
int     mvinsnstr(int, int, const char *, int);
int     mvinsstr(int, int, const char *);
int     mvinstr(int, int, char *);
int     mvprintw(int, int, const char *, ...);
int     mvscanw(int, int, const char *, ...);
int     mvvline(int, int, chtype, int);
int     mvwaddchnstr(WINDOW *, int, int, const chtype *, int);
int     mvwaddchstr(WINDOW *, int, int, const chtype *);
int     mvwaddch(WINDOW *, int, int, const chtype);
int     mvwaddnstr(WINDOW *, int, int, const char *, int);
int     mvwaddstr(WINDOW *, int, int, const char *);
int     mvwchgat(WINDOW *, int, int, int, attr_t, short, const void *);
int     mvwdelch(WINDOW *, int, int);
int     mvwgetch(WINDOW *, int, int);
int     mvwgetnstr(WINDOW *, int, int, char *, int);
int     mvwgetstr(WINDOW *, int, int, char *);
int     mvwhline(WINDOW *, int, int, chtype, int);
int     mvwinchnstr(WINDOW *, int, int, chtype *, int);
int     mvwinchstr(WINDOW *, int, int, chtype *);
chtype  mvwinch(WINDOW *, int, int);
int     mvwinnstr(WINDOW *, int, int, char *, int);
int     mvwinsch(WINDOW *, int, int, chtype);
int     mvwinsnstr(WINDOW *, int, int, const char *, int);
int     mvwinsstr(WINDOW *, int, int, const char *);
int     mvwinstr(WINDOW *, int, int, char *);
int     mvwin(WINDOW *, int, int);
int     mvwprintw(WINDOW *, int, int, const char *, ...);
int     mvwscanw(WINDOW *, int, int, const char *, ...);
int     mvwvline(WINDOW *, int, int, chtype, int);
int     napms(int);
WINDOW *newpad(int, int);
SCREEN *newterm(const char *, FILE *, FILE *);
WINDOW *newwin(int, int, int, int);
int     nl(void);
int     nocbreak(void);
int     nodelay(WINDOW *, bool);
int     noecho(void);
int     nonl(void);
void    noqiflush(void);
int     noraw(void);
int     notimeout(WINDOW *, bool);
int     overlay(const WINDOW *, WINDOW *);
int     overwrite(const WINDOW *, WINDOW *);
int     pair_content(short, short *, short *);
int     pechochar(WINDOW *, chtype);
int     pnoutrefresh(WINDOW *, int, int, int, int, int, int);
int     prefresh(WINDOW *, int, int, int, int, int, int);
int     printw(const char *, ...);
int     putwin(WINDOW *, FILE *);
void    qiflush(void);
int     raw(void);
int     redrawwin(WINDOW *);
int     refresh(void);
int     reset_prog_mode(void);
int     reset_shell_mode(void);
int     resetty(void);
int     ripoffline(int, int (*)(WINDOW *, int));
int     savetty(void);
int     scanw(const char *, ...);
int     scr_dump(const char *);
int     scr_init(const char *);
int     scr_restore(const char *);
int     scr_set(const char *);
int     scrl(int);
int     scroll(WINDOW *);
int     scrollok(WINDOW *, bool);
SCREEN *set_term(SCREEN *);
int     setscrreg(int, int);
int     slk_attroff(const chtype);
int     slk_attr_off(const attr_t, void *);
int     slk_attron(const chtype);
int     slk_attr_on(const attr_t, void *);
int     slk_attrset(const chtype);
int     slk_attr_set(const attr_t, short, void *);
int     slk_clear(void);
int     slk_color(short);
int     slk_init(int);
char   *slk_label(int);
int     slk_noutrefresh(void);
int     slk_refresh(void);
int     slk_restore(void);
int     slk_set(int, const char *, int);
int     slk_touch(void);
int     standend(void);
int     standout(void);
int     start_color(void);
WINDOW *subpad(WINDOW *, int, int, int, int);
WINDOW *subwin(WINDOW *, int, int, int, int);
int     syncok(WINDOW *, bool);
chtype  termattrs(void);
attr_t  term_attrs(void);
char   *termname(void);
void    timeout(int);
int     touchline(WINDOW *, int, int);
int     touchwin(WINDOW *);
int     typeahead(int);
int     untouchwin(WINDOW *);
void    use_env(bool);
int     vidattr(chtype);
int     vid_attr(attr_t, short, void *);
int     vidputs(chtype, int (*)(int));
int     vid_puts(attr_t, short, void *, int (*)(int));
int     vline(chtype, int);
int     vw_printw(WINDOW *, const char *, va_list);
int     vwprintw(WINDOW *, const char *, va_list);
int     vw_scanw(WINDOW *, const char *, va_list);
int     vwscanw(WINDOW *, const char *, va_list);
int     waddchnstr(WINDOW *, const chtype *, int);
int     waddchstr(WINDOW *, const chtype *);
int     waddch(WINDOW *, const chtype);
int     waddnstr(WINDOW *, const char *, int);
int     waddstr(WINDOW *, const char *);
int     wattroff(WINDOW *, chtype);
int     wattron(WINDOW *, chtype);
int     wattrset(WINDOW *, chtype);
int     wattr_get(WINDOW *, attr_t *, short *, void *);
int     wattr_off(WINDOW *, attr_t, void *);
int     wattr_on(WINDOW *, attr_t, void *);
int     wattr_set(WINDOW *, attr_t, short, void *);
void    wbkgdset(WINDOW *, chtype);
int     wbkgd(WINDOW *, chtype);
int     wborder(WINDOW *, chtype, chtype, chtype, chtype,
                chtype, chtype, chtype, chtype);
int     wchgat(WINDOW *, int, attr_t, short, const void *);
int     wclear(WINDOW *);
int     wclrtobot(WINDOW *);
int     wclrtoeol(WINDOW *);
int     wcolor_set(WINDOW *, short, void *);
void    wcursyncup(WINDOW *);
int     wdelch(WINDOW *);
int     wdeleteln(WINDOW *);
int     wechochar(WINDOW *, const chtype);
int     werase(WINDOW *);
int     wgetch(WINDOW *);
int     wgetnstr(WINDOW *, char *, int);
int     wgetstr(WINDOW *, char *);
int     whline(WINDOW *, chtype, int);
int     winchnstr(WINDOW *, chtype *, int);
int     winchstr(WINDOW *, chtype *);
chtype  winch(WINDOW *);
int     winnstr(WINDOW *, char *, int);
int     winsch(WINDOW *, chtype);
int     winsdelln(WINDOW *, int);
int     winsertln(WINDOW *);
int     winsnstr(WINDOW *, const char *, int);
int     winsstr(WINDOW *, const char *);
int     winstr(WINDOW *, char *);
int     wmove(WINDOW *, int, int);
int     wnoutrefresh(WINDOW *);
int     wprintw(WINDOW *, const char *, ...);
int     wredrawln(WINDOW *, int, int);
int     wrefresh(WINDOW *);
int     wscanw(WINDOW *, const char *, ...);
int     wscrl(WINDOW *, int);
int     wsetscrreg(WINDOW *, int, int);
int     wstandend(WINDOW *);
int     wstandout(WINDOW *);
void    wsyncdown(WINDOW *);
void    wsyncup(WINDOW *);
void    wtimeout(WINDOW *, int);
int     wtouchln(WINDOW *, int, int, int);
int     wvline(WINDOW *, chtype, int);
chtype  getattrs(WINDOW *);
int     getbegx(WINDOW *);
int     getbegy(WINDOW *);
int     getmaxx(WINDOW *);
int     getmaxy(WINDOW *);
int     getparx(WINDOW *);
int     getpary(WINDOW *);
int     getcurx(WINDOW *);
int     getcury(WINDOW *);
void    traceoff(void);
void    traceon(void);
char   *unctrl(chtype);
int     crmode(void);
int     nocrmode(void);
int     draino(int);
int     resetterm(void);
int     fixterm(void);
int     saveterm(void);
int     setsyx(int, int);
int     mouse_set(unsigned long);
int     mouse_on(unsigned long);
int     mouse_off(unsigned long);
int     request_mouse_pos(void);
int     map_button(unsigned long);
void    wmouse_position(WINDOW *, int *, int *);
unsigned long getmouse(void);
unsigned long getbmap(void);
int     assume_default_colors(int, int);
const char *curses_version(void);
bool    has_key(int);
int     use_default_colors(void);
int     wresize(WINDOW *, int, int);
int     mouseinterval(int);
mmask_t mousemask(mmask_t, mmask_t *);
bool    mouse_trafo(int *, int *, bool);
int     nc_getmouse(MEVENT *);
int     ungetmouse(MEVENT *);
bool    wenclose(const WINDOW *, int, int);
bool    wmouse_trafo(const WINDOW *, int *, int *, bool);
int     addrawch(chtype);
int     insrawch(chtype);
bool    is_termresized(void);
int     mvaddrawch(int, int, chtype);
int     mvdeleteln(int, int);
int     mvinsertln(int, int);
int     mvinsrawch(int, int, chtype);
int     mvwaddrawch(WINDOW *, int, int, chtype);
int     mvwdeleteln(WINDOW *, int, int);
int     mvwinsertln(WINDOW *, int, int);
int     mvwinsrawch(WINDOW *, int, int, chtype);
int     raw_output(bool);
int     resize_term(int, int);
WINDOW *resize_window(WINDOW *, int, int);
int     waddrawch(WINDOW *, chtype);
int     winsrawch(WINDOW *, chtype);
char    wordchar(void);
void    PDC_debug(const char *, ...);
int     PDC_ungetch(int);
int     PDC_set_blink(bool);
int     PDC_set_line_color(short);
void    PDC_set_title(const char *);
int     PDC_clearclipboard(void);
int     PDC_freeclipboard(char *);
int     PDC_getclipboard(char **, long *);
int     PDC_setclipboard(const char *, long);
unsigned long PDC_get_input_fd(void);
unsigned long PDC_get_key_modifiers(void);
int     PDC_return_key_modifiers(bool);
int     PDC_save_key_modifiers(bool);
void    PDC_set_resize_limits( const int new_min_lines,
                               const int new_max_lines,
                               const int new_min_cols,
                               const int new_max_cols);
WINDOW *Xinitscr(int, char **);

int COLOR_PAIR(int);
]]

local ffi, okay, lib = require "ffi"
ffi.cdef(decls)

if jit.os == "Windows" then
    okay, lib = pcall(ffi.load, "pdcurses")
else
    okay, lib = pcall(ffi.load, "libncursesw.so.5")

    if not okay then
        okay, lib = pcall(ffi.load, "ncursesw")
    end
end

if not okay then
    error("Couldn't find a suitable ncurses library to load.")
end

local curses = { DECLS = decls }

function curses.freeconsole()
    if jit.os == "Windows" then
        ffi.cdef("int FreeConsole();")
        ffi.C.FreeConsole()
    end
end

local function num(str)
    local res = 0

    if str:sub(1, 1) == '0' then
        --  Octal

        for i = 2, #str do
            res = res * 8 + tonumber(str:sub(i, i))
        end
    else
        error "wut?"
    end

    return res
end

--  These are extracted from the header.
curses.KEY_MIN          = num("0401")
curses.KEY_BREAK        = num("0401")
curses.KEY_SRESET       = num("0530")
curses.KEY_RESET        = num("0531")
curses.KEY_DOWN         = num("0402")
curses.KEY_UP           = num("0403")
curses.KEY_LEFT         = num("0404")
curses.KEY_RIGHT        = num("0405")
curses.KEY_HOME         = num("0406")
curses.KEY_BACKSPACE    = num("0407")
curses.KEY_F0           = num("0410")
curses.KEY_DL           = num("0510")
curses.KEY_IL           = num("0511")
curses.KEY_DC           = num("0512")
curses.KEY_IC           = num("0513")
curses.KEY_EIC          = num("0514")
curses.KEY_CLEAR        = num("0515")
curses.KEY_EOS          = num("0516")
curses.KEY_EOL          = num("0517")
curses.KEY_SF           = num("0520")
curses.KEY_SR           = num("0521")
curses.KEY_NPAGE        = num("0522")
curses.KEY_PPAGE        = num("0523")
curses.KEY_STAB         = num("0524")
curses.KEY_CTAB         = num("0525")
curses.KEY_CATAB        = num("0526")
curses.KEY_ENTER        = num("0527")
curses.KEY_PRINT        = num("0532")
curses.KEY_LL           = num("0533")
curses.KEY_A1           = num("0534")
curses.KEY_A3           = num("0535")
curses.KEY_B2           = num("0536")
curses.KEY_C1           = num("0537")
curses.KEY_C3           = num("0540")
curses.KEY_BTAB         = num("0541")
curses.KEY_BEG          = num("0542")
curses.KEY_CANCEL       = num("0543")
curses.KEY_CLOSE        = num("0544")
curses.KEY_COMMAND      = num("0545")
curses.KEY_COPY         = num("0546")
curses.KEY_CREATE       = num("0547")
curses.KEY_END          = num("0550")
curses.KEY_EXIT         = num("0551")
curses.KEY_FIND         = num("0552")
curses.KEY_HELP         = num("0553")
curses.KEY_MARK         = num("0554")
curses.KEY_MESSAGE      = num("0555")
curses.KEY_MOVE         = num("0556")
curses.KEY_NEXT         = num("0557")
curses.KEY_OPEN         = num("0560")
curses.KEY_OPTIONS      = num("0561")
curses.KEY_PREVIOUS     = num("0562")
curses.KEY_REDO         = num("0563")
curses.KEY_REFERENCE    = num("0564")
curses.KEY_REFRESH      = num("0565")
curses.KEY_REPLACE      = num("0566")
curses.KEY_RESTART      = num("0567")
curses.KEY_RESUME       = num("0570")
curses.KEY_SAVE         = num("0571")
curses.KEY_SBEG         = num("0572")
curses.KEY_SCANCEL      = num("0573")
curses.KEY_SCOMMAND     = num("0574")
curses.KEY_SCOPY        = num("0575")
curses.KEY_SCREATE      = num("0576")
curses.KEY_SDC          = num("0577")
curses.KEY_SDL          = num("0600")
curses.KEY_SELECT       = num("0601")
curses.KEY_SEND         = num("0602")
curses.KEY_SEOL         = num("0603")
curses.KEY_SEXIT        = num("0604")
curses.KEY_SFIND        = num("0605")
curses.KEY_SHELP        = num("0606")
curses.KEY_SHOME        = num("0607")
curses.KEY_SIC          = num("0610")
curses.KEY_SLEFT        = num("0611")
curses.KEY_SMESSAGE     = num("0612")
curses.KEY_SMOVE        = num("0613")
curses.KEY_SNEXT        = num("0614")
curses.KEY_SOPTIONS     = num("0615")
curses.KEY_SPREVIOUS    = num("0616")
curses.KEY_SPRINT       = num("0617")
curses.KEY_SREDO        = num("0620")
curses.KEY_SREPLACE     = num("0621")
curses.KEY_SRIGHT       = num("0622")
curses.KEY_SRSUME       = num("0623")
curses.KEY_SSAVE        = num("0624")
curses.KEY_SSUSPEND     = num("0625")
curses.KEY_SUNDO        = num("0626")
curses.KEY_SUSPEND      = num("0627")
curses.KEY_UNDO         = num("0630")
curses.KEY_MOUSE        = num("0631")
curses.KEY_RESIZE       = num("0632")
curses.KEY_EVENT        = num("0633")
curses.KEY_MAX          = num("0777")

function curses.KEY_F(n)
    return curses.KEY_F0 + n
end

for i = 1, 20 do
    curses["KEY_F" .. i] = curses.KEY_F(i)
end

local keyz = {}

for k, v in pairs(curses) do
    if type(k) == "string" and k:sub(1, 4) == "KEY_" and k ~= "KEY_MIN" and k ~= "KEY_MAX" then
        if keyz[v] then error("wut? " .. k .. " collides with " .. keyz[v]) end

        keyz[v] = k:sub(5)
    end
end

for i = 32, 126 do
    keyz[i] = string.char(i)
end

for i = 1, 26 do
    keyz[i] = "C-" .. string.char(i - 1 + string.byte 'a')
end

keyz[27] = "ESC"
keyz[10] = "\\n"
keyz[9]  = "\\t"

curses.KEY_ESC = 27
curses.KEY_NEWLINE = 10
curses.KEY_TABULATOR = 9

function curses.get_key(val)
    val = tonumber(val)

    if not val then
        error("Value given to `curses.get_key` is not a number.")
    end

    return keyz[val]
end

local NCURSES_ATTR_SHIFT = 8

local function NCURSES_BITS(val, shift)
    return bit.lshift(val, shift + NCURSES_ATTR_SHIFT)
end
curses.NCURSES_BITS = NCURSES_BITS
curses.NCURSES_ATTR_SHIFT = NCURSES_ATTR_SHIFT

curses.A_NORMAL     = 0
curses.A_STANDOUT   = NCURSES_BITS(1,  8)
curses.A_UNDERLINE  = NCURSES_BITS(1,  9)
curses.A_REVERSE    = NCURSES_BITS(1, 10)
curses.A_BLINK      = NCURSES_BITS(1, 11)
curses.A_DIM        = NCURSES_BITS(1, 12)
curses.A_BOLD       = NCURSES_BITS(1, 13)
curses.A_ALTCHARSET = NCURSES_BITS(1, 14)
curses.A_INVIS      = NCURSES_BITS(1, 15)
curses.A_PROTECT    = NCURSES_BITS(1, 16)
curses.A_HORIZONTAL = NCURSES_BITS(1, 17)
curses.A_LEFT       = NCURSES_BITS(1, 18)
curses.A_LOW        = NCURSES_BITS(1, 19)
curses.A_RIGHT      = NCURSES_BITS(1, 20)
curses.A_TOP        = NCURSES_BITS(1, 21)
curses.A_VERTICAL   = NCURSES_BITS(1, 22)
curses.A_ITALIC     = NCURSES_BITS(1, 23)

function curses.pairs()
    return table.multipairs(curses, lib)
end

vandal.ffi.curses = setmetatable({ }, {
    __index = function(self, key)
        return curses[key] or lib[key]
    end,

    __newindex = function() error "Vandal error: Cannot modify the `vandal.ffi.curses` table." end,
})

return vandal.ffi.curses

