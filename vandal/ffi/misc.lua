local ffi = require "ffi"

ffi.cdef [[
typedef struct FILE_s { } FILE;

FILE * stdin;
FILE * stdout;
FILE * stderr;

int fileno(FILE * stream);

int usleep(unsigned int useconds);

char * setlocale(int category, const char * locale);

enum setlocale_categories {
    LC_ALL      = 6,
    LC_COLLATE  = 3,
    LC_CTYPE    = 0,
    LC_MESSAGES = 5,
    LC_MONETARY = 4,
    LC_NUMERIC  = 1,
    LC_TIME     = 2,
};
]]

