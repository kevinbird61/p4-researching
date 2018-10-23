#ifndef __HASH_FUNC__
#define __HASH_FUNC__

#include "headers.p4"

/**
    Propose in the paper, 
    We use hash functions of the type
        hi = (ai·x +bi)%p 
    where the chosen ai,bi are co-prime 
    to ensure independence of the hash 
    functions across stages.

    (Each stage will use different pair of 
    co-prime number into this hash function.)
 */
control a_b_hash(
    in bit<32> co_prime_a,
    in bit<32> co_prime_b,
    in bit<32> src_ip,
    out bit<32> result
){
    apply {
        result = (bit<32>)(co_prime_a*src_ip + co_prime_b);
    }
}

/**
    5-tuple hash function
*/
control five_tuple(
    in bit<32> src_ip,
    in bit<32> dst_ip,
    in bit<8> protocol,
    in bit<16> src_port,
    in bit<16> dst_port,
    out bit<32> result
){

    apply {
        // calc 5-tuple from:
        // - ipv4 src
        // - ipv4 dst
        // - src port (tcp/udp)
        // - dst port (tcp/udp)
        // - protocol (ip)
        result = (bit<32>)(
            (src_ip * 59) ^
            (dst_ip) ^
            ((bit<32>)src_port << 16) ^
            ((bit<32>)dst_port) ^
            ((bit<32>)protocol));
    }
    
}

#endif