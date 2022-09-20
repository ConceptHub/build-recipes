#!/usr/bin/env python3

if __name__ == '__main__':

    import subprocess
    import time

    for i in range(0,256):

        if i == 0:

            proc_str = '0'

        else:

            proc_str = '+0-' + str(i)

        command = 'numactl --physcpubind=' + proc_str + ' hbatch pyro_explosion_v002.hiplc -j -1 -c "render /obj/explosion/cache/render; quit"'

        s = time.time()

        output,error  = subprocess.Popen(command, universal_newlines=True, shell=True,
                                         stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()

        e = time.time()

        print(i + 1, e - s)

