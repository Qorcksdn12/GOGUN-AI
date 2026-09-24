import ctypes, json, numpy as np, sys, os
lib = ctypes.CDLL(os.environ.get('SIMLIB', './libsim.so'))
lib.env_size.restype = ctypes.c_int
lib.env_get.restype = ctypes.c_double; lib.env_get.argtypes = [ctypes.c_void_p, ctypes.c_int]
lib.env_reset.argtypes = [ctypes.c_void_p, ctypes.c_uint32, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int]
lib.env_step.argtypes = [ctypes.c_void_p, ctypes.c_int]
lib.env_obs.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
sz = lib.env_size(); buf = ctypes.create_string_buffer(sz); ptr = ctypes.addressof(buf)
eps = json.load(open('difftrace.json'))
bad = 0; total = 0; maxobs = 0.0
for ei, ep in enumerate(eps):
    lib.env_reset(ptr, ep['seed'], ep['level'], ep['count'], ep['phase'], 1)
    for t, (a, row) in enumerate(zip(ep["acts"], ep["rows"])):
        lib.env_step(ptr, a)
        o = np.zeros(64, np.float32); lib.env_obs(ptr, o.ctypes.data)
        st = [lib.env_get(ptr, i) for i in (0, 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13)]
        js = row[0:13]
        total += 1
        d = np.abs(np.array(st) - np.array(js))
        dobs = np.abs(o - np.array(row[13:], np.float32)).max()
        maxobs = max(maxobs, float(dobs))
        if d.max() > 1e-6 or dobs > 1e-4:
            bad += 1
            if bad <= 5: print('MISMATCH ep', ei, 't', t, 'state diff', d.round(6).tolist(), 'obs diff', float(dobs))
print('compared', total, 'steps; mismatches', bad, '; max obs diff', maxobs)
