-- Completions for C/POSIX symbols that clangd cannot see until the header
-- is already included. Accepting an item inserts `#include <...>` first.

local M = {}

local KIND = {
  Function = 3,
  Constant = 21,
  Struct = 22,
  EnumMember = 20,
}

local SNIPS = {
  pthread_create = "pthread_create(&${1:thread}, ${2:NULL}, ${3:start}, ${4:NULL})",
  pthread_join = "pthread_join(${1:thread}, ${2:NULL})",
  pthread_detach = "pthread_detach(${1:thread})",
  pthread_mutex_init = "pthread_mutex_init(&${1:mutex}, ${2:NULL})",
  pthread_mutex_lock = "pthread_mutex_lock(&${1:mutex})",
  pthread_mutex_unlock = "pthread_mutex_unlock(&${1:mutex})",
  pthread_cond_wait = "pthread_cond_wait(&${1:cond}, &${2:mutex})",
  pthread_cond_signal = "pthread_cond_signal(&${1:cond})",
  pthread_cond_broadcast = "pthread_cond_broadcast(&${1:cond})",
  malloc = "malloc(${1:n} * sizeof(*${2:p}))",
  calloc = "calloc(${1:n}, sizeof(${2:T}))",
  realloc = "realloc(${1:p}, ${2:n} * sizeof(*${1:p}))",
  fopen = 'fopen("${1:path}", "${2:r}")',
  printf = 'printf("${1:%s}\\n"${2})',
  fprintf = 'fprintf(${1:stderr}, "${2:%s}\\n"${3})',
  snprintf = 'snprintf(${1:buf}, ${2:sizeof(buf)}, "${3:%s}"${4})',
  mmap = "mmap(${1:NULL}, ${2:len}, ${3:PROT_READ | PROT_WRITE}, ${4:MAP_PRIVATE | MAP_ANONYMOUS}, ${5:-1}, ${6:0})",
  socket = "socket(${1:AF_INET}, ${2:SOCK_STREAM}, ${3:0})",
  bind = "bind(${1:fd}, (struct sockaddr *)&${2:addr}, sizeof(${2:addr}))",
  listen = "listen(${1:fd}, ${2:SOMAXCONN})",
  accept = "accept(${1:fd}, (struct sockaddr *)&${2:addr}, &${3:len})",
  connect = "connect(${1:fd}, (struct sockaddr *)&${2:addr}, sizeof(${2:addr}))",
  getaddrinfo = "getaddrinfo(${1:host}, ${2:port}, &${3:hints}, &${4:res})",
  open = 'open("${1:path}", ${2:O_RDONLY})',
  mmap_file = nil,
}

