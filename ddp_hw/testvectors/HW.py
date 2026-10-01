import helpers
from modularFunct import *
from curves import *
from math import *
import curves


# Here we implement the three functions 
# that we implement in the hardware lab sessions.

# The mongomery multiplication, and exponentiation
# follow the pseudo code given in the slides,
# so that if needed students can debug
# their code by printing the intermediate values.

def MultiPrecisionAddSub_379(A, B, addsub):
    # returns (A + B) mod 2^379 if   addsub == "add"
    #         (A - B) mod 2^379 else
    
    mask379  = 2**379 - 1
    mask380  = 2**380 - 1

    am     = A & mask379
    bm     = B & mask379

    if addsub == "add": 
        r = (am + bm) 
    else:
        r = (am - bm)
    
    return r & mask380

def MultiPrecisionAddSub_380(A, B, addsub):
    # returns (A + B) mod 2^380 if   addsub == "add"
    #         (A - B) mod 2^380 else
    
    mask380  = 2**380 - 1
    mask381  = 2**381 - 1

    am     = A & mask380
    bm     = B & mask380

    if addsub == "add": 
        r = (am + bm) 
    else:
        r = (am - bm)
    
    return r & mask381

def MontMul(A, B, M):
    # Returns (A*B*Modinv(R,M)) mod M
    
    regA  = A
    regB  = B
    regC  = 0
    regM  = M

    for i in range(0,377):
        
        if (regA % 2) == 0  : regC = regC
        else                : regC = MultiPrecisionAddSub_379(regC, regB, "add")
        #print(f"regC = {regC:0096x};\n")
        if (regC % 2) == 0  : regC = regC >> 1
        else                : regC = MultiPrecisionAddSub_379(regC, regM, "add") >> 1
        #print(f"regC = {regC:0096x};\n")
        regA = regA >> 1

    while regC >= regM:
        regC = MultiPrecisionAddSub_379(regC, regM, "sub")
    
    assert (regC == modularReduction(A*B*modularInverse(2**377,M),M))
    return regC



