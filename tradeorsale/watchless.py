import sys
import os
import time


PROJECT_ROOT = os.path.abspath(os.path.dirname(__file__))
CSS_ROOT = os.path.join(PROJECT_ROOT, 'static/css')
LESS_ROOT = os.path.join(CSS_ROOT, 'less')
LESS_MODULES_ROOT = os.path.join(LESS_ROOT, 'modules')
MAIN_LESS_FILENAME = os.path.join(LESS_ROOT, 'local.less')


def compile_less(file):
    print "Compiling %s" % file
    tmp = os.path.splitext(os.path.basename(file))
    to_file = "%s.css" % os.path.join(CSS_ROOT, tmp[0])
    os.system("lessc %(from)s > %(to)s -x" % {"from": file, "to": to_file})


if __name__ == '__main__':
    # gather all less files and their last modified datetime
    less_files = {'local.less': (int(os.stat(MAIN_LESS_FILENAME).st_mtime),
                                 MAIN_LESS_FILENAME)}

    for filename in os.listdir(LESS_MODULES_ROOT):
        filepath = os.path.join(LESS_MODULES_ROOT, filename)
        less_files[filename] = (int(os.stat(filepath).st_mtime), filepath)

    try:
        while True:
            for filename, fileinfo in less_files.items():
                current_modified = int(os.stat(fileinfo[1]).st_mtime)
                if current_modified > fileinfo[0]:
                    less_files[filename] = (current_modified, fileinfo[1])
                    compile_less(MAIN_LESS_FILENAME)
            time.sleep(1)
    except KeyboardInterrupt:
        sys.exit(0)