-- header -> { fn = "...", ty = "...", mac = "..." }
local HEADERS = {
  ["stdio.h"] = {
    ty = "FILE fpos_t",
    fn = "printf fprintf sprintf snprintf asprintf dprintf vprintf vfprintf vsprintf vsnprintf scanf fscanf sscanf fopen fdopen freopen fclose fread fwrite fgets fputs fgetc fputc getc putc getchar putchar ungetc puts perror feof ferror clearerr rewind fseek ftell fseeko ftello fflush setvbuf setbuf rename remove tmpfile tmpnam getline getdelim fileno popen pclose flockfile funlockfile",
    mac = "stdin stdout stderr EOF BUFSIZ SEEK_SET SEEK_CUR SEEK_END FILENAME_MAX",
  },
  ["stdlib.h"] = {
    fn = "malloc calloc realloc free aligned_alloc posix_memalign exit abort atexit atoi atol atoll atof strtol strtoul strtoll strtoull strtod strtof qsort bsearch abs labs llabs rand srand getenv setenv unsetenv putenv system realpath mkstemp mkdtemp abs",
    mac = "EXIT_SUCCESS EXIT_FAILURE RAND_MAX",
  },
  ["string.h"] = {
    fn = "memcpy memmove memset memcmp memchr strcpy strncpy strcat strncat strcmp strncmp strchr strrchr strstr strtok strtok_r strlen strnlen strdup strndup strerror strerror_r strsignal strcoll strxfrm strcspn strspn strpbrk",
  },
  ["strings.h"] = {
    fn = "strcasecmp strncasecmp bzero bcopy bcmp",
  },
  ["ctype.h"] = {
    fn = "isalnum isalpha isblank iscntrl isdigit isgraph islower isprint ispunct isspace isupper isxdigit tolower toupper",
  },
  ["math.h"] = {
    fn = "sin cos tan asin acos atan atan2 sinh cosh tanh exp log log10 log2 pow sqrt cbrt hypot ceil floor round trunc fabs fmod frexp ldexp modf nearbyint rint remainder copysign fmin fmax fma nan",
    mac = "NAN INFINITY M_PI M_E M_SQRT2 HUGE_VAL HUGE_VALF",
  },
  ["stdint.h"] = {
    ty = "int8_t int16_t int32_t int64_t uint8_t uint16_t uint32_t uint64_t intptr_t uintptr_t intmax_t uintmax_t int_fast8_t int_fast16_t int_fast32_t int_fast64_t uint_fast8_t uint_fast16_t uint_fast32_t uint_fast64_t int_least8_t int_least16_t int_least32_t int_least64_t uint_least8_t uint_least16_t uint_least32_t uint_least64_t",
    mac = "INT8_MAX INT16_MAX INT32_MAX INT64_MAX UINT8_MAX UINT16_MAX UINT32_MAX UINT64_MAX INTPTR_MAX UINTPTR_MAX",
  },
  ["stddef.h"] = {
    ty = "size_t ptrdiff_t max_align_t wchar_t",
    mac = "NULL offsetof",
  },
  ["stdbool.h"] = {
    ty = "bool",
    mac = "true false",
  },
  ["stdarg.h"] = {
    ty = "va_list",
    mac = "va_start va_end va_arg va_copy",
  },
  ["assert.h"] = {
    mac = "assert static_assert",
  },
  ["errno.h"] = {
    mac = "errno EPERM ENOENT ESRCH EINTR EIO EBADF EAGAIN ENOMEM EACCES EFAULT EBUSY EEXIST ENOTDIR EISDIR EINVAL ENFILE EMFILE ENOSPC EPIPE EDOM ERANGE EDEADLK ENAMETOOLONG ENOSYS ENOTEMPTY EWOULDBLOCK EINPROGRESS EALREADY ENOTSOCK EPROTONOSUPPORT EOPNOTSUPP EAFNOSUPPORT EADDRINUSE EADDRNOTAVAIL ENETUNREACH ECONNABORTED ECONNRESET ENOBUFS EISCONN ENOTCONN ETIMEDOUT ECONNREFUSED EHOSTUNREACH",
  },
  ["time.h"] = {
    ty = "time_t clock_t timespec tm clockid_t",
    fn = "time clock difftime mktime strftime localtime gmtime localtime_r gmtime_r asctime ctime nanosleep clock_gettime clock_settime clock_getres",
    mac = "CLOCKS_PER_SEC CLOCK_REALTIME CLOCK_MONOTONIC CLOCK_MONOTONIC_RAW",
  },
  ["signal.h"] = {
    ty = "sigset_t siginfo_t sigaction",
    fn = "signal raise sigaction sigemptyset sigfillset sigaddset sigdelset sigismember sigprocmask sigpending sigsuspend kill killpg sigwait sigtimedwait",
    mac = "SIG_DFL SIG_IGN SIG_ERR SIGHUP SIGINT SIGQUIT SIGILL SIGTRAP SIGABRT SIGBUS SIGFPE SIGKILL SIGUSR1 SIGSEGV SIGUSR2 SIGPIPE SIGALRM SIGTERM SIGCHLD SIGCONT SIGSTOP SIGTSTP SIGTTIN SIGTTOU SIGXCPU SIGXFSZ SIGVTALRM SIGPROF SIGWINCH SIGIO SIGSYS",
  },
  ["pthread.h"] = {
    ty = "pthread_t pthread_attr_t pthread_mutex_t pthread_mutexattr_t pthread_cond_t pthread_condattr_t pthread_key_t pthread_once_t pthread_rwlock_t pthread_rwlockattr_t pthread_spinlock_t pthread_barrier_t pthread_barrierattr_t",
    fn = "pthread_create pthread_join pthread_detach pthread_exit pthread_self pthread_equal pthread_cancel pthread_setcancelstate pthread_setcanceltype pthread_testcancel pthread_attr_init pthread_attr_destroy pthread_attr_setdetachstate pthread_attr_getdetachstate pthread_attr_setstacksize pthread_attr_getstacksize pthread_mutex_init pthread_mutex_destroy pthread_mutex_lock pthread_mutex_trylock pthread_mutex_timedlock pthread_mutex_unlock pthread_mutexattr_init pthread_mutexattr_destroy pthread_mutexattr_settype pthread_mutexattr_gettype pthread_cond_init pthread_cond_destroy pthread_cond_wait pthread_cond_timedwait pthread_cond_signal pthread_cond_broadcast pthread_rwlock_init pthread_rwlock_destroy pthread_rwlock_rdlock pthread_rwlock_wrlock pthread_rwlock_unlock pthread_rwlock_tryrdlock pthread_rwlock_trywrlock pthread_spin_init pthread_spin_destroy pthread_spin_lock pthread_spin_trylock pthread_spin_unlock pthread_barrier_init pthread_barrier_destroy pthread_barrier_wait pthread_key_create pthread_key_delete pthread_setspecific pthread_getspecific pthread_once pthread_setname_np pthread_getname_np",
    mac = "PTHREAD_MUTEX_INITIALIZER PTHREAD_COND_INITIALIZER PTHREAD_ONCE_INIT PTHREAD_RWLOCK_INITIALIZER PTHREAD_CREATE_JOINABLE PTHREAD_CREATE_DETACHED PTHREAD_MUTEX_NORMAL PTHREAD_MUTEX_RECURSIVE PTHREAD_MUTEX_ERRORCHECK PTHREAD_CANCEL_ENABLE PTHREAD_CANCEL_DISABLE PTHREAD_BARRIER_SERIAL_THREAD",
  },
  ["unistd.h"] = {
    fn = "read write close lseek fork vfork pipe pipe2 dup dup2 dup3 execve execv execvp execl execlp execvpe getpid getppid getuid geteuid getgid getegid setuid setgid seteuid setegid sleep usleep pause chdir fchdir getcwd access unlink rmdir isatty ttyname gethostname sethostname sysconf pathconf _exit fsync fdatasync ftruncate truncate pread pwrite getopt getopt_long alarm ualarm setpgid getpgid setsid getsid tcgetpgrp tcsetpgrp",
    mac = "STDIN_FILENO STDOUT_FILENO STDERR_FILENO F_OK R_OK W_OK X_OK",
  },
  ["fcntl.h"] = {
    fn = "open openat creat fcntl posix_fadvise posix_fallocate",
    mac = "O_RDONLY O_WRONLY O_RDWR O_CREAT O_EXCL O_TRUNC O_APPEND O_NONBLOCK O_CLOEXEC O_SYNC O_DIRECTORY O_NOFOLLOW O_PATH F_GETFL F_SETFL F_GETFD F_SETFD F_DUPFD F_DUPFD_CLOEXEC FD_CLOEXEC F_GETLK F_SETLK F_SETLKW F_RDLCK F_WRLCK F_UNLCK",
  },
  ["sys/stat.h"] = {
    fn = "stat fstat lstat fstatat mkdir mkdirat chmod fchmod fchmodat umask mkfifo mknod",
    mac = "S_IFMT S_IFREG S_IFDIR S_IFLNK S_IFIFO S_IFSOCK S_IFCHR S_IFBLK S_ISREG S_ISDIR S_ISLNK S_ISFIFO S_ISSOCK S_ISCHR S_ISBLK S_IRWXU S_IRUSR S_IWUSR S_IXUSR S_IRWXG S_IRGRP S_IWGRP S_IXGRP S_IRWXO S_IROTH S_IWOTH S_IXOTH S_ISUID S_ISGID S_ISVTX",
  },
  ["sys/types.h"] = {
    ty = "pid_t uid_t gid_t off_t ssize_t mode_t dev_t ino_t nlink_t blkcnt_t blksize_t id_t key_t useconds_t suseconds_t clockid_t",
  },
  ["sys/wait.h"] = {
    fn = "wait waitpid waitid wait3 wait4",
    mac = "WIFEXITED WEXITSTATUS WIFSIGNALED WTERMSIG WIFSTOPPED WSTOPSIG WIFCONTINUED WNOHANG WUNTRACED WCONTINUED",
  },
  ["sys/mman.h"] = {
    fn = "mmap munmap mprotect msync madvise posix_madvise mlock munlock mlockall munlockall shm_open shm_unlink",
    mac = "MAP_FAILED PROT_READ PROT_WRITE PROT_EXEC PROT_NONE MAP_SHARED MAP_PRIVATE MAP_ANONYMOUS MAP_ANON MAP_FIXED MAP_STACK MAP_POPULATE MAP_LOCKED MAP_HUGETLB MS_SYNC MS_ASYNC MS_INVALIDATE MADV_NORMAL MADV_RANDOM MADV_SEQUENTIAL MADV_WILLNEED MADV_DONTNEED",
  },
  ["sys/socket.h"] = {
    ty = "sockaddr sockaddr_storage socklen_t msghdr cmsghdr linger",
    fn = "socket bind listen accept accept4 connect send recv sendto recvfrom sendmsg recvmsg shutdown setsockopt getsockopt socketpair getpeername getsockname",
    mac = "AF_UNIX AF_INET AF_INET6 AF_UNSPEC AF_NETLINK SOCK_STREAM SOCK_DGRAM SOCK_RAW SOCK_SEQPACKET SOCK_CLOEXEC SOCK_NONBLOCK SOL_SOCKET SO_REUSEADDR SO_REUSEPORT SO_KEEPALIVE SO_BROADCAST SO_RCVBUF SO_SNDBUF SO_ERROR SO_RCVTIMEO SO_SNDTIMEO SO_LINGER SHUT_RD SHUT_WR SHUT_RDWR MSG_PEEK MSG_OOB MSG_DONTWAIT MSG_NOSIGNAL MSG_WAITALL SOMAXCONN",
  },
  ["netinet/in.h"] = {
    ty = "sockaddr_in sockaddr_in6 in_addr in6_addr in_port_t in_addr_t",
    fn = "htons htonl ntohs ntohl",
    mac = "INADDR_ANY INADDR_LOOPBACK INADDR_BROADCAST INADDR_NONE IN6ADDR_ANY_INIT IN6ADDR_LOOPBACK_INIT IPPROTO_TCP IPPROTO_UDP IPPROTO_IP IPPROTO_IPV6 IPPROTO_ICMP",
  },
  ["arpa/inet.h"] = {
    fn = "inet_ntop inet_pton inet_aton inet_ntoa inet_addr inet_network",
  },
  ["netdb.h"] = {
    ty = "addrinfo hostent servent",
    fn = "getaddrinfo freeaddrinfo gai_strerror getnameinfo gethostbyname gethostbyaddr getservbyname getservbyport",
    mac = "AI_PASSIVE AI_CANONNAME AI_NUMERICHOST AI_NUMERICSERV AI_V4MAPPED AI_ADDRCONFIG NI_NUMERICHOST NI_NUMERICSERV NI_NAMEREQD NI_NOFQDN EAI_AGAIN EAI_FAIL EAI_NONAME EAI_SYSTEM EAI_MEMORY",
  },
  ["sys/un.h"] = {
    ty = "sockaddr_un",
  },
  ["poll.h"] = {
    ty = "pollfd nfds_t",
    fn = "poll ppoll",
    mac = "POLLIN POLLOUT POLLERR POLLHUP POLLNVAL POLLPRI POLLRDHUP POLLWRNORM POLLRDNORM",
  },
  ["sys/epoll.h"] = {
    ty = "epoll_event epoll_data_t",
    fn = "epoll_create epoll_create1 epoll_ctl epoll_wait epoll_pwait",
    mac = "EPOLLIN EPOLLOUT EPOLLET EPOLLONESHOT EPOLLEXCLUSIVE EPOLLERR EPOLLHUP EPOLLRDHUP EPOLLPRI EPOLL_CTL_ADD EPOLL_CTL_MOD EPOLL_CTL_DEL EPOLL_CLOEXEC",
  },
  ["sys/select.h"] = {
    ty = "fd_set",
    fn = "select pselect",
    mac = "FD_SET FD_CLR FD_ISSET FD_ZERO FD_SETSIZE",
  },
  ["dirent.h"] = {
    ty = "DIR dirent",
    fn = "opendir fdopendir readdir readdir_r closedir rewinddir telldir seekdir scandir alphasort",
    mac = "DT_REG DT_DIR DT_LNK DT_FIFO DT_SOCK DT_CHR DT_BLK DT_UNKNOWN",
  },
  ["dlfcn.h"] = {
    fn = "dlopen dlsym dlclose dlerror dladdr",
    mac = "RTLD_LAZY RTLD_NOW RTLD_GLOBAL RTLD_LOCAL RTLD_NODELETE RTLD_NOLOAD RTLD_DEFAULT RTLD_NEXT",
  },
  ["semaphore.h"] = {
    ty = "sem_t",
    fn = "sem_init sem_destroy sem_wait sem_trywait sem_timedwait sem_post sem_open sem_close sem_unlink sem_getvalue",
  },
  ["stdatomic.h"] = {
    ty = "atomic_bool atomic_char atomic_int atomic_uint atomic_long atomic_size_t atomic_ptrdiff_t atomic_flag memory_order",
    fn = "atomic_load atomic_store atomic_exchange atomic_compare_exchange_strong atomic_compare_exchange_weak atomic_fetch_add atomic_fetch_sub atomic_fetch_or atomic_fetch_and atomic_fetch_xor atomic_thread_fence atomic_signal_fence atomic_flag_test_and_set atomic_flag_clear",
    mac = "memory_order_relaxed memory_order_consume memory_order_acquire memory_order_release memory_order_acq_rel memory_order_seq_cst ATOMIC_VAR_INIT ATOMIC_FLAG_INIT",
  },
  ["sys/uio.h"] = {
    ty = "iovec",
    fn = "readv writev preadv pwritev",
  },
  ["err.h"] = {
    fn = "err errx warn warnx verr verrx vwarn vwarnx",
  },
  ["syslog.h"] = {
    fn = "syslog vsyslog openlog closelog setlogmask",
    mac = "LOG_EMERG LOG_ALERT LOG_CRIT LOG_ERR LOG_WARNING LOG_NOTICE LOG_INFO LOG_DEBUG LOG_PID LOG_CONS LOG_NDELAY LOG_PERROR LOG_USER LOG_DAEMON LOG_LOCAL0",
  },
  ["termios.h"] = {
    ty = "termios cc_t speed_t tcflag_t",
    fn = "tcgetattr tcsetattr cfmakeraw cfsetispeed cfsetospeed cfgetispeed cfgetospeed tcsendbreak tcdrain tcflush tcflow",
    mac = "TCSANOW TCSADRAIN TCSAFLUSH ICANON ECHO ECHOE ECHOK ISIG IEXTEN OPOST CS8 CREAD CLOCAL VMIN VTIME",
  },
  ["sys/ioctl.h"] = {
    fn = "ioctl",
  },
  ["sys/time.h"] = {
    ty = "timeval timezone",
    fn = "gettimeofday settimeofday",
    mac = "timercmp timeradd timersub timerisset timerclear",
  },
  ["inttypes.h"] = {
    mac = "PRId8 PRId16 PRId32 PRId64 PRIu8 PRIu16 PRIu32 PRIu64 PRIx8 PRIx16 PRIx32 PRIx64 PRIxPTR SCNd32 SCNd64 SCNu64",
  },
  ["limits.h"] = {
    mac = "CHAR_BIT SCHAR_MIN SCHAR_MAX UCHAR_MAX CHAR_MIN CHAR_MAX SHRT_MIN SHRT_MAX USHRT_MAX INT_MIN INT_MAX UINT_MAX LONG_MIN LONG_MAX ULONG_MAX LLONG_MIN LLONG_MAX ULLONG_MAX PATH_MAX NAME_MAX",
  },
  ["locale.h"] = {
    fn = "setlocale localeconv",
    mac = "LC_ALL LC_COLLATE LC_CTYPE LC_MESSAGES LC_MONETARY LC_NUMERIC LC_TIME",
  },
  ["setjmp.h"] = {
    ty = "jmp_buf sigjmp_buf",
    fn = "setjmp longjmp sigsetjmp siglongjmp",
  },
  ["sys/eventfd.h"] = {
    fn = "eventfd eventfd_read eventfd_write",
    mac = "EFD_CLOEXEC EFD_NONBLOCK EFD_SEMAPHORE",
  },
  ["sys/timerfd.h"] = {
    fn = "timerfd_create timerfd_settime timerfd_gettime",
    mac = "TFD_CLOEXEC TFD_NONBLOCK TFD_TIMER_ABSTIME",
  },
}

