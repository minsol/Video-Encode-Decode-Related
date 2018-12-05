# README #

This project is stop the developing now. Will restart later.

This project is streaming H.264/AAC using iOS Video Tool Box to encode and send packet over RTP / RTSP

This project is association with Wowza Media Server 4.3 over.


# Known Issue #

- H264 Hardware Encoding working on iOS. Mac OS X is not working perfectly.

- for Mac OS X, AVFoundation is using hardware encoding. I using it.

- AAC Hardware Encoding is not working on iOS (Software Encoding). Mac OS X only (AVFoundation)

- H264 Hardware Decoder is working perfectly.

- H264 MaxSlice option is not working. I use packetization mode 0 (Single NAL)

- H264 kVTCompressionPropertyKey_ExpectedFrameRate is not working on Mac OS X. (15 fps static only)

- H264 bitrate is only working iOS. not Mac OS X.

- RTSP Client is only working for stream publisher.


# TODO #

- MPEG4 container format support

- MPEG2-TS container format support


# LICENSE #

This project is under GPLv2
