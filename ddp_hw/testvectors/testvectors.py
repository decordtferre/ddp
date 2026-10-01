import helpers
import HW
import SW
import curves
import sys

operation = 0
seed = "random"

print ("TEST VECTOR GENERATOR FOR DDP\n")

if len(sys.argv) in [2,3,4]:
  if str(sys.argv[1]) == "adder":           operation = 1
  if str(sys.argv[1]) == "subtractor":      operation = 2
  if str(sys.argv[1]) == "modadder":        operation = 3
  if str(sys.argv[1]) == "modsubtractor":   operation = 4  
  if str(sys.argv[1]) == "multiplication":  operation = 5
  if str(sys.argv[1]) == "EC_add":          operation = 6
  if str(sys.argv[1]) == "EC_mult":         operation = 7
  if str(sys.argv[1]) == "ECDSA_verify":    operation = 8


if len(sys.argv) in [3,4]:
  print ("Seed is: ", sys.argv[2], "\n")
  seed = sys.argv[2]
  helpers.setSeed(sys.argv[2])

if len(sys.argv) == 4:
  if (sys.argv[3].upper() == "NOWRITE"):
    print ("NOT WRITING TO TESTVECTOR.C FILE \n")

#####################################################

if operation == 0:
  print ("You should use this script by passing an argument like:")
  print (" $ python testvectors.py adder")
  print (" $ python testvectors.py subtractor")
  print (" $ python testvectors.py modadder")
  print (" $ python testvectors.py modsubtractor")
  print (" $ python testvectors.py multiplication")
  print (" $ python testvectors.py EC_add")
  print (" $ python testvectors.py EC_mult")
  print (" $ python testvectors.py ECDSA_verify")
  print ("")
  print ("You can also set a seed for randomness to work")
  print ("with the same testvectors at each execution:")
  print (" $ python testvectors.py ECDSA_verify 2026")
  print ("")
  print ("To NOT write to testvector.c file automatically: ")
  print (" $ python testvectors.py ECDSA_verify 2026 nowrite")
  print ("")

#####################################################

if operation == 1:
  print ("Test Vector for Adder\n")

  A = helpers.getRandomInt(380)
  B = helpers.getRandomInt(380)
  C = HW.MultiPrecisionAddSub_380(A,B,"add")

  print ("A                = ", hex(A))           # 380-bits
  print ("B                = ", hex(B))           # 380-bits
  print ("A + B            = ", hex(C))           # 380-bits

#####################################################

if operation == 2:
  print ("Test Vector for Subtractor\n")

  A = helpers.getRandomInt(380)
  B = helpers.getRandomInt(380)
  C = HW.MultiPrecisionAddSub_380(A,B,"subtract")

  print ("A                = ", hex(A))           # 380-bits
  print ("B                = ", hex(B))           # 380-bits
  print ("A - B            = ", hex(C))           # 381-bits

#####################################################

if operation == 3:
  print ("Test Vector for Modular Adder\n")

  M = helpers.getModulus(377)
  A = helpers.getRandomInt(377) % M
  B = helpers.getRandomInt(377) % M
  C = (A + B) % M

  print ("A                = ", hex(A))           # 377-bits
  print ("B                = ", hex(B))           # 377-bits
  print ("M                = ", hex(M))           # 377-bits
  print ("A + B            = ", hex(C))           # 377-bits

#####################################################

if operation == 4:
  print ("Test Vector for Modular Subtractor\n")

  M = helpers.getModulus(377)
  A = helpers.getRandomInt(377) % M
  B = helpers.getRandomInt(377) % M
  C = (A - B) % M

  print ("A                = ", hex(A))           # 377-bits
  print ("B                = ", hex(B))           # 377-bits
  print ("M                = ", hex(M))           # 377-bits
  print ("A - B            = ", hex(C))           # 377-bits

#####################################################

if operation == 5:

  print ("Test Vector for Montgomery Multiplication\n")

  M = helpers.getModulus(377)
  A = helpers.getRandomInt(377) % M
  B = helpers.getRandomInt(377) % M

  C = HW.MontMul(A, B, M)
  D = SW.MontMul(A, B, M)

  e = (C - D)
  print(f"in_a        <= 377'h{A:0095x};")  
  print(f"in_b        <= 377'h{B:0095x};")  
  print(f"in_m        <= 377'h{M:0095x};")  
  print(f"expected HW <= 377'h{C:0095x};")  # Expected result
  print(f"expected SW <= 377'h{D:0095x};")  # Expected result

#####################################################

