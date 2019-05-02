import sys
import os

print (sys.path, os)

# pxr usd
#pwd = os.environ["PWD"]
#os.environ["PATH"] = pwd + "/USD/bin"
#os.environ["PATH"] = pwd + "/USD/lib"
#os.environ["PYTHONPATH"] = pwd + "/USD/lib/python"
#sys.path.append(os.path.join(pwd, "USD/lib/python"))
#sys.path.append(pwd)
#os.chdir(os.path.join(pwd, "USD/lib/python"))
#
#from pxr import Tf
#print Tf.__name__

import merops
merops.main()

