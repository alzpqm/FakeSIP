#include <arpa/inet.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netinet/in.h>

#include "globvar.h"
#include "srcinfo.h"

#define INSERT_COUNT 600U

static int fail(const char *message)
{
    fprintf(stderr, "test_srcinfo: %s\n", message);
    fs_srcinfo_cleanup();
    return EXIT_FAILURE;
}

static void set_address(struct sockaddr_in *addr, unsigned int offset)
{
    memset(addr, 0, sizeof(*addr));
    addr->sin_family = AF_INET;
    addr->sin_addr.s_addr = htonl(0x0a000001U + offset);
}

int main(void)
{
    struct sockaddr_in addr;
    uint8_t hwaddr[8], result_hwaddr[8], ttl, expected_ttl;
    unsigned int i;

    g_ctx.logfp = stderr;
    memset(hwaddr, 0xa5, sizeof(hwaddr));
    set_address(&addr, 0);
    if (fs_srcinfo_put((const struct sockaddr *) &addr, 1, hwaddr) == 0) {
        return fail("put succeeded before cache setup");
    }
    if (fs_srcinfo_setup() < 0) {
        return fail("cache setup failed");
    }
    if (fs_srcinfo_get((const struct sockaddr *) &addr, &ttl,
                       result_hwaddr) != 1) {
        return fail("empty cache lookup did not report a miss");
    }

    for (i = 0; i < INSERT_COUNT; i++) {
        set_address(&addr, i);
        hwaddr[0] = (uint8_t) i;
        expected_ttl = (uint8_t) ((i % 254U) + 1U);
        if (fs_srcinfo_put((const struct sockaddr *) &addr, expected_ttl,
                           hwaddr) < 0) {
            return fail("cache insertion failed");
        }
    }

    set_address(&addr, INSERT_COUNT - 1U);
    expected_ttl = (uint8_t) (((INSERT_COUNT - 1U) % 254U) + 1U);
    if (fs_srcinfo_get((const struct sockaddr *) &addr, &ttl, result_hwaddr) !=
            0 ||
        ttl != expected_ttl ||
        result_hwaddr[0] != (uint8_t) (INSERT_COUNT - 1U)) {
        return fail("latest cache entry was not retained");
    }

    set_address(&addr, 0);
    if (fs_srcinfo_get((const struct sockaddr *) &addr, &ttl,
                       result_hwaddr) != 1) {
        return fail("oldest cache entry was not evicted");
    }
    if (fs_srcinfo_get(NULL, &ttl, result_hwaddr) != -1) {
        return fail("NULL cache lookup was accepted");
    }

    fs_srcinfo_cleanup();
    return EXIT_SUCCESS;
}
