import q
import sys

from .bspc import *
from .xrandr import XRandR, XRANDR_MONITORS, ENVIRONMENT, ULTRAWIDE_NAME, VERTICAL_NAME
from .utils import rget


# capture and print all errors for easier debugging
def log_exception(exctype, value, tb):
    if exctype == KeyboardInterrupt:
        return

    q("=======ERROR=======")
    q("Type:", exctype)
    q("Value:", value)
    q("Traceback:", tb)
    q("===================")


sys.excepthook = log_exception
