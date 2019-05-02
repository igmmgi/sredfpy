""" SR Research Data Structure used within the EDF file. """
from libc.stdint cimport int16_t, uint16_t, uint32_t

cdef extern from 'edf_data.h':

    ctypedef struct FSAMPLE:

        uint32_t time
        float px[2]
        float py[2]
        float hx[2]
        float hy[2]
        float pa[2]
        float gx[2]
        float gy[2]
        float rx
        float ry
        float gxvel[2]
        float gyvel[2]
        float hxvel[2]
        float hyvel[2]
        float rxvel[2]
        float ryvel[2]
        float fgxvel[2]
        float fgyvel[2]
        float fhxvel[2]
        float fhyvel[2]
        float frxvel[2]
        float fryvel[2]
        int16_t hdata[8]
        uint16_t flags
        uint16_t input
        uint16_t buttons
        int16_t htype
        uint16_t errors

    ctypedef struct LSTRING:

        int16_t len
        char c

    ctypedef struct FEVENT:

        uint32_t time
        int16_t type
        int16_t read
        int16_t eye
        uint32_t sttime, entime
        float hstx, hsty
        float gstx, gsty
        float sta
        float henx, heny
        float genx, geny
        float ena
        float havx, havy
        float gavx, gavy
        float ava
        float avel
        float pvel
        float svel, evel
        float supd_x, eupd_x
        float supd_y, eupd_y
        uint16_t status
        uint16_t flags
        uint16_t input
        uint16_t buttons
        uint16_t parsedby
        LSTRING *message

    ctypedef struct  IMESSAGE:

        uint32_t time
        int16_t type
        uint16_t length
        char text[260]

    ctypedef struct IOEVENT:

        uint32_t time
        int16_t type
        uint16_t data

    ctypedef struct RECORDINGS:

        uint32_t time
        float sample_rate
        uint16_t eflags
        uint16_t sflags
        char state
        char record_type
        char pupil_type
        char recording_mode
        char filter_type
        char pos_type
        char eye

    ctypedef union ALLF_DATA:

        FEVENT fe
        IMESSAGE im
        IOEVENT io
        FSAMPLE fs
        RECORDINGS rec
