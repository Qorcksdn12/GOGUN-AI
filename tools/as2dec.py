import struct, re, json
from swflib import *

def cstr(d, p):
    e = d.index(b'\0', p)
    return d[p:e].decode('utf-8', 'replace'), e + 1

class Ins:
    def __init__(self, off, op, args, nxt, body=None):
        self.off = off; self.op = op; self.args = args; self.nxt = nxt; self.body = body

NAMES = {0x04:'NextFrame',0x05:'PrevFrame',0x06:'Play',0x07:'Stop',0x08:'ToggleQuality',0x09:'StopSounds',0x0A:'Add',0x0B:'Sub',0x0C:'Mul',0x0D:'Div',0x0E:'Equals',0x0F:'Less',0x10:'And',0x11:'Or',0x12:'Not',0x13:'StrEq',0x14:'StrLen',0x15:'StrExtract',0x17:'Pop',0x18:'ToInt',0x1C:'GetVar',0x1D:'SetVar',0x20:'SetTarget2',0x21:'StrAdd',0x22:'GetProp',0x23:'SetProp',0x24:'CloneSprite',0x25:'RemoveSprite',0x26:'Trace',0x27:'StartDrag',0x28:'EndDrag',0x29:'StrLess',0x2A:'Throw',0x2B:'Cast',0x2C:'Implements',0x30:'Random',0x31:'MBStrLen',0x32:'CharToAscii',0x33:'AsciiToChar',0x34:'GetTime',0x35:'MBStrExtract',0x3A:'Delete',0x3B:'Delete2',0x3C:'DefLocal',0x3D:'CallFunc',0x3E:'Return',0x3F:'Mod',0x40:'NewObj',0x41:'DefLocal2',0x42:'InitArray',0x43:'InitObj',0x44:'TypeOf',0x45:'TargetPath',0x46:'Enumerate',0x47:'Add2',0x48:'Less2',0x49:'Equals2',0x4A:'ToNum',0x4B:'ToStr',0x4C:'PushDup',0x4D:'Swap',0x4E:'GetMember',0x4F:'SetMember',0x50:'Incr',0x51:'Decr',0x52:'CallMethod',0x53:'NewMethod',0x54:'InstanceOf',0x55:'Enumerate2',0x60:'BitAnd',0x61:'BitOr',0x62:'BitXor',0x63:'Shl',0x64:'Shr',0x65:'UShr',0x66:'StrictEq',0x67:'Greater',0x68:'StrGreater',0x69:'Extends'}

def decode_push(pl):
    items = []; p = 0
    while p < len(pl):
        t = pl[p]; p += 1
        if t == 0: s, p = cstr(pl, p); items.append(('str', s))
        elif t == 1: items.append(('float', struct.unpack('<f', pl[p:p+4])[0])); p += 4
        elif t == 2: items.append(('null', None))
        elif t == 3: items.append(('undef', None))
        elif t == 4: items.append(('reg', pl[p])); p += 1
        elif t == 5: items.append(('bool', bool(pl[p]))); p += 1
        elif t == 6: items.append(('double', struct.unpack('<d', pl[p+4:p+8] + pl[p:p+4])[0])); p += 8
        elif t == 7: items.append(('int', struct.unpack('<i', pl[p:p+4])[0])); p += 4
        elif t == 8: items.append(('const', pl[p])); p += 1
        elif t == 9: items.append(('const', struct.unpack('<H', pl[p:p+2])[0])); p += 2
        else: items.append(('?', t)); break
    return items

