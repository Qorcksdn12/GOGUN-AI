import zlib, struct, io

TAGNAMES = {0:'End',1:'ShowFrame',2:'DefineShape',4:'PlaceObject',5:'RemoveObject',6:'DefineBits',7:'DefineButton',
8:'JPEGTables',9:'SetBackgroundColor',10:'DefineFont',11:'DefineText',12:'DoAction',13:'DefineFontInfo',
14:'DefineSound',15:'StartSound',17:'DefineButtonSound',18:'SoundStreamHead',19:'SoundStreamBlock',
20:'DefineBitsLossless',21:'DefineBitsJPEG2',22:'DefineShape2',23:'DefineButtonCxform',24:'Protect',
26:'PlaceObject2',28:'RemoveObject2',32:'DefineShape3',33:'DefineText2',34:'DefineButton2',
35:'DefineBitsJPEG3',36:'DefineBitsLossless2',37:'DefineEditText',39:'DefineSprite',43:'FrameLabel',
45:'SoundStreamHead2',46:'DefineMorphShape',48:'DefineFont2',56:'ExportAssets',57:'ImportAssets',
58:'EnableDebugger',59:'DoInitAction',60:'DefineVideoStream',61:'VideoFrame',62:'DefineFontInfo2',
63:'DebugID',64:'EnableDebugger2',65:'ScriptLimits',66:'SetTabIndex',69:'FileAttributes',70:'PlaceObject3',
71:'ImportAssets2',73:'DefineFontAlignZones',74:'CSMTextSettings',75:'DefineFont3',76:'SymbolClass',
77:'Metadata',78:'DefineScalingGrid',82:'DoABC',83:'DefineShape4',84:'DefineMorphShape2',86:'DefineSceneAndFrameLabelData',
87:'DefineBinaryData',88:'DefineFontName',90:'DefineBitsJPEG4'}

class BitReader:
    def __init__(self, data, pos=0):
        self.d = data; self.p = pos; self.bit = 0
    def align(self):
        if self.bit: self.p += 1; self.bit = 0
    def ub(self, n):
        v = 0
        for _ in range(n):
            byte = self.d[self.p]
            v = (v << 1) | ((byte >> (7 - self.bit)) & 1)
            self.bit += 1
            if self.bit == 8: self.bit = 0; self.p += 1
        return v
    def sb(self, n):
        v = self.ub(n)
        if n and v & (1 << (n-1)): v -= (1 << n)
        return v

def read_rect(d, pos=0):
    br = BitReader(d, pos)
    n = br.ub(5)
    xmin = br.sb(n); xmax = br.sb(n); ymin = br.sb(n); ymax = br.sb(n)
    br.align()
    return (xmin, xmax, ymin, ymax), br.p

def load(path):
    raw = open(path, 'rb').read()
    sig = raw[:3]; ver = raw[3]
    if sig == b'CWS': body = zlib.decompress(raw[8:])
    elif sig == b'FWS': body = raw[8:]
    else: raise Exception('unsupported ' + str(sig))
    rect, p = read_rect(body, 0)
    fr = body[p+1] + body[p]/256.0
    nframes = struct.unpack('<H', body[p+2:p+4])[0]
    return dict(version=ver, rect=rect, fps=fr, frames=nframes, body=body, tagstart=p+4)

def iter_tags(body, pos=0, end=None):
    end = len(body) if end is None else end
    while pos < end:
        h = struct.unpack('<H', body[pos:pos+2])[0]; pos += 2
        t = h >> 6; l = h & 0x3f
        if l == 0x3f:
            l = struct.unpack('<I', body[pos:pos+4])[0]; pos += 4
        yield t, body[pos:pos+l], pos
        pos += l
        if t == 0: break
