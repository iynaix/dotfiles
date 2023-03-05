from subprocess import run, check_output


def rget(obj, name, default=None):
    """recursive getitem, name can be nested, e.g. a.b.c"""
    for part in name.split("."):
        try:
            obj = obj[part]
        except KeyError:
            return default
    # handle 0 case!
    return obj if obj is not None else default


def cmd(args, debug=False, output=False):
    if output:
        return check_output(args).decode("ascii")
    else:
        run(args)
