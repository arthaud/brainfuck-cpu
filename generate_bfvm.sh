#!/usr/bin/env bash
# Algorithms for common operations: http://esolangs.org/wiki/Brainfuck_algorithms
# Efficient table: http://www.inshame.com/2008/02/efficient-brainfuck-tables.html

# Least significant bit: left (little-endian)

# [incr] increment a register (4-bytes integer)
# pre: layout is 0 0 x0 x1 x2 x3, cursor on the first 0
# post: cursor on the first 0
incr=">+>+[<-]<[->+>+[<-]<[->+>+[<-]<[->+>+[<-]<[-<]<]<]<]"

###############################################################################
# Memory load and store
#
# addresses on 3 bytes, data bus on 4 bytes
# layout: s=0 | i0 i1 i2 | j0 j1 j2 | d0 d1 d2 d3 | tab[0..n]
#
###############################################################################

# [m_movlw] move the cursor on the left (memory write)
# pre: the cursor is on i0
# post: the cursor is on i0
m_movlw=">>>>>>>>>>[-<<<<<<<<<<<+>>>>>>>>>>>]
         <[->+<]<[->+<]<[->+<]<[->+<]
         <[->+<]<[->+<]<[->+<]<[->+<]<[->+<]<[->+<]
         >"

# [m_movrw] move the cursor on the right (memory write)
# pre: the cursor is on j0
# post: the cursor is on j0
m_movrw="[-<+>]>[-<+>]>[-<+>]
         <<<<<<<[->>>>>>>>>>>+<<<<<<<<<<<]
         >>>>"

# [m_write] store 4 bytes in the memory
# pre: s=0, [i0 i1 i2] = [j0 j1 j2] = index, [d0 d1 d2 d3] = value
#      the cursor is on s
# post: s=i0=i1=i2=j0=j1=j2=d0=d1=d2=d3=0
#       the cursor is on s
m_write=">[$m_movlw-]
         >[<-[$m_movlw-] $m_movlw >-]
         >[<-[<-[$m_movlw-] $m_movlw >-] <$m_movlw >>-]
         >>>>>>>>[-]>[-]>[-]>[-]<<<<<<<
         [->>>>+<<<<]>[->>>>+<<<<]>[->>>>+<<<<]>[->>>>+<<<<]<<<<<<
         [$m_movrw-]
         >[<-[$m_movrw-] $m_movrw >-]
         >[<-[<-[$m_movrw-] $m_movrw >-] <$m_movrw >>-]
         <<<<<<"

# [m_movlr] move the cursor on the left (memory read)
# pre: the cursor is on i0
# post: the cursor is on i0
m_movlr=">>>>>>>>>>[-<<<<<<<<<<<+>>>>>>>>>>>]
         <<<<<[->+<]<[->+<]<[->+<]<[->+<]<[->+<]<[->+<]
         >"

# [m_movrr] move the cursor on the right (memory read)
# pre: the cursor is on j0
# post: the cursor is on j0
m_movrr="[-<+>]>[-<+>]>[-<+>]>[-<+>]>[-<+>]>[-<+>]>[-<+>]
         <<<<<<<<<<<[->>>>>>>>>>>+<<<<<<<<<<<]
         >>>>"

# [m_read] load 4 bytes from the memory
# pre: s=0, [i0 i1 i2] = [j0 j1 j2] = index, d0=d1=d2=d3=0
#      the cursor is on s
# post: s=i0=i1=i2=j0=j1=j2=0, [d0 d1 d2 d3] = loaded value
#       the cursor is on s
m_read=">[$m_movlr-]
        >[<-[$m_movlr-] $m_movlr >-]
        >[<-[<-[$m_movlr-] $m_movlr >-] <$m_movlr >>-]
        >>>>>>>>[-<<<<+<<<<+>>>>>>>>]<<<<<<<<[->>>>>>>>+<<<<<<<<]
        >>>>>>>>>[-<<<<+<<<<<+>>>>>>>>>]<<<<<<<<<[->>>>>>>>>+<<<<<<<<<]
        >>>>>>>>>>[-<<<<+<<<<<<+>>>>>>>>>>]<<<<<<<<<<[->>>>>>>>>>+<<<<<<<<<<]
        >>>>>>>>>>>[-<<<<+<<<<<<<+>>>>>>>>>>>]<<<<<<<<<<<[->>>>>>>>>>>+<<<<<<<<<<<]>
        [$m_movrr-]
        >[<-[$m_movrr-] $m_movrr >-]
        >[<-[<-[$m_movrr-] $m_movrr >-] <$m_movrr >>-]
        <<<<<<"

