#define _GNU_SOURCE

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "globvar.h"
#include "payload.h"

#define CUSTOM_PAYLOAD_SIZE 1200U

static int fail(const char *message)
{
    fprintf(stderr, "test_payload: %s\n", message);
    return EXIT_FAILURE;
}

static int write_all(int fd, const uint8_t *data, size_t len)
{
    size_t written;
    ssize_t result;

    written = 0;
    while (written < len) {
        result = write(fd, data + written, len - written);
        if (result <= 0) {
            return -1;
        }
        written += (size_t) result;
    }
    return 0;
}

int main(void)
{
    struct payload_info sip_payloads[] = {
        {FS_PAYLOAD_SIP, NULL},
        {FS_PAYLOAD_END, NULL},
    };
    struct payload_info custom_payloads[] = {
        {FS_PAYLOAD_CUSTOM, NULL},
        {FS_PAYLOAD_END, NULL},
    };
    uint8_t expected[CUSTOM_PAYLOAD_SIZE], *payload;
    size_t payload_len;
    char path[] = "/tmp/fakesip-payload-test.XXXXXX";
    int fd;

    g_ctx.logfp = stderr;
    payload = (uint8_t *) 1;
    payload_len = 1;
    if (th_payload_get(&payload, &payload_len) == 0 || payload != NULL ||
        payload_len != 0) {
        return fail("empty payload list was accepted");
    }

    g_ctx.plinfo = sip_payloads;
    if (fs_payload_setup() < 0 ||
        th_payload_get(&payload, &payload_len) < 0 || !payload || !payload_len) {
        return fail("default SIP payload setup failed");
    }
    fs_payload_cleanup();
    if (th_payload_get(&payload, &payload_len) == 0) {
        return fail("payload remained available after cleanup");
    }

    memset(expected, 0x5a, sizeof(expected));
    fd = mkstemp(path);
    if (fd < 0 || write_all(fd, expected, sizeof(expected)) < 0 ||
        close(fd) < 0) {
        if (fd >= 0) {
            close(fd);
        }
        unlink(path);
        return fail("could not create exact-size payload fixture");
    }

    custom_payloads[0].info = path;
    g_ctx.plinfo = custom_payloads;
    if (fs_payload_setup() < 0 ||
        th_payload_get(&payload, &payload_len) < 0 ||
        payload_len != sizeof(expected) ||
        memcmp(payload, expected, sizeof(expected)) != 0) {
        unlink(path);
        return fail("exact-size custom payload was rejected or corrupted");
    }

    fs_payload_cleanup();
    unlink(path);
    return EXIT_SUCCESS;
}
