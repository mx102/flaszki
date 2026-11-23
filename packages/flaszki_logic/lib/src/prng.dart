/// Deterministic PRNG (ADR 0002): SplitMix seeding → xoshiro128**, Lemire
/// bounded ints. 32-bit integer ops only, no floats; every intermediate stays
/// below 2^53, so output is identical on VM, AOT, wasm and dart2js.
library;

const int _two32 = 0x100000000;

/// Largest bound accepted by [Prng.nextInt] (keeps `uint32 × bound` < 2^53).
const int maxPrngBound = 1 << 21;

/// `a * b mod 2^32` for uint32 `a`, `b` without exceeding 2^53.
int mul32(int a, int b) {
  final lo = (a & 0xFFFF) * b; // < 2^48
  final hi = (((a >>> 16) * b) % 65536) * 65536;
  return (lo + hi) % _two32;
}

int _rotl(int x, int k) => ((x * (1 << k)) % _two32) + (x >>> (32 - k));

/// MurmurHash3 32-bit finalizer; maps uint32 → uint32.
int fmix32(int z) {
  z = mul32(z ^ (z >>> 16), 0x85ebca6b);
  z = mul32(z ^ (z >>> 13), 0xc2b2ae35);
  return z ^ (z >>> 16);
}

/// xoshiro128** generator. Mutable; not thread-shared.
class Prng {
  /// Raw xoshiro128** state (uint32 words, not all zero).
  Prng.fromState(this._s0, this._s1, this._s2, this._s3) {
    for (final w in [_s0, _s1, _s2, _s3]) {
      if (w < 0 || w >= _two32) throw ArgumentError.value(w, 'state word');
    }
    if ((_s0 | _s1 | _s2 | _s3) == 0) throw ArgumentError('all-zero state');
  }

  /// Seeds from uint32 [words], e.g. `[generatorVersion, levelNumber,
  /// attempt]`: words are folded with [fmix32], then four SplitMix32 steps
  /// fill the state.
  factory Prng.seed(List<int> words) {
    if (words.isEmpty) throw ArgumentError('no seed words');
    for (final w in words) {
      if (w < 0 || w >= _two32) throw ArgumentError.value(w, 'seed word');
    }
    var st = fmix32(words.first);
    for (var i = 1; i < words.length; i++) {
      st = fmix32(st ^ words[i]);
    }
    int next() {
      st = (st + 0x9e3779b9) % _two32;
      return fmix32(st);
    }

    final s = [next(), next(), next(), next()];
    if ((s[0] | s[1] | s[2] | s[3]) == 0) s[0] = 1;
    return Prng.fromState(s[0], s[1], s[2], s[3]);
  }

  int _s0, _s1, _s2, _s3;

  /// Next uint32 in `[0, 2^32)`.
  int nextUint32() {
    final result = mul32(_rotl(mul32(_s1, 5), 7), 9);
    final t = (_s1 * 512) % _two32;
    _s2 ^= _s0;
    _s3 ^= _s1;
    _s1 ^= _s2;
    _s0 ^= _s3;
    _s2 ^= t;
    _s3 = _rotl(_s3, 11);
    return result;
  }

  /// Uniform int in `[0, bound)`, `1 <= bound <= 2^21` (Lemire's method).
  int nextInt(int bound) {
    if (bound < 1 || bound > maxPrngBound) {
      throw ArgumentError.value(bound, 'bound', 'must be in 1..2^21');
    }
    var m = nextUint32() * bound;
    var low = m % _two32;
    if (low < bound) {
      final threshold = (_two32 - bound) % bound;
      while (low < threshold) {
        m = nextUint32() * bound;
        low = m % _two32;
      }
    }
    return m ~/ _two32;
  }

  /// In-place Fisher–Yates shuffle (from the end, `j = nextInt(i + 1)`).
  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final t = list[i];
      list[i] = list[j];
      list[j] = t;
    }
  }
}
