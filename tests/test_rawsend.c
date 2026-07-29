#define _GNU_SOURCE
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>

static ssize_t test_sendto(int fd, const void *buf, size_t len, int flags,
                           const struct sockaddr *addr, socklen_t addrlen);

#define sendto test_sendto
#include "../src/rawsend.c"
#undef sendto

static ssize_t sendto_result;
static int sendto_error;
static int sendto_calls;

static ssize_t test_sendto(int fd, const void *buf, size_t len, int flags,
                           const struct sockaddr *addr, socklen_t addrlen)
{
    (void) fd;
    (void) buf;
    (void) len;
    (void) flags;
    (void) addr;
    (void) addrlen;

    sendto_calls++;
    errno = sendto_error;
    return sendto_result;
}

static int fail(const char *message)
{
    fprintf(stderr, "test_rawsend: %s\n", message);
    return EXIT_FAILURE;
}

int main(void)
{
    uint8_t packet[32] = {0};
    struct sockaddr_in destination;
    struct sockaddr_ll link;

    memset(&destination, 0, sizeof(destination));
    memset(&link, 0, sizeof(link));
    destination.sin_family = AF_INET;
    link.sll_ifindex = 7;

    g_ctx.logfp = stderr;
    sock4fd = 123;
    sock4if = link.sll_ifindex;

    sendto_result = -1;
    sendto_error = EPERM;
    if (sendto_snat(&link, (struct sockaddr *) &destination, packet,
                    sizeof(packet)) != -1 || sendto_calls != 1) {
        return fail("EPERM must be reported as a fake-send failure");
    }

    sendto_result = sizeof(packet);
    sendto_error = 0;
    if (sendto_snat(&link, (struct sockaddr *) &destination, packet,
                    sizeof(packet)) != 0 || sendto_calls != 2) {
        return fail("a successful sendto must remain successful");
    }

    return EXIT_SUCCESS;
}
