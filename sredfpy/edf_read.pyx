""" Reads SR Research EDF files. """
from libc.stdlib cimport malloc
cimport numpy as np
import numpy as np
from edf_data cimport ALLF_DATA

cdef extern from "edf.h":
    ctypedef struct EDFFILE
    EDFFILE * edf_open_file(const char * fname,
                            int consistency,
                            int load_events,
                            int load_samples,
                            int *errval)
    int edf_get_preamble_text_length(EDFFILE * edf_file_ptr)
    int edf_get_preamble_text(EDFFILE *edf_file_ptr, char * buffer, int length)
    int edf_get_next_data(EDFFILE * edf_file_ptr)
    ALLF_DATA * edf_get_float_data(EDFFILE * edf_file_ptr)
    int edf_get_element_count(EDFFILE * edf_file_ptr)
    int edf_close_file(EDFFILE * edf_file_ptr)


# SAMPLE TYPES
cdef int NO_PENDING_ITEMS = 0
cdef int STARTPARSE = 1
cdef int ENDPARSE = 2
cdef int STARTBLINK = 3
cdef int ENDBLINK = 4
cdef int STARTSAC = 5
cdef int ENDSACC = 6
cdef int STARTFIX = 7
cdef int ENDFIX = 8
cdef int FIXUPDATE = 9
cdef int BREAKPARSE = 10
cdef int STARTSAMPLES = 15
cdef int ENDSAMPLES = 16
cdef int STARTEVENTS = 17
cdef int ENDEVENTS = 18
cdef int MESSAGEEVENT = 24
cdef int INPUT_EVENT = 28
cdef int RECORDING_INFO = 30
cdef int SAMPLE_TYPE = 200

SAMPLE_TYPES = {
    0: "NO_PENDING_ITEMS", 1: "STARTPARSE", 2: "ENFPARSE",
    3: "STARTBLINK", 4: "ENDBLINK", 5: "STARTSAC", 6: "ENDSACC",
    7: "STARTFIX", 8: "ENDFIX", 9: "FIXUPDATE", 10: "BREAKPARSE",
    15: "STARTSAMPLES", 16: "ENDSAMPLES", 17: "STARTEVENTS",
    18: "ENDEVENTS", 24: "MESSAGEEVENT", 28: "INPUT_EVENT",
    30: "RECORDING_INFO", 200: "SMAPLE_TYPE"
}


def read(filename):
    """ Read an EDF file into a numpy structures. """
    return cread(filename)