local KIND_MAP = {
  fn = KIND.Function,
  ty = KIND.Struct,
  mac = KIND.Constant,
}

local INDEX = {}

local function index_header(header)
  local groups = HEADERS[header]
  if not groups then
    return
  end
  for group, names in pairs(groups) do
    local kind = KIND_MAP[group]
    for name in names:gmatch("%S+") do
      if not INDEX[name] then
        INDEX[name] = { header = header, kind = kind }
      end
    end
  end
end

-- First listed header wins when a symbol appears in more than one.
for _, header in ipairs({
  "stddef.h",
  "stdint.h",
  "stdio.h",
  "stdlib.h",
  "string.h",
  "pthread.h",
  "unistd.h",
  "sys/types.h",
  "fcntl.h",
  "sys/stat.h",
  "sys/socket.h",
  "netinet/in.h",
  "arpa/inet.h",
  "netdb.h",
}) do
  index_header(header)
end
for header, _ in pairs(HEADERS) do
  index_header(header)
end

local function header_pattern(header)
  return "^%s*#%s*include%s*[<\"]" .. header:gsub("([^%w])", "%%%1") .. "[>\"]"
end

function M.has_include(lines, header)
  local pat = header_pattern(header)
  for _, line in ipairs(lines) do
    if line:find(pat) then
      return true
    end
  end
  return false
