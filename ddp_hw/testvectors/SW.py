import helpers
from modularFunct import *
from curves import *
from math import *
import curves


# Here we don't implement the functions 
# as the students should implement them
# in their software lab sessions

def MontMul(A, B, M):
    # Returns (A*B*Modinv(R,M)) mod M
    R = 2**377
    return (A*B*helpers.Modinv(R,M)) % M

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
    G = helpers.affineToExtended(curves.Gedwres)
    K = EC_scalar_mult(k, G)
    K_affine = helpers.extendedToAffine(K)
    r = K_affine[0] % curves.groupOrder
    s = (k_inv * ((m + ((p * r)%curves.groupOrder))%curves.groupOrder)) % curves.groupOrder
    return (K, s)


def ecdsa_verify(m, signature, P):    #m message, P public key 
    K, s = signature
    K_affine = helpers.extendedToAffine(K)
    r = K_affine[0] % curves.groupOrder

    G = helpers.affineToExtended(curves.Gedwres)

    Q = EC_scalar_mult(m, G)
    L = EC_scalar_mult(r, P)
    C = EC_addition(Q, L)
    # print(f"C.x          <= 377'h{(C[0]):96x};")
    # print(f"C.y          <= 377'h{(C[1]):96x};")
    # print(f"C.z          <= 377'h{(C[2]):96x};")
    # print(f"C.t          <= 377'h{(C[3]):96x};")
    C_prime = EC_scalar_mult(s, K)
    valid  = (C[0]*C_prime[2])%curves.q  == (C[2]*C_prime[0])%curves.q
    return  valid, C, C_prime, r




def EC_addition_proj(P,Q):
    R = 2**377
    #stage1
    X1mX2 = MontMul(P[0],Q[0],q)
    #print(f"\nX1mX2       <= 381'h{X1mX2:0096x};") 
    Y1mY2 = MontMul(P[1],Q[1],q)
    #print(f"Y1mY2       <= 381'h{Y1mY2:0096x};") 
    Z1mZ2 = MontMul(P[2],Q[2],q)
    #print(f"Z1mZ2       <= 381'h{Z1mZ2:0096x};") 
    X1plY1 = modularReduction(P[0]+P[1],q)
    #print(f"X1plY1      <= 381'h{X1plY1:0096x};") 
    X2plY2 = modularReduction(Q[0]+Q[1],q)
    #print(f"X2plY2      <= 381'h{X2plY2:0096x};") 
    X1plZ1 = modularReduction(P[0]+P[2],q)
    #print(f"X1plZ1      <= 381'h{X1plZ1:0096x};") 
    X2plZ2 = modularReduction(Q[0]+Q[2],q)
    #print(f"X2plZ2      <= 381'h{X2plZ2:0096x};") 
    Y1plZ1 = modularReduction(P[1]+P[2],q)
    #print(f"Y1plZ1      <= 381'h{Y1plZ1:0096x};") 
    Y2plZ2 = modularReduction(Q[1]+Q[2],q)
    #print(f"Y2plZ2      <= 381'h{Y2plZ2:0096x};") 
    #stage2 
    X1X2plY1Y2 = modularReduction(X1mX2+Y1mY2,q)
    #print(f"X1X2plY1Y2    <= 381'h{X1X2plY1Y2:0096x};") 
    X1X2plZ1Z2 = modularReduction(X1mX2+Z1mZ2,q)
    #print(f"X1X2plZ1Z2    <= 381'h{X1X2plZ1Z2:0096x};") 
    Y1Y2plZ1Z2 = modularReduction(Y1mY2+Z1mZ2,q)
    #print(f"Y1Y2plZ1Z2    <= 381'h{Y1Y2plZ1Z2:0096x};") 
    X1plY1X2plY2 = MontMul(X1plY1,X2plY2,q)
    #print(f"X1plY1X2plY2    <= 381'h{X1plY1X2plY2:0096x};") 
    X1plZ1X2plZ2 = MontMul(X1plZ1,X2plZ2,q)
    #print(f"X1plZ1X2plZ2    <= 381'h{X1plZ1X2plZ2:0096x};")
    Y1plZ1Y2plZ2 = MontMul(Y1plZ1,Y2plZ2,q)
    #print(f"Y1plZ1Y2plZ2    <= 381'h{Y1plZ1Y2plZ2:0096x};")
    #stage3
    #print(f"R*12%q       <= 381'h{R*12%q:0096x};")
    Z1Z2x12 = MontMul(Z1mZ2,R*3%q,q) #12
    #print(f"Z1Z2x12    <= 381'h{Z1Z2x12:0096x};")
    sub1 = modularReduction(X1plY1X2plY2-X1X2plY1Y2,q)
    #print(f"sub1    <= 381'h{sub1:0096x};")
    sub2 = modularReduction(X1plZ1X2plZ2-X1X2plZ1Z2,q)
    #print(f"sub2    <= 381'h{sub2:0096x};")
    sub3 = modularReduction(Y1plZ1Y2plZ2-Y1Y2plZ1Z2,q)
    #print(f"sub3    <= 381'h{sub3:0096x};")
    #stage4
    #print(f"R*3%q    <= 381'h{R*3%q:0096x};")
    X1X2x3 = MontMul(X1mX2,R*3%q, q) #3
    #print(f"X1X2x3    <= 381'h{X1X2x3:0096x};")
    addStage2 = modularReduction(Y1mY2+Z1Z2x12,q)
    #print(f"addStage2    <= 381'h{addStage2:0096x};")
    subStage2 = modularReduction(Y1mY2-Z1Z2x12,q)
    #print(f"subStage2    <= 381'h{subStage2:0096x};")
    sub2x12 = MontMul(sub2,R*3%q,q) #12
    ###############################################################
    # DO YOU REALLY NEED TO DO A MULTIPLICATION?
    # EASY TO IMPLEMENT BUT YOU LOSE ON PERFORMANCE
    ###############################################################
    #print(f"sub2x12    <= 381'h{sub2x12:0096x};")
    #stage5
    temp1 = MontMul(subStage2,sub1,q)
    #print(f"temp1    <= 381'h{temp1:0096x};")
    temp2 = MontMul(sub2x12,sub3,q)
    #print(f"temp2    <= 381'h{temp2:0096x};")
    temp3 = MontMul(addStage2,subStage2,q)
    #print(f"temp3    <= 381'h{temp3:0096x};")
    temp4 = MontMul(X1X2x3,sub2x12,q)
    #print(f"temp4    <= 381'h{temp4:0096x};")
    temp5 = MontMul(addStage2,sub3,q)
    #print(f"temp5    <= 381'h{temp5:0096x};")
    temp6 = MontMul(X1X2x3,sub1,q)
    #print(f"temp6    <= 381'h{temp6:0096x};")
    #stage6
    resX = modularReduction(temp1-temp2,q)
    #print(f"resX    <= 381'h{resX:0096x};")
    resY = modularReduction(temp3+temp4,q)
    #print(f"resY    <= 381'h{resY:0096x};")
    resZ = modularReduction(temp5+temp6,q)
    #print(f"resZ    <= 381'h{resZ:0096x};")
    #no need to go out of montgomery
    return(resX,resY,resZ)