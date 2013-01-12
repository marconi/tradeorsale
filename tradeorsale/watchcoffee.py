import sys
import os
import time
import subprocess


PROJECT_ROOT = os.path.abspath(os.path.dirname(__file__))
COFFEE_ROOT = os.path.join(PROJECT_ROOT, 'static/src')
JS_ROOT = os.path.join(PROJECT_ROOT, 'static/js')
coffee_files = []


def compile_coffee(file):
    print "Compiling %s" % file
    to_path = os.path.dirname(file).replace('src', 'js')
    cmd = "coffee -cwo %(to)s %(from)s" % {"to": to_path, "from": file}
    proc = subprocess.Popen(cmd, shell=True)

    for i in range(5):  # give it max of 5 seconds to compile
        time.sleep(1)
        if proc.poll() != None:
            break
    proc.kill()


def collect_coffees(coffee_path):
    for filename in os.listdir(coffee_path):
        path = os.path.join(coffee_path, filename)
        if os.path.isdir(path):
            collect_coffees(path)
        else:
            last_update = int(os.stat(path).st_mtime)
            coffee_files.append((last_update, path))


if __name__ == '__main__':
    
    collect_coffees(COFFEE_ROOT)

    try:
        while True:
            for index, fileinfo in enumerate(coffee_files):
                current_modified = int(os.stat(fileinfo[1]).st_mtime)
                if current_modified > fileinfo[0]:
                    coffee_files[index] = (current_modified, fileinfo[1])
                    compile_coffee(fileinfo[1])
            time.sleep(1)
    except KeyboardInterrupt:
        sys.exit(0)
