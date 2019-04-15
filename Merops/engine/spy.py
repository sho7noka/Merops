import sys
from ctypes import *


# NOTE: fn_name is copied from the output of nm (see INSTRUCTIONS.md)
if sys.platform == "darwin":
    lib_ext = "dylib"
    fn_name = "_TF3sit15mystringdoublerFGVSs20UnsafeMutablePointerVSC7_object_GS0_S1__"
else:
    lib_ext = "so"
    fn_name = "_TF3sit15mystringdoublerFGSpVSC7_object_GSpS0__"


########################################
# Calling the Simple way
########################################
libsit = PyDLL("./libEngine.{0}".format(lib_ext))
prototype = PYFUNCTYPE(    
    py_object, # return type
    py_object, # args type, arg type, arg type
)

str_doubler = prototype((fn_name, libsit))

print str_doubler("Hamburger")

def swift_fn(name, ret_type, *arg_types):
    prototype = PYFUNCTYPE(    
        ret_type,
        *arg_types
    )
    return lambda self, *args: prototype((name, self.lib))(*args)

class SwiftLib(object):
    def __init__(self):
        self.lib = PyDLL(self.lib_file)
        

class SwiftInteropTest(SwiftLib):
    lib_file = "./libEngine.{0}".format(lib_ext)
    
    double_str = swift_fn(
        fn_name,
        py_object,
        py_object,
    )

lib = SwiftInteropTest()
#print lib.double_str("Bang!")