cdef cread(filename):

    cdef int errval = 1
    cdef EDFFILE* edf_file_ptr
    cdef int sample_type, cnt, trial

    edf_file_ptr = edf_open_file(filename.encode("utf-8"), 0, 1, 1, &errval)
    if errval < 0:
        raise IOError("Could not open: {}".format(filename))

    cdef int preamble_text_length = edf_get_preamble_text_length(edf_file_ptr)
    cdef char *header = <char*> malloc(preamble_text_length *sizeof(char))

    e = edf_get_preamble_text(edf_file_ptr, header, preamble_text_length)
    num_elements = edf_get_element_count(edf_file_ptr)

    # numpy data arrays structures
    cdef np.ndarray fsample = init_np_fsample(num_elements)
    cdef np.ndarray fevent = init_np_fevent(num_elements)
    cdef np.ndarray rec = init_np_rec(num_elements)
    cdef int idx_fsample = 0
    cdef int idx_fevent = 0
    cdef int idx_rec = 0
    cdef char *msg

    while True:

        sample_type = edf_get_next_data(edf_file_ptr)

        if sample_type == SAMPLE_TYPE:

            fd = edf_get_float_data(edf_file_ptr)
            fsample[idx_fsample] = (filename,
                                    fd.fs.time,
                                    fd.fs.px[0], fd.fs.px[1],
                                    fd.fs.py[0], fd.fs.py[1],
                                    fd.fs.hx[0], fd.fs.hx[1],
                                    fd.fs.hy[0], fd.fs.hy[1],
                                    fd.fs.pa[0], fd.fs.pa[1],
                                    fd.fs.gx[0], fd.fs.gx[1],
                                    fd.fs.gy[0], fd.fs.gy[1],
                                    fd.fs.rx, fd.fs.ry,
                                    fd.fs.gxvel[0], fd.fs.gxvel[1],
                                    fd.fs.gyvel[0], fd.fs.gyvel[1],
                                    fd.fs.hxvel[0], fd.fs.hxvel[1],
                                    fd.fs.hyvel[0], fd.fs.hyvel[1],
                                    fd.fs.rxvel[0], fd.fs.rxvel[1],
                                    fd.fs.ryvel[0], fd.fs.ryvel[1],
                                    fd.fs.fgxvel[0], fd.fs.fgxvel[1],
                                    fd.fs.fgyvel[0], fd.fs.fgyvel[1],
                                    fd.fs.fhxvel[0], fd.fs.fhxvel[1],
                                    fd.fs.fhyvel[0], fd.fs.fhyvel[1],
                                    fd.fs.frxvel[0], fd.fs.frxvel[1],
                                    fd.fs.fryvel[0], fd.fs.fryvel[1],
                                    fd.fs.hdata[0], fd.fs.hdata[1],
                                    fd.fs.hdata[2], fd.fs.hdata[3],
                                    fd.fs.hdata[4], fd.fs.hdata[5],
                                    fd.fs.hdata[6], fd.fs.hdata[7],
                                    fd.fs.flags,
                                    fd.fs.input,
                                    fd.fs.buttons,
                                    fd.fs.htype,
                                    fd.fs.errors)

            idx_fsample += 1

        elif sample_type in (STARTPARSE, ENDPARSE, STARTBLINK, ENDBLINK,
                             STARTSAC, ENDSACC, STARTFIX, ENDFIX, FIXUPDATE,
                             STARTSAMPLES, ENDSAMPLES, STARTEVENTS, ENDEVENTS,
                             MESSAGEEVENT, INPUT_EVENT):

            fd = edf_get_float_data(edf_file_ptr)

            message = ""
            if <long long> fd.fe.message != 0:
                msg = &fd.fe.message.c
                message = msg[:fd.fe.message.len]

            fevent[idx_fevent] = (filename,
                                  fd.fe.time,
                                  SAMPLE_TYPES[sample_type],
                                  fd.fe.read, fd.fe.eye,
                                  fd.fe.sttime, fd.fe.entime,
                                  fd.fe.hstx, fd.fe.hsty, fd.fe.gstx,
                                  fd.fe.gsty,
                                  fd.fe.sta,
                                  fd.fe.henx, fd.fe.heny,
                                  fd.fe.genx, fd.fe.geny,
                                  fd.fe.ena,
                                  fd.fe.havx, fd.fe.havy,
                                  fd.fe.gavx, fd.fe.gavy,
                                  fd.fe.ava,
                                  fd.fe.avel,
                                  fd.fe.pvel,
                                  fd.fe.svel,
                                  fd.fe.evel,
                                  fd.fe.supd_x, fd.fe.eupd_x,
                                  fd.fe.supd_y, fd.fe.eupd_y,
                                  fd.fe.status,
                                  fd.fe.flags,
                                  fd.fe.input,
                                  fd.fe.buttons,
                                  fd.fe.parsedby,
                                  message)

            idx_fevent += 1

        elif sample_type == RECORDING_INFO:

            fd = edf_get_float_data(edf_file_ptr)
            rec[idx_rec] = (filename,
                            fd.rec.time,
                            fd.rec.sample_rate,
                            fd.rec.eflags, fd.rec.sflags,
                            fd.rec.state,
                            fd.rec.record_type,
                            fd.rec.pupil_type,
                            fd.rec.recording_mode,
                            fd.rec.filter_type,
                            fd.rec.pos_type,
                            fd.rec.eye)

            idx_rec += 1

        elif sample_type == NO_PENDING_ITEMS:

            edf_close_file(edf_file_ptr)
            break

    fsample = fsample[0:idx_fsample]
    fevent = fevent[0:idx_fevent]
    rec = rec[0:idx_rec]

    return header, fsample, fevent, rec


