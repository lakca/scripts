import inspect
import sys
import textwrap


def deb():
    frame = inspect.currentframe().f_back
    code = frame.f_code
    name = code.co_name
    abs_name = None
    func = None
    obj = None

    def find_class(cls):
        nonlocal code, name
        _func = cls.__dict__.get(name, None)
        _code = _func.__code__ if hasattr(_func, '__code__') else _func.__func__.__code__ if hasattr(_func, '__func__') else None
        if _code == code:
            func = _func
            obj = func
            abs_name = [cls.__qualname__ + '<cls>']
            if isinstance(_func, staticmethod):
                abs_name += [_func.__func__.__name__ + '<static>']
                obj = func
                func = func.__func__
            elif isinstance(_func, classmethod):
                abs_name += [_func.__func__.__name__ + '<class>']
                obj = func
                func = func.__func__
            else:
                abs_name += [_func.__name__]
            return (obj, func, abs_name)
        return (None, None, None)

    def find_func(f):
        nonlocal code, name
        if f and f.__code__ == code:
            return (f, f, [f.__qualname__])
        return (None, None, None)

    # 内联
    if frame.f_back:
        f = frame.f_back
        # 函数
        obj, func, abs_name = find_func(f.f_locals.get(name, None))
        # 类
        if func is None:
            for cls in f.f_locals.values():
                if inspect.isclass(cls):
                    obj, func, abs_name = find_class(cls)
                    if func:
                        break
    # 模块
    if func is None:
        module = inspect.getmodule(frame)
        if module:
            for cls in module.__dict__.values():
                if inspect.isclass(cls):
                    obj, func, abs_name = find_class(cls)
                    if func:
                        break

    doc = inspect.getdoc(func) or '-'
    [first, lines] = (doc.strip() + '\n').split('\n', 1)
    doc = first.strip() + '\n' + textwrap.indent(textwrap.dedent(lines.strip()), ' ' * 21)
    print(
        '\x1b[2m' + str(frame.f_lineno).ljust(3) + '\x1b[0m',
        '\x1b[31m' + '.'.join(abs_name).ljust(30) + '\x1b[0m',
        '\x1b[32;2m' + str(inspect.signature(func)).ljust(20) + '\x1b[0m',
        '\x1b[2m' + doc.strip() + '\x1b[0m',
    )