if operation == 6:

  print ("Test Vector for Elliptic Curve Addition\n")
  G = helpers.affineToExtended(curves.Gedwres)  # Use G from curves module

  #Making 2 points that lie on the elliptic curve
  s1 = helpers.getRandomInt(253) % curves.groupOrder
  s2 = helpers.getRandomInt(253) % curves.groupOrder
  Point1 = SW.EC_scalar_mult(s1,G)
  Point2 = SW.EC_scalar_mult(s2,G)

  Out_SW = SW.EC_addition(Point1, Point2)

  #HARDWARE (SLOWER BUT SHOULD BE EXACTLY THE SAME)
  Point1HW = HW.EC_scalar_mult(s1,G)
  Point2HW = HW.EC_scalar_mult(s2,G) 
  Out_HW = HW.EC_addition(Point1HW, Point2HW)
  e0 = Out_SW[0] - Out_HW[0]
  e1 = Out_SW[1] - Out_HW[1]
  e2 = Out_SW[2] - Out_HW[2]
  e3 = Out_SW[3] - Out_HW[3]
  assert(e0 == 0)
  assert(e1 == 0)
  assert(e2 == 0)
  assert(e3 == 0)


  print(f"inM          <= 377'h{curves.q:0095x};\n")
  print(f"inX1         <= 377'h{Point1[0]:0095x};")  
  print(f"inY1         <= 377'h{Point1[1]:0095x};")
  print(f"inZ1         <= 377'h{Point1[2]:0095x};")
  print(f"inT1         <= 377'h{Point1[3]:0095x};\n")
  print(f"inX2         <= 377'h{Point2[0]:0095x};")  
  print(f"inY2         <= 377'h{Point2[1]:0095x};")
  print(f"inZ2         <= 377'h{Point2[2]:0095x};")
  print(f"inT2         <= 377'h{Point2[3]:0095x};\n")
  print(f"outX         <= 377'h{Out_SW[0]:0095x};")  
  print(f"outY         <= 377'h{Out_SW[1]:0095x};")
  print(f"outZ         <= 377'h{Out_SW[2]:0095x};")
  print(f"outT         <= 377'h{Out_SW[3]:0095x};")
  
#####################################################

if operation == 7:

  print ("Test Vector for Elliptic Curve Scalar Multiplication\n")
  G = helpers.affineToExtended(curves.Gedwres)  # Use G from curves module
  #Making new points that lie on the elliptic curve
  s1 = helpers.getRandomInt(253) % curves.groupOrder
  Point = SW.EC_scalar_mult(s1,G)

  s2 = helpers.getRandomInt(253) % curves.groupOrder
  
  Out_SW = SW.EC_scalar_mult(s2, Point)

  #HARDWARE (SLOWER BUT SHOULD BE EXACTLY THE SAME)
  PointHW = HW.EC_scalar_mult(s1,G)
  Out_HW = HW.EC_scalar_mult(s2, PointHW)
  e0 = Out_SW[0] - Out_HW[0]
  e1 = Out_SW[1] - Out_HW[1]
  e2 = Out_SW[2] - Out_HW[2]
  e3 = Out_SW[3] - Out_HW[3]
  assert(e0 == 0)
  assert(e1 == 0)
  assert(e2 == 0)
  assert(e3 == 0)



  print(f"inM          <= 377'h{curves.q:0095x};\n")
  print(f"inS          <= 253'h{s2:0064x};\n") 
  print(f"inX          <= 377'h{Point[0]:0095x};")  
  print(f"inY          <= 377'h{Point[1]:0095x};")
  print(f"inZ          <= 377'h{Point[2]:0095x};")
  print(f"inT          <= 377'h{Point[3]:0095x};\n")
  print(f"outX         <= 377'h{Out_SW[0]:0095x};")  
  print(f"outY         <= 377'h{Out_SW[1]:0095x};")
  print(f"outZ         <= 377'h{Out_SW[2]:0095x};")
  print(f"outT         <= 377'h{Out_SW[3]:0095x};\n")
  
#####################################################

if operation == 8:

  print ("Test Vector for ECDSA verification\n")

  G = helpers.affineToExtended(curves.Gedwres)  # Use G from curves module
  private_key = helpers.getRandomInt(253) % curves.groupOrder

  # 2. Compute public key P = p * G
  public_key = SW.EC_scalar_mult(private_key, G)
  # 3. Create message hash (simulate hash with random number < groupOrder)
  message = helpers.getRandomInt(253) % curves.groupOrder

  # 4. Sign the message
  signature = SW.ecdsa_sign(private_key, message)
  K, s = signature

  print("Signature:")
  print(f"K.x          <= 377'h{K[0]:095x};")
  print(f"K.y          <= 377'h{K[1]:095x};")
  print(f"K.z          <= 377'h{K[2]:095x};")
  print(f"K.t          <= 377'h{K[3]:095x};")
  print(f"s            <= 253'h{s:064x};")
  print(f"Modulus      <= 377'h{curves.q:0095x};\n")


  # 5. Verify the signature
  verify_result = SW.ecdsa_verify(message, signature, public_key)
  valid, C, C_prime, r = verify_result
  print("Verification result:", "✅ VALID" if valid else "❌ INVALID")
  if len(sys.argv) == 4:
    if (sys.argv[3].upper() != "NOWRITE"):
      helpers.CreateConstants(seed, message, K, s, curves.q, r, public_key, C, C_prime, G)
  else:
    helpers.CreateConstants(seed, message, K, s, curves.q, r, public_key, C, C_prime, G)

#####################################################
