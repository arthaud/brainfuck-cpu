#!/usr/bin/env bash
# Algorithms for common operations: http://esolangs.org/wiki/Brainfuck_algorithms
# Efficient table: http://www.inshame.com/2008/02/efficient-brainfuck-tables.html

# Least significant bit: left (little-endian)

###############################################################################
# Array load and store
#
# addresses on 3 bytes, data bus on 4 bytes
# layout: s=0 | i0 i1 i2 | j0 j1 j2 | d0 d1 d2 d3 | tab[0..n]
#
###############################################################################

# [amovlw] move the cursor on the left (array write)
# pre: the cursor is on i0
# post: the cursor is on i0
amovlw=">>>>>>>>>>[-<<<<<<<<<<<+>>>>>>>>>>>]
        <[->+<]<[->+<]<[->+<]<[->+<]
        <[->+<]<[->+<]<[->+<]<[->+<]<[->+<]<[->+<]
        >"

# [amovrw] move the cursor on the right (array write)
# pre: the cursor is on j0
# post: the cursor is on j0
amovrw="[-<+>]>[-<+>]>[-<+>]
        <<<<<<<[->>>>>>>>>>>+<<<<<<<<<<<]
        >>>>"

# [awrite] store 4 bytes in the array
# pre: s=0, [i0 i1 i2] = [j0 j1 j2] = index, [d0 d1 d2 d3] = value
#      the cursor is on s
# post: s=i0=i1=i2=j0=j1=j2=d0=d1=d2=d3=0
#       the cursor is on s
awrite=">[$amovlw-]
        >[<-[$amovlw-] $amovlw >-]
        >[<-[<-[$amovlw-] $amovlw >-] <$amovlw >>-]
        >>>>>>>>[-]>[-]>[-]>[-]<<<<<<<
        [->>>>+<<<<]>[->>>>+<<<<]>[->>>>+<<<<]>[->>>>+<<<<]<<<<<<
        [$amovrw-]
        >[<-[$amovrw-] $amovrw >-]
        >[<-[<-[$amovrw-] $amovrw >-] <$amovrw >>-]
        <<<<<<"

# [amovlr] move the cursor on the left (array read)
# pre: the cursor is on i0
# post: the cursor is on i0
amovlr=">>>>>>>>>>[-<<<<<<<<<<<+>>>>>>>>>>>]
	<<<<<[->+<]<[->+<]<[->+<]<[->+<]<[->+<]<[->+<]
        >"

# [amovrr] move the cursor on the right (array read)
# pre: the cursor is on j0
# post: the cursor is on j0
amovrr="[-<+>]>[-<+>]>[-<+>]>[-<+>]>[-<+>]>[-<+>]>[-<+>]
        <<<<<<<<<<<[->>>>>>>>>>>+<<<<<<<<<<<]
        >>>>"

# [aread] load 4 bytes from the array
# pre: s=0, [i0 i1 i2] = [j0 j1 j2] = index, d0=d1=d2=d3=0
#      the cursor is on s
# post: s=i0=i1=i2=j0=j1=j2=0, [d0 d1 d2 d3] = loaded value
#       the cursor is on s
aread=">[$amovlr-]
       >[<-[$amovlr-] $amovlr >-]
       >[<-[<-[$amovlr-] $amovlr >-] <$amovlr >>-]
       >>>>>>>>[-<<<<+<<<<+>>>>>>>>]<<<<<<<<[->>>>>>>>+<<<<<<<<]
       >>>>>>>>>[-<<<<+<<<<<+>>>>>>>>>]<<<<<<<<<[->>>>>>>>>+<<<<<<<<<]
       >>>>>>>>>>[-<<<<+<<<<<<+>>>>>>>>>>]<<<<<<<<<<[->>>>>>>>>>+<<<<<<<<<<]
       >>>>>>>>>>>[-<<<<+<<<<<<<+>>>>>>>>>>>]<<<<<<<<<<<[->>>>>>>>>>>+<<<<<<<<<<<]>
       [$amovrr-]
       >[<-[$amovrr-] $amovrr >-]
       >[<-[<-[$amovrr-] $amovrr >-] <$amovrr >>-]
       <<<<<<"
