import pandas as pd
from sredfpy import edf_read


class EDF:
    """ SR-Research EDF File """

    def __init__(self, fname=None):
        """
        Read Sr-Research EyeTracking Datafile

        :param fname: str
        """

        self.fname = fname
        self.header = None
        self.fsample = None
        self.fevent = None
        self.rec = None

        if self.fname is not None:
            self.read(fname)

    def __str__(self):
        """ Print out some useful information. """
        name = "Filename: " + self.fname
        header = self.header.decode()

        return "{}\n{}".format(name, header)

    def __repr__(self):
        return self.__str__()

    def read(self, fname):
        """ Read SR-Research EDF file. """

        print("Reading file: {}".format(fname))
        self.header, self.fsample, self.fevent, self.rec = edf_read.read(fname)

    def convert_to_pandas_df(self):
        """
        Convert numpy structures (fsample, fevent, and rec)
        to pandas DataFrame.
        """

        self.fsample = pd.DataFrame(self.fsample)
        self.fevent = pd.DataFrame(self.fevent)
        self.rec = pd.DataFrame(self.rec)