end

function M.include_insert_row(lines)
  local last_inc
  for i, line in ipairs(lines) do
    if line:match("^%s*#%s*include") then
      last_inc = i
    end
  end
  if last_inc then
    return last_inc
  end

  local i = 1
  local function skip_noise()
    while i <= #lines do
      local line = lines[i]
      if
        line:match("^%s*$")
        or line:match("^%s*//")
        or line:match("^%s*/%*")
        or line:match("^%s*%*")
        or line:match("^%s*%*/")
      then
        i = i + 1
      else
        break
      end
    end
  end

  skip_noise()
  if lines[i] and lines[i]:match("^%s*#%s*pragma%s+once") then
    i = i + 1
    skip_noise()
    return i - 1
  end
  if
    lines[i]
    and (
      lines[i]:match("^%s*#%s*ifndef")
      or lines[i]:match("^%s*#%s*if%s+!%s*defined")
      or lines[i]:match("^%s*#%s*if%s+!defined")
    )
  then
    i = i + 1
    if lines[i] and lines[i]:match("^%s*#%s*define") then
      i = i + 1
    end
    skip_noise()
    return i - 1
  end
  return 0
end

function M.ensure_include(header, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if M.has_include(lines, header) then
    return false
  end
  local row = M.include_insert_row(lines)
  vim.api.nvim_buf_set_lines(bufnr, row, row, false, { "#include <" .. header .. ">" })
  return true
end

local function include_edit(header, bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if M.has_include(lines, header) then
    return {}
  end
  local row = M.include_insert_row(lines)
  return {
    {
      range = {
        start = { line = row, character = 0 },
        ["end"] = { line = row, character = 0 },
      },
      newText = "#include <" .. header .. ">\n",
    },
  }
end

function M.new()
  local source = {}

  function source:get_debug_name()
    return "c_headers"
  end

  function source:is_available()
    return vim.bo.filetype == "c"
  end

  function source:get_keyword_pattern()
    return [[\k\+]]
  end

  function source:get_position_encoding_kind()
    return "utf-8"
  end

  function source:complete(request, callback)
    local input = request.context.cursor_before_line:sub(request.offset)
    if #input < 2 then
      callback({ items = {} })
      return
    end

    local bufnr = request.context.bufnr or vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local included = {}
    local items = {}

    for name, meta in pairs(INDEX) do
      if name:sub(1, #input) == input then
        if included[meta.header] == nil then
          included[meta.header] = M.has_include(lines, meta.header)
        end
        if not included[meta.header] then
          local snip = SNIPS[name]
          local item = {
            label = name,
            kind = meta.kind,
            detail = "<" .. meta.header .. ">",
            documentation = {
              kind = "markdown",
              value = "```c\n#include <" .. meta.header .. ">\n```\nInserts this include if it is missing.",
            },
            data = { header = meta.header },
            additionalTextEdits = include_edit(meta.header, bufnr),
            dup = 0,
            sortText = "0" .. name,
          }
          if snip then
            item.insertText = snip
            item.insertTextFormat = 2
          end
          items[#items + 1] = item
        end
      end
    end

    callback({ items = items })
  end

  function source:execute(completion_item, callback)
    local header = completion_item.data and completion_item.data.header
    if header then
      M.ensure_include(header)
    end
    callback(completion_item)
  end

  return source
end

return M
