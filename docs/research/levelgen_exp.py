"""Empirical solvability of random water-sort deals (water rule, cap h).
Flask = tuple bottom->top. State canonicalised as sorted tuple of flasks.
Queue mode: queue of colors; when head color has a complete flask on board it is removed (sealed).
DFS with visited set; node limit -> 'unknown'."""
import random, sys, time

def moves(state, h):
    n = len(state)
    for i in range(n):
        s = state[i]
        if not s: continue
        c = s[-1]
        run = 1
        while run < len(s) and s[-1 - run] == c: run += 1
        for j in range(n):
            if i == j: continue
            d = state[j]
            if len(d) >= h: continue
            if d and d[-1] != c: continue
            if not d and run == len(s): continue  # useless: mono into empty
            k = min(run, h - len(d))
            ns = list(state)
            ns[i] = s[:-k]; ns[j] = d + (c,) * k
            yield ns, bool(k == run and d)

def settle(ns, queue, h):
    q = list(queue)
    changed = True
    while q and changed:
        changed = False
        for idx, f in enumerate(ns):
            if len(f) == h and f[0] == q[0] and all(x == f[0] for x in f):
                ns = ns[:idx] + ns[idx + 1:]; q.pop(0); changed = True; break
    return ns, tuple(q)

def solved_std(state, h):
    return all((not f) or (len(f) == h and len(set(f)) == 1) for f in state)

def solve(state, h, queue=None, limit=200000):
    start = tuple(sorted(state))
    if queue is not None:
        s2, q2 = settle(list(start), queue, h); start = (tuple(sorted(s2)), q2)
    else:
        start = (start, None)
    seen = {start}; stack = [start]; nodes = 0
    while stack:
        st, q = stack.pop(); nodes += 1
        if (q is not None and not q) or (q is None and solved_std(st, h)): return True, nodes
        if nodes > limit: return None, nodes
        succ = []
        for ns, merging in moves(st, h):
            if q is not None:
                ns, nq = settle(ns, q, h)
            else:
                nq = None
            key = (tuple(sorted(ns)), nq)
            if key not in seen:
                seen.add(key); succ.append((merging, key))
        succ.sort(key=lambda x: x[0])
        stack.extend(k for _, k in succ)
    return False, nodes

def deal(rng, n, h, k, colors=None):
    colors = colors or n
    units = []
    per = [n // colors + (1 if i < n % colors else 0) for i in range(colors)]
    for c in range(colors): units += [c] * (h * per[c])
    rng.shuffle(units)
    st = [tuple(units[i * h:(i + 1) * h]) for i in range(n)] + [()] * k
    return st, per

def run(n, k, trials, h=4, queue=False, colors=None, seed=1, limit=200000):
    rng = random.Random(seed)
    res = {True: 0, False: 0, None: 0}; t0 = time.time(); maxnodes = 0
    for _ in range(trials):
        st, per = deal(rng, n, h, k, colors)
        q = None
        if queue:
            q = [c for c in range(len(per)) for _ in range(per[c])]; rng.shuffle(q); q = tuple(q)
        r, nodes = solve(st, h, q, limit); res[r] += 1; maxnodes = max(maxnodes, nodes)
    dt = (time.time() - t0) / trials
    print(f"n={n} colors={colors or n} k={k} h={h} queue={queue}: solvable={res[True]} unsolvable={res[False]} unknown={res[None]} / {trials}  avg {dt*1000:.0f} ms/inst (py)  max nodes {maxnodes}", flush=True)

if __name__ == "__main__":
    for args in eval(sys.argv[1]):
        run(**args)
