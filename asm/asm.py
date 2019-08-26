from ast import literal_eval
import fileinput
import re

def remove_nonsense(it):
    regex = re.compile("[/#;].*")
    for line in it:
        code = regex.sub('', line).strip()
        if code != '':
            yield code

def tokenize(it):
    for line in it:
        yield line.split()

def parse_numbers(it):
    def num(val):
        try:
            return literal_eval(val)
        except:
            return val

    for cmd in it:
        yield [num(val) for val in cmd]


def replace_defines(it):
    defines = {}
    for cmd in it:
        if cmd[0].startswith('%'):
            defines[cmd[1]] = cmd[2]
        else:
            yield [defines.get(w, w) for w in cmd]

def join_labels(it):
    for cmd in it:
        if len(cmd) == 1 and cmd[0].endswith(':'):
            try:
                yield cmd + next(it)
            except StopIteration:
                yield cmd
        else:
            yield cmd

def replace_labels(it):
    # two passes to be able to jump forward
    data = list(it)
    labels = {}
    # create indices
    for idx, cmd in enumerate(data):
        if cmd[0].endswith(':'):
            labels[cmd[0][:-1]] = idx
            cmd.pop(0)
    # replace labels with indices
    for cmd in data:
        yield [labels.get(w, w) for w in cmd]

def encode(it):
    reg = {'a': 0, 'sp': 1, 'pc': 2, 'pcc': 3}
    alu = {'add': 0, 'sub': 1, 'or': 2, 'and': 3,
           'xor': 4, 'b': 5, 'eq': 5, 'a': 6, 'gt': 6, 'clr': 7}
    for cmd in it:
        if len(cmd) == 0: continue
        op = cmd[0].lower()
        if op == 'lit':
            yield cmd[1]
        elif op == 'st':
            yield 0b0100110000000000 # SP = SP
        elif op == 'push':
            if len(cmd) < 3: cmd.extend(['sub', 1])
            alu_op = alu[cmd[1].lower()] << 9
            yield 0b0100000000000000 | alu_op | cmd[2] # SP = op SP lit
        elif op == 'pusha':
            if len(cmd) < 3: cmd.extend(['sub', 1])
            alu_op = alu[cmd[1].lower()] << 9
            yield 0b0101000000000000 | alu_op | cmd[2] # SP = op SP lit
        elif op == 'ld':
            yield 0b0110110000000000
        elif op == 'pop':
            if len(cmd) < 3: cmd.extend(['add', 1])
            alu_op = alu[cmd[1].lower()] << 9
            yield 0b0110000000000000 | alu_op | cmd[2] # SP = op SP lit
        elif op == 'popa':
            if len(cmd) < 3: cmd.extend(['add', 1])
            alu_op = alu[cmd[1].lower()] << 9
            yield 0b0111000000000000 | alu_op | cmd[2] # SP = op SP lit
        elif op == 'rol':
            alu_op = alu[cmd[1].lower()] << 9
            yield 0b1000000000000000 | alu_op | cmd[2]
        else: # ALU
            dest = reg[cmd[1].lower()] << 12
            alu_op = alu[op] << 9
            if len(cmd) > 2:
                yield 0b1100000000000000 | dest | alu_op | cmd[2]
            else:
                yield 0b1000000000000000 | dest | alu_op

def print_mem(it):
    for op in it:
        print(format(op, '016b'))

def process(it):
    it = remove_nonsense(it)
    it = tokenize(it)
    it = parse_numbers(it)
    it = replace_defines(it)
    it = join_labels(it)
    it = replace_labels(it)
    it = encode(it)
    print_mem(it)

if __name__ == "__main__":
    process(fileinput.input())
