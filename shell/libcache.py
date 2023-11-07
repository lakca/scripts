from json import dumps, loads
from time import sleep


class Cache:
    def __init__(self, file, multiple) -> None:
        self.__file = file
        self.__cache = [] if multiple else {}
        self.load()

    def __del__(self) -> None:
        self.flush()
        sleep(1)

    def load(self):
        with open(self.__file, "w+") as f:
            self.__cache = loads(f.read() or '{}')

    def flush(self):
        with open(self.__file, "w") as f:
            f.write(dumps(self.__cache))

    def get(self, key):
        return self.__cache[key]

    def set(self, key, val):
        self.__cache[key] = val
