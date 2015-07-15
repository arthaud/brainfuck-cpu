#!/usr/bin/env python3
'''
Brainfuck interpreter and compiler

Notes:
    The input language is brainfuck, with the following instructions added:
        # starts a line comment
        ! prints the array content (in debug mode and interpreter only)
    All characters other than <>+-.,[]#! are ignored.

    Cells are 8-bit

    In debug mode and compiler, the cursor position is checked after each move.

    The special character End Of Line is 0xff (255).
'''
import os.path
import sys
import re
import tempfile
import subprocess


def int2byte(x):
    return bytes([x])


def hexdump(array, cursor, output):
    i = 0
    while i < len(array):
        line = hex(i)[2:].zfill(8)
        line += ' '
        for j in range(8):
            if cursor == i:
                line += '<'
            elif cursor == i - 1 and i % 8 != 0:
                line += '>'
            else:
                line += ' '

            if i < len(array):
                line += hex(array[i])[2:].zfill(2)
            else:
                line += '  '

            i += 1

        if cursor == i - 1:
            line += '>'
        else:
            line += ' '

        for j in range(8):
            if cursor == i:
                line += '<'
            elif cursor == i - 1 and i % 8 != 0:
                line += '>'
            else:
                line += ' '

            if i < len(array):
                line += hex(array[i])[2:].zfill(2)
            else:
                line += '  '

            i += 1

        if cursor == i - 1:
            line += '>'
        else:
            line += ' '

        line += '|'
        i -= 16
        for j in range(16):
            if i < len(array):
                c = chr(array[i])
                if c.isprintable():
                    line += c
                else:
                    line += '.'

            i += 1

        line += '|\n'
        output.write(line)


def execute(source_input, process_input, process_output, debug):
    source = source_input.read()
    source = re.sub('\#[^\n]*(\n|$)', '', source)
    source_cursor = 0
    source_brackets = []

    array = [0]
    cursor = 0

    while source_cursor < len(source):
        cmd = source[source_cursor]

        if cmd == '>':
            cursor += 1
            if cursor >= len(array):
                array.append(0)
        elif cmd == '<':
            cursor -= 1
            if cursor < 0:
                print('error: cursor below 0', file=sys.stderr)
                exit(2)
        elif cmd == '+':
            array[cursor] = (array[cursor] + 1) & 0xff
        elif cmd == '-':
            array[cursor] = (array[cursor] - 1) & 0xff
        elif cmd == '.':
            process_output.write(int2byte(array[cursor]))
            process_output.flush()
        elif cmd == ',':
            data = process_input.read(1)
            if data == b'': # EOF
                array[cursor] = 0xff
            else:
                array[cursor] = ord(data)
        elif cmd == '[':
            if array[cursor] > 0:
                source_brackets.append(source_cursor)
            else:
                # find the closing ]
                level = 1
                source_cursor += 1
                while source_cursor < len(source) and level > 0:
                    if source[source_cursor] == '[':
                        level += 1
                    elif source[source_cursor] == ']':
                        level -= 1

                    source_cursor += 1

                if source_cursor >= len(source):
                    print('error: unbalanced brackets, missing ]', file=sys.stderr)
                    exit(3)

                source_cursor -= 1
        elif cmd == ']':
            if not source_brackets:
                print('error: unbalanced brackets, missing [', file=sys.stderr)
                exit(4)

            source_cursor = source_brackets.pop() - 1
        elif cmd == '!':
            if debug:
                sys.stderr.write('\n')
                hexdump(array, cursor, sys.stderr)
                sys.stderr.flush()

        source_cursor += 1


class Compiler:
    def __init__(self, source_output, debug, size):
        self.source_output = source_output
        self.debug = debug
        self.size = size

        self.comment = False
        self.level = 0
        self.move = 0
        self.incr = 0

    def write_move(self):
        if self.move != 0:
            self.source_output.write('ptr += %d;\n' % self.move)
            if self.debug:
                self.source_output.write('assert(ptr >= array && ptr < array + %d);\n' % self.size)
            self.move = 0

    def write_incr(self):
        if self.incr != 0:
            self.source_output.write('*ptr += %d;\n' % self.incr)
            self.incr = 0

    def start(self):
        header = '''
#include <stdio.h>
#include <assert.h>

int main(int argc, char** argv) {
  char array[%d] = {0};
  char *ptr = array;
        '''
        self.source_output.write(header % self.size)

    def parse(self, c):
        if c == '\n':
            self.comment = False
        elif not self.comment:
            if c == '#':
                self.comment = True
            elif c == '>':
                self.write_incr()
                self.move += 1
            elif c == '<':
                self.write_incr()
                self.move -= 1
            elif c == '+':
                self.write_move()
                self.incr += 1
            elif c == '-':
                self.write_move()
                self.incr -= 1
            elif c == '.':
                self.write_move()
                self.write_incr()
                self.source_output.write('putchar(*ptr);\n')
            elif c == ',':
                self.write_move()
                self.write_incr()
                self.source_output.write('*ptr = getchar();\n')
            elif c == '[':
                self.write_move()
                self.write_incr()
                self.level += 1
                self.source_output.write('while (*ptr) {\n')
            elif c == ']':
                if self.level < 1:
                    print('error: unbalanced brackets, missing [', file=sys.stderr)
                    exit(4)

                self.write_move()
                self.write_incr()
                self.level -= 1
                self.source_output.write('}\n')

    def finish(self):
        # useless to call write_move() or write_incr(), it's too late
        if self.level > 0:
            print('error: unbalanced brackets, missing ]', file=sys.stderr)
            exit(3)

        self.source_output.write('return 0;\n}\n')
        self.source_output.flush()


def compile(source_input, source_output, debug, size):
    compiler = Compiler(source_output, debug, size)
    compiler.start()
    while True:
        c = source_input.read(1)
        if not c:
            break
        compiler.parse(c)

    compiler.finish()


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('filename', metavar='FILE', type=str)
    parser.add_argument('-c', '--compile',
                        action='store_const', const=True, default=False,
                        help='Generate a binary')
    parser.add_argument('-o', '--output', type=str, nargs='?', default='a.out',
                        help='Output file (compiler only), default is a.out')
    parser.add_argument('-d', '--debug',
                        action='store_const', const=True, default=False,
                        help='Debug mode')
    parser.add_argument('-s', '--size', type=int, nargs='?', default=65636,
                        help='Array size (compiler only), default is 65636')
    args = parser.parse_args()

    if not os.path.isfile(args.filename):
        print("error: no such file: '%s'" % args.filename, file=sys.stderr)
        exit(1)

    with open(args.filename, 'r') as input:
        if args.compile:
            with tempfile.NamedTemporaryFile(mode='w+', suffix='.c', prefix='bf.') as tmp:
                compile(input, tmp, args.debug, args.size)
                tmp.flush()
                subprocess.call(['gcc', '-O1' if args.debug else '-O3',
                                 '-o', args.output,
                                 tmp.name])
        else:
            execute(input, sys.stdin.buffer, sys.stdout.buffer, args.debug)