###############################################################################
# Register load and store
#
# addresses on 1 byte, data bus on 1 or 4 bytes
# layout: i | 0 0 d0 d1 d2 d3 | 0 0 tab[0]_0 tab[0]_1 tab[0]_2 tab[0]_3 
#                             | 0 0 tab[1]_0 tab[1]_1 tab[1]_2 tab[1]_3
#                             | ...
#
###############################################################################

# [r_fill_index] write 1 before each array cell until we reach the index
# pre: the cursor is on i
# post: the cursor is on i and i=0
r_fill_index="[>>>>>>>[>>>>>>]+[<<<<<<]<-]"

# [r_remove_index] remove all 1 before each array cell until we reach the beginning
# pre: the cursor in on the current array cell
# post: the cursor is on i
r_remove_index="<<<<<<[-<<<<<<]<"

# [r_read1] read 1 byte
# pre: i = index, d0=d1=d2=d3=0
#      the cursor is on i
# post: i=0, d0 = read value, d1=d2=d3=0
#       the cursor is on i
r_read1="$r_fill_index
         >>>>>>>[>>>>>>]
         >>[-<+<<<<<<<[<<<<<<]>>+>>>>[>>>>>>]>>]<[->+<]<
         $r_remove_index"

# [r_read4] read 4 bytes
# pre: i = index, d0=d1=d2=d3=0
#      the cursor is on i
# post: i=0, [d0 d1 d2 d3] = read value
#       the cursor is on i
r_read4="$r_fill_index
         >>>>>>>[>>>>>>]
         >>[-<+<<<<<<<[<<<<<<]>>+>>>>[>>>>>>]>>]<[->+<]
         >>[-<<+<<<<<<<[<<<<<<]>>>+>>>[>>>>>>]>>>]<<[->>+<<]
         >>>[-<<<+<<<<<<<[<<<<<<]>>>>+>>[>>>>>>]>>>>]<<<[->>>+<<<]
         >>>>[-<<<<+<<<<<<<[<<<<<<]>>>>>+>[>>>>>>]>>>>>]<<<<[->>>>+<<<<]<
         $r_remove_index"

# [r_write1] write 1 byte
# pre: i = index, d0 = value, d1=d2=d3=0
#      the cursor is on i
# post: i=d0=d1=d2=d3=0
#       the cursor is on i
r_write1="$r_fill_index
          >>>>>>>[>>>>>>]>>[-]<<<<<<<<[<<<<<<]
          >>[->>>>[>>>>>>]>>+<<<<<<<<[<<<<<<]>>]
          >>>>[>>>>>>]
          $r_remove_index"

# [r_write4] write 4 bytes
# pre: i = index, [d0 d1 d2 d3] = value
#      the cursor is on i
# post: i=d0=d1=d2=d3=0
#       the cursor is on i
r_write4="$r_fill_index
          >>>>>>>[>>>>>>]>>[-]>[-]>[-]>[-]<<<<<<<<<<<[<<<<<<]
          >>[->>>>[>>>>>>]>>+<<<<<<<<[<<<<<<]>>]
          >[->>>[>>>>>>]>>>+<<<<<<<<<[<<<<<<]>>>]
          >[->>[>>>>>>]>>>>+<<<<<<<<<<[<<<<<<]>>>>]
          >[->[>>>>>>]>>>>>+<<<<<<<<<<<[<<<<<<]>>>>>]
          >[>>>>>>]
          $r_remove_index"

###############################################################################
# brainfuck virtual machine
#
# layout:
#  0x0 - 0xf  : internal memory
# 0x10 - 0x7f : registers
#        0x6b : r14 (sp)
#        0x71 : r15 (ip)
# 0x80 - inf  : memory
###############################################################################

