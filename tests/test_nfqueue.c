#define _GNU_SOURCE

#include <arpa/inet.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../src/nfqueue.c"

static int fail(const char *message)
{
    fprintf(stderr, "test_nfqueue: %s\n", message);
    return EXIT_FAILURE;
}

int main(void)
{
    struct nfqnl_msg_packet_hw packet_hw;
    struct sockaddr_ll link;
    size_t i;

    g_ctx.logfp = stderr;
    memset(&packet_hw, 0, sizeof(packet_hw));
    memset(&link, 0xa5, sizeof(link));
    packet_hw.hw_addrlen = htons(6);
    for (i = 0; i < sizeof(packet_hw.hw_addr); i++) {
        packet_hw.hw_addr[i] = (uint8_t) (i + 1);
    }

    if (copy_packet_hwaddr(&link, &packet_hw) < 0 || link.sll_halen != 6 ||
        memcmp(link.sll_addr, packet_hw.hw_addr, 6) != 0 ||
        link.sll_addr[6] != 0 || link.sll_addr[7] != 0) {
        return fail("NFQUEUE hardware address length was not preserved");
    }

    memset(&link, 0xa5, sizeof(link));
    if (copy_packet_hwaddr(&link, NULL) < 0 || link.sll_halen != 0) {
        return fail("missing NFQUEUE hardware address was not accepted");
    }
    for (i = 0; i < sizeof(link.sll_addr); i++) {
        if (link.sll_addr[i] != 0) {
            return fail("missing hardware address left stale bytes");
        }
    }

    packet_hw.hw_addrlen = htons(sizeof(packet_hw.hw_addr) + 1U);
    if (copy_packet_hwaddr(&link, &packet_hw) == 0) {
        return fail("oversized NFQUEUE hardware address was accepted");
    }

    return EXIT_SUCCESS;
}