#######################################################################################################
#                           FASTER ALTERNATIVE BUT HARDER TO IMPLEMENT                                # 
#             THIS IS AN EXTRA TO DO WHEN YOU ARE DONE AND WANT TO MAKE IT FASTER                     #
#        ASK TEACHING ASSITENT FOR MORE INFO (ODD NUMBER OF BITS, PRECOMPUTE 3M AND 3B)               #
#                                 HARDER TO MEET TIMING CONSTRAINT !!!                                # 
#######################################################################################################
def MontMul_2bW(A, B, M):
    # Implements the multiplication with 2-bit windows
    # Returns (A*B*Modinv(R,M)) mod M
    
    WindowSize = 2
    b = 2**WindowSize
    
    regA  = A
    regB  = B
    regC  = 0
    regM  = M

    # reg2B = MultiPrecisionAddSub_379(regB, regB , "add")
    reg3B = MultiPrecisionAddSub_379(regB, regB<<1, "add")
    
    # reg2M = MultiPrecisionAddSub_379(regM, regM , "add")
    reg3M = MultiPrecisionAddSub_379(regM, regM<<1, "add")

    # Define a multiplexer function
    def ModMux(M, twoM, threeM, Csel, Msel):
        if   (Csel == 0 and Msel == 1) or (Csel == 0 and Msel == 3) : return 0;
        elif (Csel == 1 and Msel == 1) or (Csel == 3 and Msel == 3) : return threeM;
        elif (Csel == 2 and Msel == 1) or (Csel == 2 and Msel == 3) : return twoM;
        elif (Csel == 3 and Msel == 1) or (Csel == 1 and Msel == 3) : return M;

    for i in range(0, 376//WindowSize):
        
        # Decide the conditional addition with the lsb 2-bits of A
        if   (regA % b) == 0:  regC = regC
        elif (regA % b) == 1:  regC = MultiPrecisionAddSub_379(regC, regB   , "add")
        elif (regA % b) == 2:  regC = MultiPrecisionAddSub_379(regC, regB<<1, "add")
        elif (regA % b) == 3:  regC = MultiPrecisionAddSub_379(regC, reg3B  , "add")
        # Optionally, two additions can be performed to get rid of reg3B
        # elif (regA % b) == 3:  
        #     regC = MultiPrecisionAddSub_379(regC, regB   , "add")
        #     regC = MultiPrecisionAddSub_379(regC, regB<<1, "add")

        # Take the lsb 2-bits of C and M as select signals
        C_sel = (regC % b)
        M_sel = (regM % b)

        ModMuxOut = ModMux(regM, regM<<1,  reg3M, C_sel, M_sel)
        #print(f"regC = {regC:0097x};\n")
        regC = MultiPrecisionAddSub_379(regC, ModMuxOut, "add") // b
        # Optionally, two additions can be performed to get rid of reg3M
        #print(f"regC = {regC:0097x};\n")
        regA = regA >> WindowSize
        #print(f"regC = {regC:0097x};\n")
    #print(f"regC = {regC:0097x};\n")
    if (regA % 2) == 0  : regC = regC
    else                : regC = MultiPrecisionAddSub_379(regC, regB, "add")
    #print(f"regC = {regC:0096x};\n")
    if (regC % 2) == 0  : regC = regC >> 1
    else                : regC = MultiPrecisionAddSub_379(regC, regM, "add") >> 1
    #print(f"regC = {regC:0096x};\n")
    while regC >= regM:
        regC = MultiPrecisionAddSub_379(regC, regM, "sub")
    #print(f"regC = {regC:0096x};\n")
    assert (regC == modularReduction(A*B*modularInverse(2**377,M),M))
    return regC

def EC_addition(P,Q):
    R = 2**377
    k = curves.k

    #stage1
    A1 = modularReduction(P[1]-P[0],q)
    #print(f"\nA1       <= 377'h{A1:0096x};") 
    A2 = modularReduction(Q[1]-Q[0],q)
    #print(f"\nA2       <= 377'h{A2:0096x};") 
    A = MontMul(A1,A2,q) #A
    #print(f"A       <= 377'h{A:0096x};") 

    B1 = modularReduction(P[1]+P[0],q)
    #print(f"\nB1       <= 377'h{B1:0096x};") 
    B2 = modularReduction(Q[1]+Q[0],q)
    #print(f"\nB2       <= 377'h{B2:0096x};") 
    B = MontMul(B1,B2,q) #B
    #print(f"B       <= 377'h{B:0096x};")

    C1 = MontMul(P[3],Q[3],q)
    #print(f"C1       <= 377'h{C1:0096x};")
    C = MontMul(C1,(k*R)%q,q) #C
    # C = (C1*k)%q
    #print(f"C       <= 377'h{C:0096x};")

    D1 = MontMul(P[2],Q[2],q)
    #print(f"D1       <= 377'h{D1:0096x};")
    D = MontMul(D1,(2*R)%q,q) #D
    # D = (D1*2)%q
    #print(f"D       <= 377'h{D:0096x};")
    ###############################################################
    # DO YOU REALLY NEED TO DO A MULTIPLICATION ?                 #
    # EASY TO IMPLEMENT BUT YOU LOSE ON PERFORMANCE               #
    ###############################################################

    #stage2
    E = modularReduction(B-A,q) #E
    #print(f"E      <= 377'h{E:0096x};") 
    F = modularReduction(D-C,q)
    #print(f"F      <= 377'h{F:0096x};") 
    G = modularReduction(D+C,q)
    #print(f"G      <= 377'h{G:0096x};") 
    H = modularReduction(B+A,q)
    #print(f"H      <= 377'h{H:0096x};") 

    #stage3
    resX = MontMul(E,F,q)
    #print(f"resX    <= 377'h{resX:0096x};")
    resY = MontMul(G,H,q)
    #print(f"resY    <= 377'h{resY:0096x};")
    resZ = MontMul(F,G,q)
    #print(f"resZ    <= 377'h{resZ:0096x};")
    resT = MontMul(E,H,q)
    #print(f"resZ    <= 377'h{resZ:0096x};")
    #no need to go out of montgomery
    return(resX,resY,resZ,resT)

def EC_scalar_mult(s, P):
    """
    :param s: Integer scalar (e.g., 253-bit)
    :param P: EC point (e.g., in affine or extended coordinates)
    :return: EC point corresponding to s * P
    """
    R = (0, 1, 1, 0)  # Identity element in extended coordinates (adjust if using affine or projective)
    bin_s = bin(s)[2:]  # Convert scalar to binary string without '0b' prefix
    for bit in bin_s:
        R = EC_addition(R, R)  # Point doubling
        if bit == '1':
            R = EC_addition(R, P)  # Point addition
    return R


def ecdsa_sign(p, m):
    while True:
        k = helpers.getRandomInt(253) % curves.groupOrder
        if k == 0:
            continue
        k_inv = helpers.Modinv(k, curves.groupOrder)
        if k_inv != -1:
            break
    G = helpers.affineToExtended(curves.G)
    K = EC_scalar_mult(k, G)
    K_affine = helpers.extendedToAffine(K)
    r = K_affine[0] % curves.groupOrder
    s = (k_inv * ((m + ((p * r)%curves.groupOrder))%curves.groupOrder)) % curves.groupOrder
    return (K, s)


def ecdsa_verify(m, signature, P):    #m message, P public key 
    K, s = signature
    K_affine = helpers.extendedToAffine(K)
    r = K_affine[0] % curves.groupOrder

    G = helpers.affineToExtended(curves.G)

    Q = EC_scalar_mult(m, G)
    L = EC_scalar_mult(r, P)
    C = EC_addition(Q, L)
    C_prime = EC_scalar_mult(s, K)
    valid  = (C[0]*C_prime[2])%curves.q  == (C[2]*C_prime[0])%curves.q
    return  valid, C, C_prime, r