def parse_code(code):
    ins = []; pos = 0; n = len(code)
    while pos < n:
        off = pos; op = code[pos]; pos += 1
        if op == 0:
            ins.append(Ins(off, 0, [], pos)); break
        if op < 0x80:
            ins.append(Ins(off, op, [], pos)); continue
        ln = struct.unpack('<H', code[pos:pos+2])[0]; pos += 2
        pl = code[pos:pos+ln]; pos += ln
        nxt = pos; args = []; body = None
        if op == 0x96: args = decode_push(pl)
        elif op == 0x88:
            cnt = struct.unpack('<H', pl[:2])[0]; p = 2; args = []
            for _ in range(cnt):
                s, p = cstr(pl, p); args.append(s)
        elif op in (0x99, 0x9D): args = [struct.unpack('<h', pl[:2])[0]]
        elif op == 0x81: args = [struct.unpack('<H', pl[:2])[0]]
        elif op == 0x83:
            u, p = cstr(pl, 0); t, p = cstr(pl, p); args = [u, t]
        elif op == 0x87: args = [pl[0]]
        elif op == 0x8B: args = [cstr(pl, 0)[0]]
        elif op == 0x8C: args = [cstr(pl, 0)[0]]
        elif op == 0x8A: args = [struct.unpack('<H', pl[:2])[0], pl[2]]
        elif op == 0x8D: args = [pl[0]]
        elif op == 0x9A: args = [pl[0]]
        elif op == 0x9F:
            args = [pl[0]]
        elif op == 0x9B:
            name, p = cstr(pl, 0); np_ = struct.unpack('<H', pl[p:p+2])[0]; p += 2
            params = []
            for _ in range(np_):
                s, p = cstr(pl, p); params.append(s)
            cs = struct.unpack('<H', pl[p:p+2])[0]
            body = parse_code(code[pos:pos+cs]); pos += cs; nxt = pos
            args = [name, params, None]
        elif op == 0x8E:
            name, p = cstr(pl, 0); np_ = struct.unpack('<H', pl[p:p+2])[0]; p += 2
            nregs = pl[p]; p += 1
            b0 = pl[p]; b1 = pl[p+1]; p += 2
            params = []
            for _ in range(np_):
                r = pl[p]; p += 1
                s, p = cstr(pl, p); params.append((r, s))
            cs = struct.unpack('<H', pl[p:p+2])[0]
            body = parse_code(code[pos:pos+cs]); pos += cs; nxt = pos
            regs = {}; r = 1
            if b0 & 0x01: regs[r] = 'this'; r += 1
            if b0 & 0x04: regs[r] = 'arguments'; r += 1
            if b0 & 0x10: regs[r] = 'super'; r += 1
            if b0 & 0x40: regs[r] = '_root'; r += 1
            if b0 & 0x80: regs[r] = '_parent'; r += 1
            if b1 & 0x01: regs[r] = '_global'; r += 1
            for (rr, s) in params:
                if rr: regs[rr] = s
            args = [name, [s for (_, s) in params], regs, nregs]
        elif op == 0x94:
            sz = struct.unpack('<H', pl[:2])[0]
            body = parse_code(code[pos:pos+sz]); pos += sz; nxt = pos
        elif op == 0x8F:
            fl = pl[0]; ts, cs, fs = struct.unpack('<HHH', pl[1:7])
            if fl & 0x04: cname = pl[7]
            else: cname = cstr(pl, 7)[0]
            tb = parse_code(code[pos:pos+ts]); pos += ts
            cb = parse_code(code[pos:pos+cs]); pos += cs
            fb = parse_code(code[pos:pos+fs]); pos += fs
            nxt = pos; args = [fl, cname]; body = (tb, cb, fb)
        ins.append(Ins(off, op, args, nxt, body))
    return ins

# ---------------- expressions ----------------
class E:
    __slots__ = ('t', 'p', 'k', 'a', 'b', 'op')
    def __init__(self, t, p=100, k='expr', a=None, b=None, op=None):
        self.t = t; self.p = p; self.k = k; self.a = a; self.b = b; self.op = op
    def __str__(self): return self.t

