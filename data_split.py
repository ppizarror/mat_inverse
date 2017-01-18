# coding=utf-8
"""
Crea los archivos
vp_basin.grd
vs_basin.grd
rho_basin.grd
"""

# Se carga el archivo inicial
d = open('model_data.dat', 'r')

# Se crean los nuevos archivos
vp = open('vp_basin.grd', 'w')
vs = open('vs_basin.grd', 'w')
rh = open('rho_basin.grd', 'w')

# Se transforma el archivo
ksum = 0.0
for line in d:
    print line
    nline = line.split(' ')
    rline = []
    for i in nline:
        if i is not '':
            rline.append(i)
    vp.write('{0}\t{1}\n'.format(ksum, rline[1]))
    vs.write('{0}\t{1}\n'.format(ksum, rline[2]))
    rh.write('{0}\t{1}\n'.format(ksum, rline[3]))
    ksum += float(rline[0])


# Se cierran los archivos
def close_object(o):
    """
    Se cierran los archivos abiertos
    :param o:
    :return:
    """
    o.flush()
    o.close()


close_object(vs)
close_object(vp)
close_object(rh)
