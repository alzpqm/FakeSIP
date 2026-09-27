#define _GNU_SOURCE
#include <arpa/inet.h>
#include <assert.h>
#include <netinet/ip.h>
#include <netinet/ip6.h>
#include <netinet/udp.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "globvar.h"
#include "ipv4pkt.h"
#include "ipv6pkt.h"

static void parse6(int next_header)
{
    uint8_t bytes[64] __attribute__((aligned)) = {0};
    struct ip6_hdr *ip = (void *) bytes;
    struct sockaddr_storage source, destination;
    struct udphdr *udp;
    int payload_length = -1, result;
    uint8_t ttl;
    size_t offset = sizeof(*ip);
    ip->ip6_vfc = 0x60;
    ip->ip6_nxt = next_header;
    ip->ip6_hlim = 64;
    if (next_header != IPPROTO_UDP) {
        bytes[offset] = IPPROTO_UDP;
        bytes[offset + 1] = 0;
        bytes[offset + 2] = 1;
        bytes[offset + 3] = 4;
        offset += 8;
    }
    udp = (void *) (bytes + offset);
    udp->source = htons(40000);
    udp->dest = htons(443);
    udp->len = htons(10);
    bytes[offset + 8] = 'O';
    bytes[offset + 9] = 'K';
    ip->ip6_plen = htons(offset + 10 - sizeof(*ip));
    result = fs_pkt6_parse(bytes, offset + 10, (void *) &source,
                           (void *) &destination, &ttl, &udp, &payload_length);
    printf("parser next_header=%d result=%d payload_length=%d\n",
           next_header, result, payload_length);
    assert(result == (next_header == IPPROTO_UDP ? 0 : -1));
}

int main(void)
{
    uint8_t bytes[128] __attribute__((aligned)) = {0};
    uint8_t payload[] = {1, 2, 3};
    struct sockaddr_in s4 = {.sin_family = AF_INET};
    struct sockaddr_in d4 = {.sin_family = AF_INET};
    struct sockaddr_in6 s6 = {.sin6_family = AF_INET6};
    struct sockaddr_in6 d6 = {.sin6_family = AF_INET6};
    struct udphdr *udp;
    int length;
    g_ctx.logfp = stderr;
    inet_pton(AF_INET, "198.51.100.1", &s4.sin_addr);
    inet_pton(AF_INET, "198.51.100.2", &d4.sin_addr);
    inet_pton(AF_INET6, "2001:db8::1", &s6.sin6_addr);
    inet_pton(AF_INET6, "2001:db8::2", &d6.sin6_addr);
    length = fs_pkt4_make(bytes, sizeof(bytes), (void *) &s4, (void *) &d4,
                          3, htons(40000), htons(443), payload, sizeof(payload));
    assert(length > 0);
    udp = (void *) (bytes + sizeof(struct iphdr));
    printf("builder IPv4 wire_udp_length=%u expected=11\n", ntohs(udp->len));
    length = fs_pkt6_make(bytes, sizeof(bytes), (void *) &s6, (void *) &d6,
                          3, htons(40000), htons(443), payload, sizeof(payload));
    assert(length > 0);
    udp = (void *) (bytes + sizeof(struct ip6_hdr));
    printf("builder IPv6 wire_udp_length=%u expected=11\n", ntohs(udp->len));
    parse6(IPPROTO_UDP);
    parse6(IPPROTO_DSTOPTS);
    parse6(IPPROTO_HOPOPTS);
    return 0;
}