def par(e, p): return '(' + e.t + ')' if e.p < p else e.t
PREC = {'*':80,'/':80,'%':80,'+':70,'-':70,'<<':65,'>>':65,'>>>':65,'<':60,'>':60,'<=':60,'>=':60,'instanceof':60,'==':55,'!=':55,'===':55,'!==':55,'&':50,'^':48,'|':46,'&&':40,'||':38}
INV = {'<':'>=','>':'<=','<=':'>','>=':'<','==':'!=','!=':'==','===':'!==','!==':'==='}
def binop(op, l, r):
    p = PREC[op]
    return E(f"{par(l,p)} {op} {par(r,p+1)}", p, 'bin', l, r, op)
def neg(e):
    if e.k == 'not': return e.a
    if e.k == 'bin' and e.op in INV: return binop(INV[e.op], e.a, e.b)
    return E('!' + par(e, 90), 90, 'not', e)
IDENT = re.compile(r'^[A-Za-z_$][A-Za-z0-9_$]*$')
PATH = re.compile(r'^[A-Za-z_$][A-Za-z0-9_$.:/]*$')
PROPS = ['_x','_y','_xscale','_yscale','_currentframe','_totalframes','_alpha','_visible','_width','_height','_rotation','_target','_framesloaded','_name','_droptarget','_url','_highquality','_focusrect','_soundbuftime','_quality','_xmouse','_ymouse']
def fmtnum(v):
    if v == int(v) and abs(v) < 1e15: return str(int(v))
    return repr(round(v, 9)) if abs(v) > 1e-4 else repr(v)
def strlit(s): return json.dumps(s, ensure_ascii=False)

