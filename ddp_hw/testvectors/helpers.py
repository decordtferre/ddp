import binascii
import random
import math


from curves import *
from modularFunct import *

# x << 1 #multiply by two
# x >> 1 #divide by two

import sys
sys.setrecursionlimit(1500)

def setSeed(seedInput):
    random.seed(seedInput)

def getModulus(bits):
    n = random.randrange(2**(bits-1), 2**bits-1)
    # print gcd(n, 2**bits)
    while not gcd(n, 2**bits) == 1:
        n = random.randrange(2**(bits-1), 2**bits-1)
    mod = n
    return n

def getRandomInt(bits):
    return random.randrange(2**(bits-1), 2**bits-1)

def egcd(a, b):
    if a == 0:
        return (b, 0, 1)
    else:
        g, y, x = egcd(b % a, a)
        return (g, x - (b // a) * y, y)

def Modinv(a, m):
    g, x, y = egcd(a, m)
    if g != 1:
        return -1
    else:
        return x % m

def WriteConstants(number, size):

    out = ''

    for i in range(size):
        out += '0x{:08x}'.format(number & 0xFFFFFFFF)
        number >>= 32
        out += ', ' if i<(size - 1) else ''
    return out
    
    # print (out)

def CreateConstants(seed, message, K, s, modulus, r, public_key, C, C_prime, G):
    target = open("../sw_project/src/sw/testvector.c", 'w')
    target.truncate()      

    R    = 2**377
    R_N  = R % modulus
    R2_N = (R*R) % modulus

    target.write(
    "#include <stdint.h>                                              \n" +
    "#include <stdalign.h>                                            \n" +
    "                                                                 \n" +
    "// This file's content is created by the testvector generator    \n" +
    "// python script for seed = " + str(seed) + "                    \n" +   
    "//                                                               \n" +    
    "// The variables are defined for the ECDSA verifivation.         \n" +   
    "// And they are assigned by the script for the generated         \n" +   
    "// testvector. Do not create a new variable in this file.        \n" +
    "//                                                               \n" +
    "// When you are submitting your results, be careful to verify    \n" +
    "// the test vectors created for seeds from 2026.1, to 2026.5     \n" +
    "// To create them, run your script as:                           \n" +
    "//   $ python testvectors.py ECDSA_verify 2026.1                 \n" +
    "                                                                 \n" +
    "// modulus                                                       \n" +
    "alignas(128) uint32_t modulus[32]   = {" + WriteConstants(modulus,32) + "};       \n" +
    "                                                                                       \n" +
    "// message                                                                             \n" +
    "alignas(128) uint32_t message[32]   = {" + WriteConstants(message,32) + "};       \n" +
    "                                                                                       \n" +
    "// Signature K and s                                                                   \n" +
    "alignas(128) uint32_t K_X[32]       = {" + WriteConstants(K[0],32) + "};          \n" +
    "alignas(128) uint32_t K_Y[32]       = {" + WriteConstants(K[1],32) + "};          \n" +
    "alignas(128) uint32_t K_Z[32]       = {" + WriteConstants(K[2],32) + "};          \n" +
    "alignas(128) uint32_t K_T[32]       = {" + WriteConstants(K[3],32) + "};          \n" +
    "alignas(128) uint32_t s[32]         = {" + WriteConstants(s,32) + "};             \n" +
    "                                                                                       \n" +
    "// Public key                                                                          \n" +
    "alignas(128) uint32_t Public_X[32]  = {" + WriteConstants(public_key[0],32) + "}; \n" +
    "alignas(128) uint32_t Public_Y[32]  = {" + WriteConstants(public_key[1],32) + "}; \n" +
    "alignas(128) uint32_t Public_Z[32]  = {" + WriteConstants(public_key[2],32) + "}; \n" +
    "alignas(128) uint32_t Public_T[32]  = {" + WriteConstants(public_key[3],32) + "}; \n" +
    "                                                                                       \n" +
    "// OUTPUT VALUES final                                                                 \n" +
    "alignas(128) uint32_t C_X[32]       = {" + WriteConstants(C[0],32) + "};          \n" +
    "alignas(128) uint32_t C_Y[32]       = {" + WriteConstants(C[1],32) + "};          \n" +
    "alignas(128) uint32_t C_Z[32]       = {" + WriteConstants(C[2],32) + "};          \n" +
    "alignas(128) uint32_t C_T[32]       = {" + WriteConstants(C[3],32) + "};          \n" +
    "alignas(128) uint32_t C_Prime_X[32] = {" + WriteConstants(C_prime[0],32) + "};    \n" +
    "alignas(128) uint32_t C_Prime_Y[32] = {" + WriteConstants(C_prime[1],32) + "};    \n" +
    "alignas(128) uint32_t C_Prime_Z[32] = {" + WriteConstants(C_prime[2],32) + "};    \n" +
    "alignas(128) uint32_t C_Prime_T[32] = {" + WriteConstants(C_prime[3],32) + "};    \n" +
    "                                                                                       \n" +
    "//START POINT ON CURVE                                                                                       \n" +
    "alignas(128) uint32_t G_X[32]       = {" + WriteConstants(G[0],32) + "};          \n" +
    "alignas(128) uint32_t G_Y[32]       = {" + WriteConstants(G[1],32) + "};          \n" +
    "alignas(128) uint32_t G_Z[32]       = {" + WriteConstants(G[2],32) + "};          \n" +
    "alignas(128) uint32_t G_T[32]       = {" + WriteConstants(G[3],32) + "};          \n" +
    "                                                                                       \n" +
    "alignas(128) uint32_t K_X_Modn[32]  = {" + WriteConstants(r,32) + "};             \n" +
    "                                                                                       \n" +
    "// R mod N, and R^2 mod N, (R = 2^377)                                                 \n" +
    "alignas(128) uint32_t R_N[32]     = {" + WriteConstants(R_N,32) + "};            \n" +
    "alignas(128) uint32_t R2_N[32]    = {" + WriteConstants(R2_N,32) + "};            \n" )

    target.close()

def affineToExtended(P):
    if P == (0,0):
        return (0,1,1,0) #point at inf
    return (P[0], P[1], 1, modularReduction(P[0]*P[1], q))

def extendedToAffine(P):
    if P == (0,1,1,0):
        return (0,0) #point at inf
    assert(P[3] == modularReduction(P[0]*P[1]*modularInverse(P[2]),q))
    return (modularReduction(P[0]*modularInverse(P[2]),q), 
            modularReduction(P[1]*modularInverse(P[2]),q))

def affineToProjective(P):
    if P == (0,0):
        return (0,1,0) #point at inf
    return (P[0], P[1], 1)

def projectiveToAffine(P):
    if P == (0,1,0):
        return (0,0) #point at inf
    return (modularReduction(P[0]*modularInverse(P[2]),q), 
            modularReduction(P[1]*modularInverse(P[2]),q))

def weierstrassToEdwards(P):
    if P == (0,0):
        return (0,0)
    return (modularReduction(rescale*(P[0]+1)*modularInverse(P[1],q),q),
            modularReduction((P[0]+1+A)*modularInverse((P[0]+1-A),q),q))