main="# reading the code until we consecutively read 4 null bytes
      ++++
      [-
       # read next char
       >>>,
       # if c != 0, reset counter=4
       <+>[<<<[-]++++>>-]<[-<]>>
       # move the read char in d0
       [->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+<<<<<<<<
        <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<]
       # copy the current index (r14 = sp) in the memory index
       >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
       >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
       [<+>>>>>>>>>>>>>>>>>>>>>+>>>+<<<<<<<<<<<<<<<<<<<<<<<-]<[->+<]
       >>[<<+>>>>>>>>>>>>>>>>>>>>>>+>>>+<<<<<<<<<<<<<<<<<<<<<<<-]<<[->>+<<]
       >>>[<<<+>>>>>>>>>>>>>>>>>>>>>>>+>>>+<<<<<<<<<<<<<<<<<<<<<<<-]<<<[->>>+<<<]
       # store the value
       >>>>>>>>>>>>>>>>>>>> $m_write
       # increment the current index (r14 = sp)
       <<<<<<<<<<<<<<<<<<<<< $incr
       # go back to address 0
       <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
       <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
      ]
      # execute the program
      +[# Main Loop
        # copy the instruction pointer (r15 = ip) in the memory index
        >>>>>>>>>>>>>>>> # registers
        >>>>>>>>>>>>>>>>
        >>>>>>>>>>>>>>>>
        >>>>>>>>>>>>>>>>
        >>>>>>>>>>>>>>>>
        >>>>>>>>>>>>>>>>
        >>>>>>>>>>>>>>>>
        >>> # r15 = ip
        [<+>>>>>>>>>>>>>>>+>>>+<<<<<<<<<<<<<<<<<-]<[->+<]
        >>[<<+>>>>>>>>>>>>>>>>+>>>+<<<<<<<<<<<<<<<<<-]<<[->>+<<]
        >>>[<<<+>>>>>>>>>>>>>>>>>+>>>+<<<<<<<<<<<<<<<<<-]<<<[->>>+<<<]
        # fetch the next instruction
        >>>>>>>>>>>>>> $m_read
        # decode and execute the instruction
        #   decrement d0, test d0 == 0, decrement d0, test d0 == 0, and so on
        #   each instruction starts with the cursor on d0
        #   each instruction writes its length on i0 (the main loop increment ip after)
        >>>>>
        >+>-[-[-[
          # Unknow instruction : EXIT
          <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
          <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<->>
          >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
          >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

          # instruction length
          <<<<<<+>>>>>>
        <-]<[->
          # 0x03 : SETB
          # move the register in i
          >[<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<+>>>>>>>>>>>>>
            >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>-]
          # move the value in d0
          >[<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
          <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<+>>>>>>>>>>>>>>>>>
          >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
          >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>-]
          # write register
          <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
          <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
          $r_write4
          >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
          >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

          # instruction length
          <<<<<<+++>>>>>>
        <<]>]<[->
          # 0x02 : CLR
          # move the register in i
          >[<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<+>>>>>>>>>>>>>
            >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>-]
          # write register
          <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
          <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
          $r_write4
          >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
          >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

          # instruction length
          <<<<<<++>>>>>>
        <<]>]<[->
          # 0x01 : NOP
          # instruction length
          <<<<<<+>>>>>>
        <<]
        !
        # clean memory header
        >>[-]>[-]>[-]>[-]<<<<<<<<<
        # increment ip
        [<<<<<<<<<<<<<<<< $incr >>>>>>>>>>>>>>>>-]
        # go back to address 0
        <
        <<<<<<<<<<<<<<<<
        <<<<<<<<<<<<<<<<
        <<<<<<<<<<<<<<<<
        <<<<<<<<<<<<<<<<
        <<<<<<<<<<<<<<<<
        <<<<<<<<<<<<<<<<
        <<<<<<<<<<<<<<<<
        <<<<<<<<<<<<<<<<
      ]"

# Remove comments and whitespaces
echo "$main" | sed "s/#[^\n]*$//" | tr -d ' \n\t'