class Decomp:
    def __init__(self, ins, pool, regs=None, fname=''):
        self.ins = ins; self.pool = pool; self.regs = regs or {}; self.fname = fname
        self.idx = {i.off: k for k, i in enumerate(ins)}
        if ins: self.idx[ins[-1].nxt] = len(ins)
        self.mark = {}
        self.dw = {}   # do-while heads: head idx -> if idx
        for k, i in enumerate(ins):
            if i.op == 0x9D:
                t = self.idx.get(i.nxt + i.args[0])
                if t is not None and t <= k: self.dw.setdefault(t, k)
        self.depth = 0

    def tgt(self, k):
        i = self.ins[k]; return self.idx.get(i.nxt + i.args[0])

    def regname(self, r): return self.regs.get(r, f'_r{r}')

    def const(self, it):
        t, v = it
        if t == 'str': return E(strlit(v), 100, 'str', v)
        if t in ('float', 'double'): return E(fmtnum(v), 100, 'num', v)
        if t == 'int': return E(str(v), 100 if v >= 0 else 90, 'num', v)
        if t == 'null': return E('null', 100, 'lit')
        if t == 'undef': return E('undefined', 100, 'lit')
        if t == 'bool': return E('true' if v else 'false', 100, 'lit')
        if t == 'reg': return E(self.regname(v), 100, 'reg', v)
        if t == 'const':
            s = self.pool[v] if v < len(self.pool) else f'<const{v}>'
            return E(strlit(s), 100, 'str', s)
        return E('<?>')

    def pop(self, st):
        return st.pop() if st else E('<UNDERFLOW>')

    def name_of(self, e):
        if e.k == 'str' and PATH.match(e.a): return e.a
        return f'eval({e.t})'

    def member(self, o, n):
        if n.k == 'str' and IDENT.match(n.a): return E(f'{par(o,100)}.{n.a}', 100, 'mem', o, n)
        return E(f'{par(o,100)}[{n.t}]', 100, 'mem', o, n)

    def block(self, lo, hi, st, loops):
        out = []; i = lo
        ins = self.ins
        while i < hi:
            self.mark[i] = len(out)
            if i in self.dw and self.dw[i] >= i and self.dw[i] < hi and (not loops or loops[-1][0] != ('dw', i)):
                k = self.dw[i]
                body = self.block(i, k, st, loops + [(('dw', i), i, k + 1)])
                cnd = self.pop(st)
                # If jumps when true -> loop continues
                out.append('do {'); out += ['    ' + l for l in body]; out.append('} while (' + cnd.t + ');')
                i = k + 1; continue
            x = ins[i]; op = x.op
            # -------- control flow --------
            if op == 0x9D:
                i = self.do_if(i, hi, st, loops, out); continue
            if op == 0x99:
                t = self.tgt(i)
                if loops and t == loops[-1][2]: out.append('break;')
                elif loops and t == loops[-1][1]: out.append('continue;')
                elif t is not None and t >= len(ins) - 1: out.append('return; /*jump end*/')
                else:
                    # search outer loops
                    done = False
                    for lp in reversed(loops[:-1]):
                        if t == lp[2]: out.append('break; /*outer*/'); done = True; break
                        if t == lp[1]: out.append('continue; /*outer*/'); done = True; break
                    if not done: out.append(f'goto L{ins[t].off if t is not None and t < len(ins) else "?"};')
                i += 1; continue
            self.step(x, st, out, loops)
            i += 1
        return out

    def do_if(self, i, hi, st, loops, out):
        ins = self.ins; x = ins[i]
        t = self.tgt(i)
        # short circuit
        if t is not None and t > i and i + 1 < len(ins) and ins[i+1].op == 0x17 and t <= hi + 1:
            is_and = i >= 2 and ins[i-1].op == 0x12 and ins[i-2].op == 0x4C
            is_or = i >= 1 and ins[i-1].op == 0x4C
            if is_and or is_or:
                self.pop(st)  # cond
                a = self.pop(st)
                sub = self.block(i + 2, t, st, loops)
                b = self.pop(st)
                op = '&&' if is_and else '||'
                st.append(binop(op, a, b))
                return t
        cond = self.pop(st)
        if t is None:
            out.append(f'if ({cond.t}) goto ?;'); return i + 1
        if t > i:
            last = ins[t-1] if t - 1 > i else None
            # while loop: last instr is Jump back to head <= i
            if last is not None and last.op == 0x99:
                lt = self.tgt(t - 1)
                if lt is not None and lt <= i:
                    head = lt
                    m = self.mark.get(head, len(out))
                    pre = out[m:]; del out[m:]
                    body = self.block(i + 1, t - 1, st, loops + [(('w', head), head, t)])
                    if pre:
                        out.append('while (true) {')
                        out += ['    ' + l for l in pre]
                        out.append('    if (' + cond.t + ') break;')
                        out += ['    ' + l for l in body]
                        out.append('}')
                    else:
                        out.append('while (' + neg(cond).t + ') {'); out += ['    ' + l for l in body]; out.append('}')
                    return t
            # ternary (expression-level)
            if last is not None and last.op == 0x99:
                e_ = self.tgt(t - 1)
                if e_ is not None and e_ > t and e_ <= hi + 0:
                    st1 = list(st)
                    try:
                        th = self.block(i + 1, t - 1, st1, loops)
                        if not th and len(st1) == len(st) + 1:
                            st2 = list(st)
                            el = self.block(t, e_, st2, loops)
                            if not el and len(st2) == len(st) + 1:
                                a = st1[-1]; b = st2[-1]
                                del st[:]; st.extend(st1[:-1])
                                c = neg(cond)
                                st.append(E(f"{par(c,21)} ? {par(a,21)} : {par(b,21)}", 20, 'tern'))
                                return e_
                    except Exception:
                        pass
            # break / continue via conditional jump
            if loops and t == loops[-1][2] and t > hi - 0 and False: pass
            if loops and t == loops[-1][2]:
                out.append('if (' + cond.t + ') break;'); return i + 1
            if loops and t == loops[-1][1]:
                out.append('if (' + cond.t + ') continue;'); return i + 1
            if t > hi:
                for lp in reversed(loops[:-1]):
                    if t == lp[2]: out.append('if (' + cond.t + ') break; /*outer*/'); return i + 1
                if t >= len(ins) - 1:
                    out.append('if (' + cond.t + ') return; /*jump end*/'); return i + 1
                out.append(f'if ({cond.t}) goto L{ins[t].off if t < len(ins) else "?"};'); return i + 1
            # if / else
            if last is not None and last.op == 0x99:
                e_ = self.tgt(t - 1)
                if e_ is not None and e_ > t and e_ <= hi:
                    th = self.block(i + 1, t - 1, st, loops)
                    el = self.block(t, e_, st, loops)
                    c = neg(cond)
                    out.append('if (' + c.t + ') {'); out += ['    ' + l for l in th]
                    if el and el[0].startswith('if (') and False: pass
                    out.append('} else {'); out += ['    ' + l for l in el]; out.append('}')
                    return e_
            body = self.block(i + 1, t, st, loops)
            c = neg(cond)
            out.append('if (' + c.t + ') {'); out += ['    ' + l for l in body]; out.append('}')
            return t
        else:
            # backward conditional jump
            if loops and t == loops[-1][1]:
                out.append('if (' + cond.t + ') continue;'); return i + 1
            out.append(f'if ({cond.t}) goto L{ins[t].off}; /*backward*/'); return i + 1

    def stmt(self, out, s):
        out.extend(s.split('\n'))

    def call_args(self, st):
        n = self.pop(st)
        cnt = int(n.a) if n.k == 'num' else 0
        args = [self.pop(st) for _ in range(cnt)]
        return args

    def step(self, x, st, out, loops):
        op = x.op; P = self.pop
        if op == 0: return
        if op == 0x96:
            for it in x.args: st.append(self.const(it))
        elif op == 0x88: self.pool = x.args
        elif op == 0x17:
            e = P(st)
            if e.k in ('lit', 'str', 'num', 'reg', 'var', 'mem') and e.t not in ('<UNDERFLOW>',): return
            self.stmt(out, e.t + ';')
        elif op in (0x0A, 0x47, 0x21): b = P(st); a = P(st); st.append(binop('+', a, b))
        elif op == 0x0B: b = P(st); a = P(st); st.append(binop('-', a, b))
        elif op == 0x0C: b = P(st); a = P(st); st.append(binop('*', a, b))
        elif op == 0x0D: b = P(st); a = P(st); st.append(binop('/', a, b))
        elif op == 0x3F: b = P(st); a = P(st); st.append(binop('%', a, b))
        elif op in (0x0E, 0x13, 0x49): b = P(st); a = P(st); st.append(binop('==', a, b))
        elif op == 0x66: b = P(st); a = P(st); st.append(binop('===', a, b))
        elif op in (0x0F, 0x29, 0x48): b = P(st); a = P(st); st.append(binop('<', a, b))
        elif op in (0x67, 0x68): b = P(st); a = P(st); st.append(binop('>', a, b))
        elif op == 0x10: b = P(st); a = P(st); st.append(binop('&&', a, b))
        elif op == 0x11: b = P(st); a = P(st); st.append(binop('||', a, b))
        elif op == 0x60: b = P(st); a = P(st); st.append(binop('&', a, b))
        elif op == 0x61: b = P(st); a = P(st); st.append(binop('|', a, b))
        elif op == 0x62: b = P(st); a = P(st); st.append(binop('^', a, b))
        elif op == 0x63: b = P(st); a = P(st); st.append(binop('<<', a, b))
        elif op == 0x64: b = P(st); a = P(st); st.append(binop('>>', a, b))
        elif op == 0x65: b = P(st); a = P(st); st.append(binop('>>>', a, b))
        elif op == 0x54: b = P(st); a = P(st); st.append(binop('instanceof', a, b))
        elif op == 0x2B: b = P(st); a = P(st); st.append(E(f'{par(b,100)}({a.t})', 100))
        elif op == 0x12: a = P(st); st.append(neg(a) if a.k == 'not' or a.k == 'bin' and a.op in INV and False else E('!' + par(a, 90), 90, 'not', a))
        elif op == 0x14 or op == 0x31: a = P(st); st.append(E(f'{par(a,100)}.length', 100))
        elif op == 0x18: a = P(st); st.append(E(f'int({a.t})'))
        elif op == 0x4A: a = P(st); st.append(E(f'Number({a.t})'))
        elif op == 0x4B: a = P(st); st.append(E(f'String({a.t})'))
        elif op == 0x44: a = P(st); st.append(E('typeof ' + par(a, 90), 90))
        elif op == 0x50: a = P(st); st.append(E(f'{par(a,70)} + 1', 70, 'bin', a, E('1'), '+'))
        elif op == 0x51: a = P(st); st.append(E(f'{par(a,70)} - 1', 70, 'bin', a, E('1'), '-'))
        elif op == 0x32 or op == 0x36: a = P(st); st.append(E(f'ord({a.t})'))
        elif op == 0x33 or op == 0x37: a = P(st); st.append(E(f'chr({a.t})'))
        elif op == 0x30: a = P(st); st.append(E(f'random({a.t})'))
        elif op == 0x34: st.append(E('getTimer()'))
        elif op == 0x45: a = P(st); st.append(E(f'targetPath({a.t})'))
        elif op in (0x15, 0x35): c = P(st); i_ = P(st); s = P(st); st.append(E(f'substring({s.t}, {i_.t}, {c.t})'))
        elif op == 0x1C:
            n = P(st); st.append(E(self.name_of(n), 100, 'var', n))
        elif op == 0x1D:
            v = P(st); n = P(st); self.stmt(out, f'{self.name_of(n)} = {v.t};')
        elif op == 0x3C:
            v = P(st); n = P(st); self.stmt(out, f'var {self.name_of(n)} = {v.t};')
        elif op == 0x41:
            n = P(st); self.stmt(out, f'var {self.name_of(n)};')
        elif op == 0x4E:
            n = P(st); o = P(st); st.append(self.member(o, n))
        elif op == 0x4F:
            v = P(st); n = P(st); o = P(st); self.stmt(out, f'{self.member(o, n).t} = {v.t};')
        elif op == 0x87:
            v = st[-1] if st else E('<UNDERFLOW>')
            nm = self.regname(x.args[0])
            st[-1:] = [E(f'{nm} = {v.t}', 10, 'assign')] if st else [E(f'{nm} = ?', 10, 'assign')]
            st[-1].a = v
            # keep value semantic: reading the register later uses regname
            self._last_store = (x.args[0], v)
        elif op == 0x4C: a = st[-1] if st else E('<UNDERFLOW>'); st.append(a)
        elif op == 0x4D:
            if len(st) >= 2: st[-1], st[-2] = st[-2], st[-1]
        elif op == 0x3D:
            n = P(st); args = self.call_args(st); st.append(E(f'{self.name_of(n)}({", ".join(a.t for a in args)})'))
        elif op == 0x52:
            n = P(st); o = P(st); args = self.call_args(st)
            a = ', '.join(a.t for a in args)
            if n.k == 'undef' or (n.k == 'str' and n.a == ''): st.append(E(f'{par(o,100)}({a})'))
            elif n.k == 'str' and IDENT.match(n.a): st.append(E(f'{par(o,100)}.{n.a}({a})'))
            else: st.append(E(f'{par(o,100)}[{n.t}]({a})'))
        elif op == 0x40:
            n = P(st); args = self.call_args(st); st.append(E(f'new {self.name_of(n)}({", ".join(a.t for a in args)})', 95))
        elif op == 0x53:
            n = P(st); o = P(st); args = self.call_args(st)
            st.append(E(f'new {par(o,100)}.{n.a if n.k=="str" else "["+n.t+"]"}({", ".join(a.t for a in args)})', 95))
        elif op == 0x42:
            args = self.call_args(st); st.append(E('[' + ', '.join(a.t for a in args) + ']'))
        elif op == 0x43:
            n = P(st); cnt = int(n.a) if n.k == 'num' else 0
            items = []
            for _ in range(cnt):
                v = P(st); k = P(st); items.append((k, v))
            items.reverse()
            st.append(E('{' + ', '.join(f'{(k.a if k.k=="str" and IDENT.match(k.a) else k.t)}: {v.t}' for k, v in items) + '}'))
        elif op == 0x3E: v = P(st); self.stmt(out, f'return {v.t};')
        elif op == 0x2A: v = P(st); self.stmt(out, f'throw {v.t};')
        elif op == 0x3A: n = P(st); o = P(st); st.append(E(f'delete {self.member(o, n).t}', 90))
        elif op == 0x3B: n = P(st); st.append(E(f'delete {self.name_of(n)}', 90))
        elif op == 0x22:
            i_ = P(st); tg = P(st)
            pn = PROPS[int(i_.a)] if i_.k == 'num' and 0 <= int(i_.a) < len(PROPS) else f'prop{i_.t}'
            st.append(E(f'{par(tg,100)}.{pn}' if not (tg.k=='str' and tg.a=='') else pn))
        elif op == 0x23:
            v = P(st); i_ = P(st); tg = P(st)
            pn = PROPS[int(i_.a)] if i_.k == 'num' and 0 <= int(i_.a) < len(PROPS) else f'prop{i_.t}'
            self.stmt(out, f'{par(tg,100)}.{pn} = {v.t};' if not (tg.k=='str' and tg.a=='') else f'{pn} = {v.t};')
        elif op == 0x24: d = P(st); n = P(st); s = P(st); self.stmt(out, f'duplicateMovieClip({s.t}, {n.t}, {d.t});')
        elif op == 0x25: a = P(st); self.stmt(out, f'removeMovieClip({a.t});')
        elif op == 0x26: a = P(st); self.stmt(out, f'trace({a.t});')
        elif op == 0x27:
            tg = P(st); lock = P(st); con = P(st)
            if con.k == 'num' and con.a: b = P(st); r = P(st); t_ = P(st); l = P(st); self.stmt(out, f'startDrag({tg.t}, {lock.t}, {l.t}, {t_.t}, {r.t}, {b.t});')
            else: self.stmt(out, f'startDrag({tg.t}, {lock.t});')
        elif op == 0x28: self.stmt(out, 'stopDrag();')
        elif op == 0x04: self.stmt(out, 'nextFrame();')
        elif op == 0x05: self.stmt(out, 'prevFrame();')
        elif op == 0x06: self.stmt(out, 'play();')
        elif op == 0x07: self.stmt(out, 'stop();')
        elif op == 0x08: self.stmt(out, 'toggleHighQuality();')
        elif op == 0x09: self.stmt(out, 'stopAllSounds();')
        elif op == 0x81: self.stmt(out, f'gotoFrame({x.args[0] + 1});')
        elif op == 0x8C: self.stmt(out, f'gotoLabel({strlit(x.args[0])});')
        elif op == 0x9F:
            f = P(st); play = x.args[0] & 1
            self.stmt(out, f'{"gotoAndPlay" if play else "gotoAndStop"}({f.t});')
        elif op == 0x8B: self.stmt(out, f'setTarget({strlit(x.args[0])});')
        elif op == 0x20: a = P(st); self.stmt(out, f'setTarget({a.t});')
        elif op == 0x83: self.stmt(out, f'getURL({strlit(x.args[0])}, {strlit(x.args[1])});')
        elif op == 0x9A: tg = P(st); u = P(st); self.stmt(out, f'getURL({u.t}, {tg.t});')
        elif op == 0x9E: a = P(st); self.stmt(out, f'call({a.t});')
        elif op == 0x69: sup = P(st); sub = P(st); self.stmt(out, f'{sub.t}.extends({sup.t});')
        elif op == 0x2C:
            c = P(st); args = self.call_args(st); self.stmt(out, f'{c.t}.implements({", ".join(a.t for a in args)});')
        elif op in (0x46, 0x55):
            o = P(st); st.append(E('null')); st.append(E(f'/*enum*/{o.t}'))
        elif op == 0x9B or op == 0x8E:
            name = x.args[0]; params = x.args[1]
            regs = x.args[2] if op == 0x8E else {}
            d = Decomp(x.body, self.pool, regs, name)
            d.depth = self.depth + 1
            body = d.run()
            hdr = f'function {name}({", ".join(params)}) {{' if True else ''
            txt = hdr + ('\n' + '\n'.join('    ' + l for l in body) if body else '') + '\n}'
            if name:
                self.stmt(out, txt)
            else:
                st.append(E(txt, 100, 'func'))
        elif op == 0x94:
            o = P(st)
            d = Decomp(x.body, self.pool, self.regs, self.fname); d.depth = self.depth
            body = d.run()
            self.stmt(out, f'with ({o.t}) {{\n' + '\n'.join('    ' + l for l in body) + '\n}')
        elif op == 0x8F:
            tb, cb, fb = x.body
            def sub(b):
                d = Decomp(b, self.pool, self.regs, self.fname); return d.run()
            t = sub(tb); c = sub(cb) if cb else []; f = sub(fb) if fb else []
            s = 'try {\n' + '\n'.join('    ' + l for l in t) + '\n}'
            if x.args[0] & 1:
                cn = self.regname(x.args[1]) if x.args[0] & 4 else x.args[1]
                s += f' catch ({cn}) {{\n' + '\n'.join('    ' + l for l in c) + '\n}'
            if x.args[0] & 2: s += ' finally {\n' + '\n'.join('    ' + l for l in f) + '\n}'
            self.stmt(out, s)
        elif op in (0x8A, 0x8D): self.stmt(out, f'/*waitForFrame*/')
        elif op == 0x2D: self.stmt(out, '/*FSCommand2*/')
        else:
            out.append(f'/*UNHANDLED op {hex(op)} {x.args}*/')

    def run(self):
        st = []
        # register store followed by pop: statement 'r = v'
        out = self.block(0, len(self.ins), st, [])
        if st: out.append(f'/* leftover stack: {[e.t for e in st]} */')
        return out

