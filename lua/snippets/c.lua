-- C snippets for LuaSnip. Appear in nvim-cmp; expand with <CR> / <C-y>.
-- Jump placeholders with <C-l> / <C-h>.
local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

local function header_guard()
  local name = vim.fn.expand("%:t")
  if name == "" then
    return "HEADER_H"
  end
  return name:upper():gsub("[^A-Z0-9]", "_")
end

local function guard_snip()
  return sn(nil, i(1, header_guard()))
end

local function S(trig, name, nodes)
  return s({ trig = trig, name = name, dscr = name }, nodes)
end

local function inc(trig, header)
  header = header or trig
  return S(trig, "#include <" .. header .. ".h>", t("#include <" .. header .. ".h>"))
end

ls.add_snippets("c", {
  -- ── file / main ──────────────────────────────────────────────
  S(
    "main",
    "int main(void)",
    fmta(
      [[
int main(void) {
    <>
    return 0;
}
]],
      { i(0) }
    )
  ),

  S(
    "maina",
    "int main(argc, argv)",
    fmta(
      [[
int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;
    <>
    return 0;
}
]],
      { i(0) }
    )
  ),

  S(
    "once",
    "header include guard",
    fmta(
      [[
#ifndef <>
#define <>

<>

#endif /* <> */
]],
      {
        d(1, guard_snip),
        rep(1),
        i(0),
        rep(1),
      }
    )
  ),

  S(
    "head",
    "file header comment",
    fmta(
      [[
/*
 * <>
 * <>
 */
]],
      {
        f(function()
          return vim.fn.expand("%:t")
        end),
        i(1, "description"),
      }
    )
  ),

  -- ── includes ─────────────────────────────────────────────────
  S("inc", "#include <header.h>", fmt("#include <{}.h>", { i(1, "stdio") })),
  S('inq', '#include "header.h"', fmt('#include "{}.h"', { i(1, "header") })),

  inc("stdio"),
  inc("stdlib"),
  inc("string"),
  inc("stdint"),
  inc("stdbool"),
  inc("stddef"),
  inc("stdarg"),
  inc("assert"),
  inc("errno"),
  inc("limits"),
  inc("float", "float"),
  inc("math"),
  inc("ctype"),
  inc("time"),
  inc("unistd"),
  inc("fcntl"),
  inc("signal"),
  inc("pthread"),
  inc("dirent"),
  inc("dlfcn"),
  inc("poll"),
  inc("semaphore"),
  inc("stdatomic"),
  inc("sys/types"),
  inc("sys/stat"),
  inc("sys/wait"),
  inc("sys/mman"),
  inc("sys/socket"),
  inc("sys/epoll"),
  inc("sys/time"),
  inc("netinet/in"),
  inc("arpa/inet"),
  inc("netdb"),

  -- ── preprocessor ─────────────────────────────────────────────
  S("def", "#define", fmt("#define {} {}", { i(1, "NAME"), i(2, "value") })),
  S(
    "ifdef",
    "#ifdef ... #endif",
    fmta(
      [[
#ifdef <>
<>
#endif
]],
      { i(1, "DEBUG"), i(0) }
    )
  ),
  S(
    "ifndef",
    "#ifndef ... #endif",
    fmta(
      [[
#ifndef <>
<>
#endif
]],
      { i(1, "NAME"), i(0) }
    )
  ),
  S(
    "if0",
    "#if 0 ... #endif (comment out)",
    fmta(
      [[
#if 0
<>
#endif
]],
      { i(0) }
    )
  ),

  S(
    "minmax",
    "MIN / MAX macros",
    t({
      "#define MIN(a, b) ((a) < (b) ? (a) : (b))",
      "#define MAX(a, b) ((a) > (b) ? (a) : (b))",
    })
  ),

  S(
    "lenof",
    "LEN(a) array-length macro",
    t("#define LEN(a) ((int)(sizeof(a) / sizeof((a)[0])))")
  ),

  S("unused", "UNUSED(x) macro", t("#define UNUSED(x) ((void)(x))")),

  -- ── control flow ─────────────────────────────────────────────
  S(
    "if",
    "if ()",
    fmta(
      [[
if (<>) {
    <>
}
]],
      { i(1, "cond"), i(0) }
    )
  ),

  S(
    "ife",
    "if / else",
    fmta(
      [[
if (<>) {
    <>
} else {
    <>
}
]],
      { i(1, "cond"), i(2), i(0) }
    )
  ),

  S(
    "elif",
    "else if",
    fmta(
      [[
else if (<>) {
    <>
}
]],
      { i(1, "cond"), i(0) }
    )
  ),

  S(
    "el",
    "else",
    fmta(
      [[
else {
    <>
}
]],
      { i(0) }
    )
  ),

  S(
    "for",
    "for loop",
    fmta(
      [[
for (<>; <>; <>) {
    <>
}
]],
      { i(1, "int i = 0"), i(2, "i < n"), i(3, "++i"), i(0) }
    )
  ),

  S(
    "fori",
    "for (int i = 0; i < n; ++i)",
    fmta(
      [[
for (int <> = 0; <> << <>; ++<>) {
    <>
}
]],
      { i(1, "i"), rep(1), i(2, "n"), rep(1), i(0) }
    )
  ),

  S(
    "forj",
    "for (int j = 0; j < n; ++j)",
    fmta(
      [[
for (int <> = 0; <> << <>; ++<>) {
    <>
}
]],
      { i(1, "j"), rep(1), i(2, "m"), rep(1), i(0) }
    )
  ),

  S(
    "forr",
    "reverse for loop",
    fmta(
      [[
for (int <> = <> - 1; <> >>= 0; --<>) {
    <>
}
]],
      { i(1, "i"), i(2, "n"), rep(1), rep(1), i(0) }
    )
  ),

  S(
    "fore",
    "for each element of array",
    fmta(
      [[
for (size_t <> = 0; <> << sizeof(<>) / sizeof((<>)[0]); ++<>) {
    <>
}
]],
      { i(1, "i"), rep(1), i(2, "arr"), rep(2), rep(1), i(0) }
    )
  ),

  S(
    "forp",
    "linked-list walk",
    fmta(
      [[
for (<> *<> = <>; <> != NULL; <> = <>->><>) {
    <>
}
]],
      {
        i(1, "Node"),
        i(2, "p"),
        i(3, "head"),
        rep(2),
        rep(2),
        rep(2),
        i(4, "next"),
        i(0),
      }
    )
  ),

  S(
    "wh",
    "while loop",
    fmta(
      [[
while (<>) {
    <>
}
]],
      { i(1, "cond"), i(0) }
    )
  ),

  S(
    "dw",
    "do while loop",
    fmta(
      [[
do {
    <>
} while (<>);
]],
      { i(0), i(1, "cond") }
    )
  ),

  S(
    "sw",
    "switch",
    fmta(
      [[
switch (<>) {
case <>:
    <>
    break;
default:
    <>
    break;
}
]],
      { i(1, "x"), i(2, "0"), i(3), i(0) }
    )
  ),

  S(
    "case",
    "case label",
    fmta(
      [[
case <>:
    <>
    break;
]],
      { i(1, "1"), i(0) }
    )
  ),

  S("tern", "ternary", fmt("{} ? {} : {}", { i(1, "cond"), i(2, "a"), i(3, "b") })),

  -- ── functions / types ────────────────────────────────────────
  S(
    "fn",
    "function definition",
    fmta(
      [[
<> <>(<>) {
    <>
}
]],
      { i(1, "void"), i(2, "name"), i(3, "void"), i(0) }
    )
  ),

  S(
    "fnd",
    "function declaration",
    fmt("{} {}({});", { i(1, "void"), i(2, "name"), i(3, "void") })
  ),

  S(
    "sfn",
    "static function",
    fmta(
      [[
static <> <>(<>) {
    <>
}
]],
      { i(1, "void"), i(2, "name"), i(3, "void"), i(0) }
    )
  ),

  S(
    "inl",
    "static inline function",
    fmta(
      [[
static inline <> <>(<>) {
    <>
}
]],
      { i(1, "int"), i(2, "name"), i(3, "void"), i(0) }
    )
  ),

  S(
    "st",
    "struct",
    fmta(
      [[
struct <> {
    <>
};
]],
      { i(1, "Name"), i(0) }
    )
  ),

  S(
    "tds",
    "typedef struct",
    fmta(
      [[
typedef struct <> {
    <>
} <>;
]],
      { i(1, "Name"), i(0), rep(1) }
    )
  ),

  S(
    "en",
    "enum",
    fmta(
      [[
typedef enum {
    <>
} <>;
]],
      { i(2, "VALUE"), i(1, "Name") }
    )
  ),

  S(
    "un",
    "union",
    fmta(
      [[
typedef union {
    <>
} <>;
]],
      { i(0), i(1, "Name") }
    )
  ),

  S("td", "typedef", fmt("typedef {} {};", { i(1, "int"), i(2, "name") })),

  -- ── I/O ──────────────────────────────────────────────────────
  S("pr", "printf", fmt('printf("{}\\n"{});', { i(1, "%s"), i(2) })),
  S("prd", "printf %d", fmt('printf("%d\\n", {});', { i(1, "n") })),
  S("prs", "printf %s", fmt('printf("%s\\n", {});', { i(1, "s") })),
  S("prf", "printf %f", fmt('printf("%f\\n", {});', { i(1, "x") })),
  S("fpr", "fprintf", fmt('fprintf({}, "{}\\n"{});', { i(1, "fp"), i(2, "%s"), i(3) })),
  S("epr", "fprintf stderr", fmt('fprintf(stderr, "{}\\n"{});', { i(1, "%s"), i(2) })),
  S("sc", "scanf", fmt('scanf("{}", {});', { i(1, "%d"), i(2, "&n") })),

  S(
    "fo",
    "fopen with check",
    fmta(
      [[
FILE *<> = fopen("<>", "<>");
if (<> == NULL) {
    perror("<>");
    <>
}
]],
      {
        i(1, "fp"),
        i(2, "path"),
        i(3, "r"),
        rep(1),
        rep(2),
        i(0, "return 1;"),
      }
    )
  ),

  S("fc", "fclose", fmt("fclose({});", { i(1, "fp") })),

  -- ── memory ───────────────────────────────────────────────────
  S(
    "mal",
    "malloc with NULL check",
    fmta(
      [[
<> *<> = malloc(<>sizeof(*<>));
if (<> == NULL) {
    perror("malloc");
    <>
}
]],
      {
        i(1, "int"),
        i(2, "p"),
        i(3, "n * "),
        rep(2),
        rep(2),
        i(0, "return 1;"),
      }
    )
  ),

  S(
    "cal",
    "calloc with NULL check",
    fmta(
      [[
<> *<> = calloc(<>, sizeof(*<>));
if (<> == NULL) {
    perror("calloc");
    <>
}
]],
      {
        i(1, "int"),
        i(2, "p"),
        i(3, "n"),
        rep(2),
        rep(2),
        i(0, "return 1;"),
      }
    )
  ),

  S(
    "real",
    "realloc with NULL check",
    fmta(
      [[
<> *<> = realloc(<>, <>sizeof(*<>));
if (<> == NULL) {
    perror("realloc");
    <>
}
<> = <>;
]],
      {
        i(1, "int"),
        i(2, "tmp"),
        i(3, "p"),
        i(4, "n * "),
        rep(3),
        rep(2),
        i(0, "return 1;"),
        rep(3),
        rep(2),
      }
    )
  ),

  S(
    "new",
    "malloc one object",
    fmta(
      [[
<> *<> = malloc(sizeof(*<>));
if (<> == NULL) {
    perror("malloc");
    <>
}
]],
      {
        i(1, "T"),
        i(2, "p"),
        rep(2),
        rep(2),
        i(0, "return 1;"),
      }
    )
  ),

  S(
    "fr",
    "free and NULL",
    fmta(
      [[
free(<>);
<> = NULL;
]],
      { i(1, "p"), rep(1) }
    )
  ),

  -- ── errors / debug ───────────────────────────────────────────
  S(
    "null",
    "NULL check",
    fmta(
      [[
if (<> == NULL) {
    <>
}
]],
      { i(1, "p"), i(0, "return 1;") }
    )
  ),

  S("perr", "perror", fmt('perror("{}");', { i(1, "msg") })),

  S(
    "die",
    "perror and exit",
    fmta(
      [[
perror("<>");
exit(EXIT_FAILURE);
]],
      { i(1, "msg") }
    )
  ),

  S(
    "dbg",
    "debug fprintf with file:line",
    fmta(
      [[
fprintf(stderr, "%s:%d: <>\\n", __FILE__, __LINE__<>);
]],
      { i(1, "here"), i(2) }
    )
  ),

  S("asrt", "assert", fmt("assert({});", { i(1, "cond") })),

  -- ── common calls ─────────────────────────────────────────────
  S("sz", "sizeof", fmt("sizeof({})", { i(1, "x") })),
  S("ret", "return", fmt("return {};", { i(1, "0") })),

  S(
    "cpy",
    "memcpy",
    fmt("memcpy({}, {}, {} * sizeof(*{}));", {
      i(1, "dst"),
      i(2, "src"),
      i(3, "n"),
      i(4, "dst"),
    })
  ),

  S(
    "set",
    "memset",
    fmt("memset({}, {}, {} * sizeof(*{}));", {
      i(1, "p"),
      i(2, "0"),
      i(3, "n"),
      i(4, "p"),
    })
  ),

  S("mcmp", "memcmp", fmt("memcmp({}, {}, {})", { i(1, "a"), i(2, "b"), i(3, "n") })),
  S("slen", "strlen", fmt("strlen({})", { i(1, "s") })),
  S("scmp", "strcmp", fmt("strcmp({}, {})", { i(1, "a"), i(2, "b") })),
  S("scpy", "strcpy", fmt("strcpy({}, {});", { i(1, "dst"), i(2, "src") })),
  S(
    "sncpy",
    "strncpy + terminate",
    fmta(
      [[
strncpy(<>, <>, <>);
<>[<> - 1] = '\0';
]],
      { i(1, "dst"), i(2, "src"), i(3, "n"), rep(1), rep(3) }
    )
  ),

  -- ── comments ─────────────────────────────────────────────────
  S("todo", "TODO comment", fmt("/* TODO: {} */", { i(1, "...") })),
  S("fixme", "FIXME comment", fmt("/* FIXME: {} */", { i(1, "...") })),
  S("note", "NOTE comment", fmt("/* NOTE: {} */", { i(1, "...") })),
  S(
    "doc",
    "block comment",
    fmta(
      [[
/*
 * <>
 */
]],
      { i(1) }
    )
  ),
  S(
    "fncom",
    "function doc comment",
    fmta(
      [[
/*
 * <>
 *
 * <>
 */
]],
      { i(1, "name"), i(2, "description") }
    )
  ),
})
