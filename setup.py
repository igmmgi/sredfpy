from setuptools import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
from Cython.Build import cythonize
import numpy

args = {
    'include_dirs': [numpy.get_include(), 'include/'],
    'library_dirs': ['lib/'],
    'libraries': ['edfapi'],
}

ext = [Extension(name="sredfpy.edf_data",
                 sources=["sredfpy/edf_data.pxd"],
                 **args),
       Extension(name="sredfpy.edf_read",
                 sources=["sredfpy/edf_read.pyx"],
                 **args)]

setup(
    name='sredfpy',
    version='0.1',
    description='Read SR-Research EDF files and convert to numpy structure.',
    author='igm',
    cmdclass={'build_ext': build_ext},
    packages=['sredfpy'],
    install_requires=["cython", "numpy", "pandas"],
    ext_modules=cythonize(ext)
)
