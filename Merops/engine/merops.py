import sys
from ctypes import *

@CFUNCTYPE(None, POINTER(c_int))
def callback(number):
    print('python: the number is ', number[0])

def main():
    native_lib = CDLL('/Users/shosumioka/Merops/DerivedData/Merops/Build/Products/Debug/libMerops.dylib')
    native_lib.set_callback(byref(callback))
    native_lib.execute_callback()
    print (dir(native_lib))
    del native_lib

if __name__ == "__main__":
    main()
