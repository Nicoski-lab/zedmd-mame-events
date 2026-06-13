BASE=0x6000
dumps=[]
for line in open("/userdata/system/zedmd-mame/dkdump.log"):
    if not line.startswith("DUMP"): continue
    p=line.split()
    dumps.append((int(p[1].split("=")[1]), bytes.fromhex(p[2])))
print(f"{len(dumps)} dumps, {len(dumps[0][1])} bytes each")
def bcdb(x):
    hi,lo=x>>4,x&0xf
    return hi*10+lo if hi<=9 and lo<=9 else None
def dec(b,off,w,order,mode):
    bs=[b[off+i] for i in range(w)]
    if order=="rev": bs=bs[::-1]
    if mode=="bcd":
        v=0
        for x in bs:
            d=bcdb(x)
            if d is None: return None
            v=v*100+d
        return v
    v=0
    for x in bs: v=v*256+x
    return v
N=len(dumps[0][1]); cands=[]
for off in range(N):
    for w in (1,2,3,4):
        if off+w>N: continue
        for order in ("fwd","rev"):
            for mode in ("bcd","bin"):
                seq=[];ok=True
                for f,b in dumps:
                    v=dec(b,off,w,order,mode)
                    if v is None: ok=False;break
                    seq.append(v)
                if not ok: continue
                for mult,tgt in ((1,1000),(100,10)):
                    if max(seq)!=tgt: continue
                    pi=seq.index(tgt); rise=seq[:pi+1]
                    if any(rise[i]<rise[i-1] for i in range(1,len(rise))): continue
                    if len(set(rise))<3: continue
                    cands.append((BASE+off,w,order,mode,mult,seq))
for off,w,order,mode,mult,seq in cands:
    print(f"0x{off:04x} w{w} {order} {mode} x{mult} seq={seq}")
print(f"total: {len(cands)}")