def init_np_fsample(n):
    """ Initalize numpy data structure to hold fsample. """

    return np.ndarray(n,
                      dtype = [("fname", "<S8"),
                               ("time", "u4"),
                               ("px_left", "f4"), ("px_right", "f4"),
                               ("py_left", "f4"), ("py_right", "f4"),
                               ("hx_left", "f4"), ("hx_right", "f4"),
                               ("hy_left", "f4"), ("hy_right", "f4"),
                               ("pa_left", "f4"), ("pa_right", "f4"),
                               ("gx_left", "f4"), ("gx_right", "f4"),
                               ("gy_left", "f4"), ("gy_right", "f4"),
                               ("rx", "f4"), ("ry", "f4"),
                               ("gxvel_left", "f4"), ("gxvel_right", "f4"),
                               ("gyvel_left", "f4"), ("gyvel_right", "f4"),
                               ("hxvel_left", "f4"), ("hxvel_right", "f4"),
                               ("hyvel_left", "f4"), ("hyvel_right", "f4"),
                               ("rxvel_left", "f4"), ("rxvel_right", "f4"),
                               ("ryvel_left", "f4"), ("ryvel_right", "f4"),
                               ("fgxvel_left", "f4"), ("fgxvel_right", "f4"),
                               ("fgyvel_left", "f4"), ("fgyvel_right", "f4"),
                               ("fhxvel_left", "f4"), ("fhxvel_right", "f4"),
                               ("fhyvel_left", "f4"), ("fhyvel_right", "f4"),
                               ("frxvel_left", "f4"), ("frxvel_right", "f4"),
                               ("fryvel_left", "f4"), ("fryvel_right", "f4"),
                               ("hdata0", "i2"), ("hdata1", "i2"),
                               ("hdata2", "i2"), ("hdata3", "i2"),
                               ("hdata4", "i2"), ("hdata5", "i2"),
                               ("hdata6", "i2"), ("hdata7", "i2"),
                               ("flags", "u2"),
                               ("input", "u2"),
                               ("buttons", "u2"),
                               ("htype", "i2"),
                               ("errors", "i2")]
                      )


def init_np_fevent(n):
    """ Initalize numpy data structure to hold fevent. """

    return np.ndarray(n,
                      dtype = [("fname", "<S8"),
                               ("time", "<u4"),
                               ("type", "<U10"),
                               ("read", "f4"),
                               ("eye", "f4"),
                               ("sttime", "f4"),
                               ("entime", "f4" ),
                               ("hstx", "f4"), ("hsty", "f4"),
                               ("gstx", "f4"), ("gsty", "f4"),
                               ("sta", "f4"),
                               ("henx", "f4"), ("heny", "f4"),
                               ("genx", "f4"), ("geny", "f4"),
                               ("ena", "f4"),
                               ("havx", "f4"), ("havy", "f4"),
                               ("gavx", "f4"), ("gavy", "f4"),
                               ("ava", "f4"),
                               ("avel", "f4"),
                               ("pvel", "f4"),
                               ("svel", "f4"),
                               ("evel", "f4"),
                               ("supd_x", "f4"), ("eupd_x", "f4"),
                               ("supd_y", "f4"), ("eupd_y", "f4"),
                               ("status", "f4"),
                               ("flags""", "f4"),
                               ("input""", "f4"),
                               ("buttons", "f4"),
                               ("parsedby", "f4"),
                               ("message", "<U260")]
                      )


def init_np_rec(n):
    """ Initalize numpy data structure to hold recording. """

    return np.ndarray(n,
                      dtype = [("fname", "<S8"),
                               ("time", "<u4"),
                               ("sample_rate","f4"),
                               ("eflags","f4"),
                               ("sflags","f4"),
                               ("state","f4"),
                               ("record_type","f4"),
                               ("pupil_type","f4"),
                               ("recording_mode","f4"),
                               ("filter_type","f4"),
                               ("pos_type","f4"),
                               ("eye","f4")]
                      )

