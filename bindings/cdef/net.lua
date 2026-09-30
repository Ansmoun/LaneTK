-- cdef de sockets Unix y fork. Lo que necesita el cliente de greetd
-- y los tests del protocolo.

local ffi = require("ffi")

ffi.cdef[[
typedef int socklen_t;
typedef unsigned short sa_family_t;
typedef unsigned int uint32_t;
typedef int pid_t;
typedef long ssize_t;

struct sockaddr {
    sa_family_t sa_family;
    char        sa_data[14];
};

struct sockaddr_un {
    sa_family_t sun_family;
    char        sun_path[108];
};

int socket(int domain, int type, int protocol);
int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
int listen(int sockfd, int backlog);
int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
ssize_t send(int sockfd, const void *buf, size_t len, int flags);
ssize_t recv(int sockfd, void *buf, size_t len, int flags);
int close(int fd);
int unlink(const char *path);

pid_t fork(void);
pid_t waitpid(pid_t pid, int *status, int options);
void _exit(int status);
unsigned int sleep(unsigned int seconds);
]]

return ffi
