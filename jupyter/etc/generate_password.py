import sys

from notebook.auth import passwd

if __name__ == "__main__":
  print(passwd(sys.argv[1], 'sha1'))
  exit()