def decompile_code(code, pool=None):
    ins = parse_code(code)
    d = Decomp(ins, pool or [], {}, '')
    try:
        return '\n'.join(d.run())
    except Exception as e:
        import traceback
        return f'/* DECOMPILE FAILED: {e}\n{traceback.format_exc()} */'

def disasm(ins, pool=None, indent=0):
    out = []
    pool = pool or []
    for x in ins:
        nm = NAMES.get(x.op, hex(x.op))
        if x.op == 0x88: pool = x.args; out.append(' ' * indent + f'{x.off:5d} ConstantPool {len(x.args)}'); continue
        if x.op == 0x96:
            a = []
            for t, v in x.args:
                if t == 'const': a.append(strlit(pool[v]) if v < len(pool) else f'c{v}')
                elif t == 'str': a.append(strlit(v))
                elif t == 'reg': a.append(f'r{v}')
                else: a.append(str(v))
            out.append(' ' * indent + f'{x.off:5d} Push ' + ', '.join(a))
        elif x.op in (0x99, 0x9D): out.append(' ' * indent + f'{x.off:5d} {"Jump" if x.op == 0x99 else "If"} -> {x.nxt + x.args[0]}')
        elif x.op in (0x9B, 0x8E):
            out.append(' ' * indent + f'{x.off:5d} {"DefineFunction2" if x.op == 0x8E else "DefineFunction"} {x.args[0]}({x.args[1]}) {{')
            out += disasm(x.body, pool, indent + 4); out.append(' ' * indent + '}')
        else: out.append(' ' * indent + f'{x.off:5d} {nm} {x.args if x.args else ""}')
    return out
