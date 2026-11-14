import random, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from levelgen_exp import solve, deal

def paired(n, k, trials, colors=None, h=4, seed=7):
    rng = random.Random(seed); both = std_only = q_only = neither = 0
    for _ in range(trials):
        st, per = deal(rng, n, h, k, colors)
        q = [c for c in range(len(per)) for _ in range(per[c])]; rng.shuffle(q)
        a, _ = solve(st, h, None); b, _ = solve(st, h, tuple(q))
        if a and b: both += 1
        elif a: std_only += 1
        elif b: q_only += 1
        else: neither += 1
    print(f"n={n} colors={colors or n} k={k}: both={both} std_only={std_only} queue_only={q_only} neither={neither} / {trials}", flush=True)

for a in eval(sys.argv[1]): paired(**a)
