import 'dart:typed_data';

import 'x25519_field.dart' as x25519Field;
import 'package:fixnum/fixnum.dart';

/*
  Ed25519 is EdDSA instantiated with:
+-----------+-------------------------------------------------------+
| Parameter |                                                 Value |
+-----------+-------------------------------------------------------+
|     p     |     p of edwards25519 in [RFC7748] (i.e., 2^255 - 19) |
|     b     |                                                   256 |
|  encoding |    255-bit little-endian encoding of {0, 1, ..., p-1} |
|  of GF(p) |                                                       |
|    H(x)   |            SHA-512(dom2(phflag,context)||x) [RFC6234] |
|     c     |       base 2 logarithm of cofactor of edwards25519 in |
|           |                                   [RFC7748] (i.e., 3) |
|     n     |                                                   254 |
|     d     |  d of edwards25519 in [RFC7748] (i.e., -121665/121666 |
|           | = 370957059346694393431380835087545651895421138798432 |
|           |                           19016388785533085940283555) |
|     a     |                                                    -1 |
|     B     | (X(P),Y(P)) of edwards25519 in [RFC7748] (i.e., (1511 |
|           | 22213495354007725011514095885315114540126930418572060 |
|           | 46113283949847762202, 4631683569492647816942839400347 |
|           |      5163141307993866256225615783033603165251855960)) |
|     L     |             order of edwards25519 in [RFC7748] (i.e., |
|           |        2^252+27742317777372353535851937790883648493). |
|    PH(x)  |                       x (i.e., the identity function) |
+-----------+-------------------------------------------------------+
Table 1: Parameters of Ed25519
 */

/**
 * AMS 2021: Supporting curve point operations for all EC crypto primitives in eddsa package
 * Directly ported from BouncyCastle implementation of Ed25519 RFC8032 https://tools.ietf.org/html/rfc8032
 * Licensing: https://www.bouncycastle.org/licence.html
 * Copyright (c) 2000 - 2021 The Legion of the Bouncy Castle Inc. (https://www.bouncycastle.org)
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

final _precomp = _precompute();
final _precompBaseTable = _precomp.$1;
final _precompBase = _precomp.$2;

int mulAddTo256(Int32List x, Int32List y, Int32List zz) {
  final y_0 = Int64(y[0]) & M;
  final y_1 = Int64(y[1]) & M;
  final y_2 = Int64(y[2]) & M;
  final y_3 = Int64(y[3]) & M;
  final y_4 = Int64(y[4]) & M;
  final y_5 = Int64(y[5]) & M;
  final y_6 = Int64(y[6]) & M;
  final y_7 = Int64(y[7]) & M;
  Int64 zc = Int64.ZERO;
  for (int i = 0; i < 8; i++) {
    var c = Int64.ZERO;
    final x_i = Int64(x[i]) & M;
    c += x_i * y_0 + (Int64(zz[i + 0]) & M);
    zz[i + 0] = c.toInt32().toInt();
    c = c.shiftRightUnsigned(32);
    c += x_i * y_1 + (Int64(zz[i + 1]) & M);
    zz[i + 1] = c.toInt32().toInt();
    c = c.shiftRightUnsigned(32);
    c += x_i * y_2 + (Int64(zz[i + 2]) & M);
    zz[i + 2] = c.toInt32().toInt();
    c = c.shiftRightUnsigned(32);
    c += x_i * y_3 + (Int64(zz[i + 3]) & M);
    zz[i + 3] = c.toInt32().toInt();
    c = c.shiftRightUnsigned(32);
    c += x_i * y_4 + (Int64(zz[i + 4]) & M);
    zz[i + 4] = c.toInt32().toInt();
    c = c.shiftRightUnsigned(32);
    c += x_i * y_5 + (Int64(zz[i + 5]) & M);
    zz[i + 5] = c.toInt32().toInt();
    c = c.shiftRightUnsigned(32);
    c += x_i * y_6 + (Int64(zz[i + 6]) & M);
    zz[i + 6] = c.toInt32().toInt();
    c = c.shiftRightUnsigned(32);
    c += x_i * y_7 + (Int64(zz[i + 7]) & M);
    zz[i + 7] = c.toInt32().toInt();
    c = c.shiftRightUnsigned(32);
    zc += c + zz[i + 8] & M;
    zz[i + 8] = zc.toInt32().toInt();
    zc = zc.shiftRightUnsigned(32);
  }
  return zc.toInt32().toInt();
}

bool gte256(Int32List x, Int32List y) {
  for (int i = 7; i >= 0; i--) {
    final x_i = Int32(x[i]) ^ Int32.MIN_VALUE;
    final y_i = Int32(y[i]) ^ Int32.MIN_VALUE;
    if (x_i < y_i) return false;
    if (x_i > y_i) return true;
  }
  return true;
}

void cmov(int len, Int32 mask, Int32List x, int xOff, Int32List z, int zOff) {
  var maskv = mask;
  maskv = -(maskv & 1);
  for (int i = 0; i < len; i++) {
    var z_i = Int32(z[zOff + i]);
    final diff = z_i ^ x[xOff + i];
    z_i ^= (diff & maskv);
    z[zOff + i] = z_i.toInt();
  }
}

int cadd(int len, Int32 mask, Int32List x, Int32List y, Int32List z) {
  final m = -(mask & 1).toInt64() & M;
  Int64 c = Int64.ZERO;
  for (int i = 0; i < len; i++) {
    c += (Int64(x[i]) & M) + (Int64(y[i]) & m);
    z[i] = c.toInt32().toInt();
    c = c.shiftRightUnsigned(32);
  }
  return c.toInt32().toInt();
}

int shiftDownBit(int len, Int32List z, int c) {
  var i = len;
  var cv = Int32(c);
  while (--i >= 0) {
    final next = Int32(z[i]);
    z[i] = ((next.shiftRightUnsigned(1)) | (cv << 31)).toInt();
    cv = next;
  }
  return (cv << 31).toInt();
}

Int32 shuffle2(Int32 x) {
  var t = Int32.ZERO;
  var xv = x;
  t = (xv ^ (xv.shiftRightUnsigned(7))) & 0x00aa00aa;
  xv ^= (t ^ (t << 7));
  t = (xv ^ (xv.shiftRightUnsigned(14))) & 0x0000cccc;
  xv ^= (t ^ (t << 14));
  t = (xv ^ (xv.shiftRightUnsigned(4))) & 0x00f000f0;
  xv ^= (t ^ (t << 4));
  t = (xv ^ (xv.shiftRightUnsigned(8))) & 0x0000ff00;
  xv ^= (t ^ (t << 8));
  return xv;
}

bool areAllZeroes(Int8List buf, int off, int len) {
  int bits = 0;
  for (int i = 0; i < len; i++) bits |= buf[off + i];
  return bits == 0;
}

Int8List calculateS(Int8List r, Int8List k, Int8List s) {
  final t = Int32List(SCALAR_INTS * 2);
  decodeScalar(r, 0, t);
  final u = Int32List(SCALAR_INTS * 2);
  decodeScalar(k, 0, u);
  final v = Int32List(SCALAR_INTS * 2);
  decodeScalar(s, 0, v);
  mulAddTo256(u, v, t);
  final result = Int8List(SCALAR_BYTES * 2);
  for (int i = 0; i < t.length; i++) encode32(t[i], result, i * 4);
  return reduceScalar(result);
}

bool checkPointVar(Int8List p) {
  final t = Int32List(8);
  decode32(p, 0, t, 0, 8);
  t[7] = (Int32(t[7]) & 0x7fffffff).toInt();
  return !gte256(t, P);
}

bool checkScalarVar(Int8List s) {
  final n = Int32List(SCALAR_INTS);
  decodeScalar(s, 0, n);
  return !gte256(n, L);
}

int decode24(Int8List bs, int off) {
  var n = (bs[off] & 0xff);
  n |= ((bs[off + 1] & 0xff) << 8);
  n |= ((bs[off + 2] & 0xff) << 16);
  return n;
}

int decode32v(Int8List bs, int off) {
  var n = (bs[off].toByte & 0xff);
  n |= ((bs[off + 1].toByte & 0xff) << 8);
  n |= ((bs[off + 2].toByte & 0xff) << 16);
  n |= (bs[off + 3].toByte << 24);
  return n;
}

void decode32(Int8List bs, int bsOff, Int32List n, int nOff, int nLen) {
  for (int i = 0; i < nLen; i++) n[nOff + i] = decode32v(bs, bsOff + i * 4);
}

bool decodePointVar(Int8List p, int pOff, bool negate, PointExt r) {
  final py = Int8List.fromList(p.sublist(pOff, pOff + POINT_BYTES));
  if (!checkPointVar(py)) return false;
  final x_0 = (py[POINT_BYTES - 1] & 0x80) >>> 7;
  py[POINT_BYTES - 1] = (py[POINT_BYTES - 1] & 0x7f).toByte;
  x25519Field.decode(py, 0, r.y);
  final u = x25519Field.create;
  final v = x25519Field.create;
  x25519Field.sqr(r.y, u);
  x25519Field.mul2(C_d, u, v);
  x25519Field.subOne(u);
  x25519Field.addOne1(v);
  if (!x25519Field.sqrtRatioVar(u, v, r.x)) return false;
  x25519Field.normalize(r.x);
  if (x_0 == 1 && x25519Field.isZeroVar(r.x)) return false;
  if (negate ^ (x_0 != (r.x[0] & 1))) x25519Field.negate(r.x, r.x);
  pointExtendXY(r);
  return true;
}

void decodeScalar(Int8List k, int kOff, Int32List n) =>
    decode32(k, kOff, n, 0, SCALAR_INTS);

void encode24(int n, Int8List bs, int off) {
  bs[off] = n.toByte;
  bs[off + 1] = (n >>> 8).toByte;
  bs[off + 2] = (n >>> 16).toByte;
}

void encode32(int n, Int8List bs, int off) {
  bs[off] = n.toByte;
  bs[off + 1] = (n >>> 8).toByte;
  bs[off + 2] = (n >>> 16).toByte;
  bs[off + 3] = (n >>> 24).toByte;
}

void encode56(Int64 n, Int8List bs, int off) {
  encode32(n.toInt32().toInt(), bs, off);
  encode24((n.shiftRightUnsigned(32)).toInt32().toInt(), bs, off + 4);
}

void encodePoint(PointAccum p, Int8List r, int rOff) {
  final x = x25519Field.create;
  final y = x25519Field.create;
  x25519Field.inv(p.z, y);
  x25519Field.mul2(p.x, y, x);
  x25519Field.mul2(p.y, y, y);
  x25519Field.normalize(x);
  x25519Field.normalize(y);
  x25519Field.encode(y, r, rOff);
  r[rOff + POINT_BYTES - 1] =
      (r[rOff + POINT_BYTES - 1] | ((x[0] & 1) << 7)).toByte;
}

Int8List getWNAF(Int32List n, int width) {
  final t = Int32List(SCALAR_INTS * 2);
  var tPos = t.length;
  var c = Int32.ZERO;
  var i = SCALAR_INTS;
  while (--i >= 0) {
    final next = Int32(n[i]);
    t[--tPos] = ((next.shiftRightUnsigned(16)) | (c << 16)).toInt32().toInt();
    c = next;
    t[--tPos] = c.toInt();
  }
  final ws = Int8List(256);
  final pow2 = 1 << width;
  final mask = pow2 - 1;
  final sign = pow2 >>> 1;
  var j = 0;
  var carry = 0;
  i = 0;
  while (i < t.length) {
    final word = t[i];
    while (j < 16) {
      final word16 = word >>> j;
      final bit = word16 & 1;
      if (bit == carry) {
        j += 1;
      } else {
        var digit = (word16 & mask) + carry;
        carry = digit & sign;
        digit -= (carry << 1);
        carry >>>= (width - 1);
        ws[(i << 4) + j] = digit.toByte;
        j += width;
      }
    }
    i += 1;
    j -= 16;
  }
  return ws;
}

void scalarMultBaseYZ(Int8List k, int kOff, Int32List y, Int32List z) {
  final n = Int8List(SCALAR_BYTES);
  pruneScalar(k, kOff, n);
  final p = PointAccum.create();
  scalarMultBase(n, p);
  x25519Field.copy(p.y, 0, y, 0);
  x25519Field.copy(p.z, 0, z, 0);
}

void pointAddVar1(bool negate, PointExt p, PointAccum r) {
  final A = x25519Field.create;
  final B = x25519Field.create;
  final C = x25519Field.create;
  final D = x25519Field.create;
  final E = r.u;
  final F = x25519Field.create;
  final G = x25519Field.create;
  final H = r.v;
  late Int32List c;
  late Int32List d;
  late Int32List f;
  late Int32List g;
  if (negate) {
    c = D;
    d = C;
    f = G;
    g = F;
  } else {
    c = C;
    d = D;
    f = F;
    g = G;
  }
  x25519Field.apm(r.y, r.x, B, A);
  x25519Field.apm(p.y, p.x, d, c);
  x25519Field.mul2(A, C, A);
  x25519Field.mul2(B, D, B);
  x25519Field.mul2(r.u, r.v, C);
  x25519Field.mul2(C, p.t, C);
  x25519Field.mul2(C, C_d2, C);
  x25519Field.mul2(r.z, p.z, D);
  x25519Field.add(D, D, D);
  x25519Field.apm(B, A, H, E);
  x25519Field.apm(D, C, g, f);
  x25519Field.carry(g);
  x25519Field.mul2(E, F, r.x);
  x25519Field.mul2(G, H, r.y);
  x25519Field.mul2(F, G, r.z);
}

void pointAddVar2(bool negate, PointExt p, PointExt q, PointExt r) {
  final A = x25519Field.create;
  final B = x25519Field.create;
  final C = x25519Field.create;
  final D = x25519Field.create;
  final E = x25519Field.create;
  final F = x25519Field.create;
  final G = x25519Field.create;
  final H = x25519Field.create;
  late Int32List c;
  late Int32List d;
  late Int32List f;
  late Int32List g;
  if (negate) {
    c = D;
    d = C;
    f = G;
    g = F;
  } else {
    c = C;
    d = D;
    f = F;
    g = G;
  }
  x25519Field.apm(p.y, p.x, B, A);
  x25519Field.apm(q.y, q.x, d, c);
  x25519Field.mul2(A, C, A);
  x25519Field.mul2(B, D, B);
  x25519Field.mul2(p.t, q.t, C);
  x25519Field.mul2(C, C_d2, C);
  x25519Field.mul2(p.z, q.z, D);
  x25519Field.add(D, D, D);
  x25519Field.apm(B, A, H, E);
  x25519Field.apm(D, C, g, f);
  x25519Field.carry(g);
  x25519Field.mul2(E, F, r.x);
  x25519Field.mul2(G, H, r.y);
  x25519Field.mul2(F, G, r.z);
  x25519Field.mul2(E, H, r.t);
}

void pointAddPrecomp(PointPrecomp p, PointAccum r) {
  final A = x25519Field.create;
  final B = x25519Field.create;
  final C = x25519Field.create;
  final E = r.u;
  final F = x25519Field.create;
  final G = x25519Field.create;
  final H = r.v;
  x25519Field.apm(r.y, r.x, B, A);
  x25519Field.mul2(A, p.ymx_h, A);
  x25519Field.mul2(B, p.ypx_h, B);
  x25519Field.mul2(r.u, r.v, C);
  x25519Field.mul2(C, p.xyd, C);
  x25519Field.apm(B, A, H, E);
  x25519Field.apm(r.z, C, G, F);
  x25519Field.carry(G);
  x25519Field.mul2(E, F, r.x);
  x25519Field.mul2(G, H, r.y);
  x25519Field.mul2(F, G, r.z);
}

PointExt pointCopyAccum(PointAccum p) {
  final r = PointExt.create();
  x25519Field.copy(p.x, 0, r.x, 0);
  x25519Field.copy(p.y, 0, r.y, 0);
  x25519Field.copy(p.z, 0, r.z, 0);
  x25519Field.mul2(p.u, p.v, r.t);
  return r;
}

PointExt pointCopyExt(PointExt p) {
  final r = PointExt.create();
  x25519Field.copy(p.x, 0, r.x, 0);
  x25519Field.copy(p.y, 0, r.y, 0);
  x25519Field.copy(p.z, 0, r.z, 0);
  x25519Field.copy(p.t, 0, r.t, 0);
  return r;
}

void pointDouble(PointAccum r) {
  final A = x25519Field.create;
  final B = x25519Field.create;
  final C = x25519Field.create;
  final E = r.u;
  final F = x25519Field.create;
  final G = x25519Field.create;
  final H = r.v;
  x25519Field.sqr(r.x, A);
  x25519Field.sqr(r.y, B);
  x25519Field.sqr(r.z, C);
  x25519Field.add(C, C, C);
  x25519Field.apm(A, B, H, G);
  x25519Field.add(r.x, r.y, E);
  x25519Field.sqr(E, E);
  x25519Field.sub(H, E, E);
  x25519Field.add(C, G, F);
  x25519Field.carry(F);
  x25519Field.mul2(E, F, r.x);
  x25519Field.mul2(G, H, r.y);
  x25519Field.mul2(F, G, r.z);
}

void pointExtendXYAccum(PointAccum p) {
  x25519Field.one(p.z);
  x25519Field.copy(p.x, 0, p.u, 0);
  x25519Field.copy(p.y, 0, p.v, 0);
}

void pointExtendXY(PointExt p) {
  x25519Field.one(p.z);
  x25519Field.mul2(p.x, p.y, p.t);
}

void pointLookup(int block, Int32 index, PointPrecomp p) {
  var off = block * PRECOMP_POINTS * 3 * x25519Field.SIZE;
  for (int i = 0; i < PRECOMP_POINTS; i++) {
    final Int32 mask = ((Int32(i) ^ index) - Int32(1)).toInt32() >> 31;
    cmov(x25519Field.SIZE, mask, _precompBase, off, p.ypx_h, 0);
    off += x25519Field.SIZE;
    cmov(x25519Field.SIZE, mask, _precompBase, off, p.ymx_h, 0);
    off += x25519Field.SIZE;
    cmov(x25519Field.SIZE, mask, _precompBase, off, p.xyd, 0);
    off += x25519Field.SIZE;
  }
}

List<PointExt> pointPrecompVar(PointExt p, int count) {
  final d = PointExt.create();
  pointAddVar2(false, p, p, d);
  final List<PointExt> table = [];
  table.add(pointCopyExt(p));
  for (int i = 1; i < count; i++) {
    table.add(PointExt.create());
    pointAddVar2(false, table[i - 1], d, table[i]);
  }
  return table;
}

void pointSetNeutralAccum(PointAccum p) {
  x25519Field.zero(p.x);
  x25519Field.one(p.y);
  x25519Field.one(p.z);
  x25519Field.zero(p.u);
  x25519Field.one(p.v);
}

void pointSetNeutralExt(PointExt p) {
  x25519Field.zero(p.x);
  x25519Field.one(p.y);
  x25519Field.one(p.z);
  x25519Field.zero(p.t);
}

(List<PointExt>, Int32List) _precompute() {
  // Precomputed table for the base point in verification ladder
  final b = PointExt.create();
  x25519Field.copy(B_x, 0, b.x, 0);
  x25519Field.copy(B_y, 0, b.y, 0);
  pointExtendXY(b);
  final _precompBaseTable = pointPrecompVar(b, 1 << (WNAF_WIDTH_BASE - 2));
  final p = PointAccum.create();
  x25519Field.copy(B_x, 0, p.x, 0);
  x25519Field.copy(B_y, 0, p.y, 0);
  pointExtendXYAccum(p);
  final _precompBase =
      Int32List(PRECOMP_BLOCKS * PRECOMP_POINTS * 3 * x25519Field.SIZE);
  var off = 0;
  for (int b = 0; b < PRECOMP_BLOCKS; b++) {
    final List<PointExt> ds = [];
    final sum = PointExt.create();
    pointSetNeutralExt(sum);
    for (int t = 0; t < PRECOMP_TEETH; t++) {
      final q = pointCopyAccum(p);
      pointAddVar2(true, sum, q, sum);
      pointDouble(p);
      ds.add(pointCopyAccum(p));
      if (b + t != PRECOMP_BLOCKS + PRECOMP_TEETH - 2)
        for (int i = 1; i < PRECOMP_SPACING; i++) pointDouble(p);
    }
    final List<PointExt?> points =
        List.filled(PRECOMP_POINTS, null, growable: false);
    var k = 1;
    points[0] = sum;
    for (int t = 0; t < PRECOMP_TEETH - 1; t++) {
      final size = 1 << t;
      var j = 0;
      while (j < size) {
        points[k] = PointExt.create();
        pointAddVar2(false, points[k - size]!, ds[t], points[k]!);
        j += 1;
        k += 1;
      }
    }
    for (int i = 0; i < PRECOMP_POINTS; i++) {
      final q = points[i]!;
      final x = x25519Field.create;
      final y = x25519Field.create;
      x25519Field.add(q.z, q.z, x);
      x25519Field.inv(x, y);
      x25519Field.mul2(q.x, y, x);
      x25519Field.mul2(q.y, y, y);
      final r = PointPrecomp.create();
      x25519Field.apm(y, x, r.ypx_h, r.ymx_h);
      x25519Field.mul2(x, y, r.xyd);
      x25519Field.mul2(r.xyd, C_d4, r.xyd);
      x25519Field.normalize(r.ypx_h);
      x25519Field.normalize(r.ymx_h);
      x25519Field.copy(r.ypx_h, 0, _precompBase, off);
      off += x25519Field.SIZE;
      x25519Field.copy(r.ymx_h, 0, _precompBase, off);
      off += x25519Field.SIZE;
      x25519Field.copy(r.xyd, 0, _precompBase, off);
      off += x25519Field.SIZE;
    }
  }
  return (_precompBaseTable, _precompBase);
}

void pruneScalar(Int8List n, int nOff, Int8List r) {
  for (int i = 0; i < SCALAR_BYTES; i++) {
    r[i] = n[nOff + i].toByte;
  }
  r[0] = (r[0] & 0xf8).toByte;
  r[SCALAR_BYTES - 1] = (r[SCALAR_BYTES - 1] & 0x7f).toByte;
  r[SCALAR_BYTES - 1] = (r[SCALAR_BYTES - 1] | 0x40).toByte;
}

Int8List reduceScalar(Int8List n) {
  var x00 = Int64(decode32v(n, 0)) & M32L; // x00:32/--
  var x01 = Int64((decode24(n, 4)) << 4) & M32L; // x01:28/--
  var x02 = Int64(decode32v(n, 7)) & M32L; // x02:32/--
  var x03 = Int64((decode24(n, 11)) << 4) & M32L; // x03:28/--
  var x04 = Int64(decode32v(n, 14)) & M32L; // x04:32/--
  var x05 = Int64((decode24(n, 18)) << 4) & M32L; // x05:28/--
  var x06 = Int64(decode32v(n, 21)) & M32L; // x06:32/--
  var x07 = Int64((decode24(n, 25)) << 4) & M32L; // x07:28/--
  var x08 = Int64(decode32v(n, 28)) & M32L; // x08:32/--
  var x09 = Int64((decode24(n, 32)) << 4) & M32L; // x09:28/--
  var x10 = Int64(decode32v(n, 35)) & M32L; // x10:32/--
  var x11 = Int64((decode24(n, 39)) << 4) & M32L; // x11:28/--
  var x12 = Int64(decode32v(n, 42)) & M32L; // x12:32/--
  var x13 = Int64((decode24(n, 46)) << 4) & M32L; // x13:28/--
  var x14 = Int64(decode32v(n, 49)) & M32L; // x14:32/--
  var x15 = Int64((decode24(n, 53)) << 4) & M32L; // x15:28/--
  var x16 = Int64(decode32v(n, 56)) & M32L; // x16:32/--
  var x17 = Int64((decode24(n, 60)) << 4) & M32L; // x17:28/--
  final x18 = Int64(n[63]) & Int64(0xff); // x18:08/-- TODO?
  var t = Int64(0);
  x09 -= x18 * L0; // x09:34/28
  x10 -= x18 * L1; // x10:33/30
  x11 -= x18 * L2; // x11:35/28
  x12 -= x18 * L3; // x12:32/31
  x13 -= x18 * L4; // x13:28/21
  x17 += (x16 >> 28);
  x16 &= M28L; // x17:28/--, x16:28/--
  x08 -= x17 * L0; // x08:54/32
  x09 -= x17 * L1; // x09:52/51
  x10 -= x17 * L2; // x10:55/34
  x11 -= x17 * L3; // x11:51/36
  x12 -= x17 * L4; // x12:41/--
  x07 -= x16 * L0; // x07:54/28
  x08 -= x16 * L1; // x08:54/53
  x09 -= x16 * L2; // x09:55/53
  x10 -= x16 * L3; // x10:55/52
  x11 -= x16 * L4; // x11:51/41
  x15 += (x14 >> 28);
  x14 &= M28L; // x15:28/--, x14:28/--
  x06 -= x15 * L0; // x06:54/32
  x07 -= x15 * L1; // x07:54/53
  x08 -= x15 * L2; // x08:56/--
  x09 -= x15 * L3; // x09:55/54
  x10 -= x15 * L4; // x10:55/53
  x05 -= x14 * L0; // x05:54/28
  x06 -= x14 * L1; // x06:54/53
  x07 -= x14 * L2; // x07:56/--
  x08 -= x14 * L3; // x08:56/51
  x09 -= x14 * L4; // x09:56/--
  x13 += (x12 >> 28);
  x12 &= M28L; // x13:28/22, x12:28/--
  x04 -= x13 * L0; // x04:54/49
  x05 -= x13 * L1; // x05:54/53
  x06 -= x13 * L2; // x06:56/--
  x07 -= x13 * L3; // x07:56/52
  x08 -= x13 * L4; // x08:56/52
  x12 += (x11 >> 28);
  x11 &= M28L; // x12:28/24, x11:28/--
  x03 -= x12 * L0; // x03:54/49
  x04 -= x12 * L1; // x04:54/51
  x05 -= x12 * L2; // x05:56/--
  x06 -= x12 * L3; // x06:56/52
  x07 -= x12 * L4; // x07:56/53
  x11 += (x10 >> 28);
  x10 &= M28L; // x11:29/--, x10:28/--
  x02 -= x11 * L0; // x02:55/32
  x03 -= x11 * L1; // x03:55/--
  x04 -= x11 * L2; // x04:56/55
  x05 -= x11 * L3; // x05:56/52
  x06 -= x11 * L4; // x06:56/53
  x10 += (x09 >> 28);
  x09 &= M28L; // x10:29/--, x09:28/--
  x01 -= x10 * L0; // x01:55/28
  x02 -= x10 * L1; // x02:55/54
  x03 -= x10 * L2; // x03:56/55
  x04 -= x10 * L3; // x04:57/--
  x05 -= x10 * L4; // x05:56/53
  x08 += (x07 >> 28);
  x07 &= M28L; // x08:56/53, x07:28/--
  x09 += (x08 >> 28);
  x08 &= M28L; // x09:29/25, x08:28/--
  t = x08.shiftRightUnsigned(27);
  x09 += t; // x09:29/26
  x00 -= x09 * L0; // x00:55/53
  x01 -= x09 * L1; // x01:55/54
  x02 -= x09 * L2; // x02:57/--
  x03 -= x09 * L3; // x03:57/--
  x04 -= x09 * L4; // x04:57/42
  x01 += (x00 >> 28);
  x00 &= M28L;
  x02 += (x01 >> 28);
  x01 &= M28L;
  x03 += (x02 >> 28);
  x02 &= M28L;
  x04 += (x03 >> 28);
  x03 &= M28L;
  x05 += (x04 >> 28);
  x04 &= M28L;
  x06 += (x05 >> 28);
  x05 &= M28L;
  x07 += (x06 >> 28);
  x06 &= M28L;
  x08 += (x07 >> 28);
  x07 &= M28L;
  x09 = x08 >> 28;
  x08 &= M28L;
  x09 -= t;
  x00 += x09 & L0;
  x01 += x09 & L1;
  x02 += x09 & L2;
  x03 += x09 & L3;
  x04 += x09 & L4;
  x01 += (x00 >> 28);
  x00 &= M28L;
  x02 += (x01 >> 28);
  x01 &= M28L;
  x03 += (x02 >> 28);
  x02 &= M28L;
  x04 += (x03 >> 28);
  x03 &= M28L;
  x05 += (x04 >> 28);
  x04 &= M28L;
  x06 += (x05 >> 28);
  x05 &= M28L;
  x07 += (x06 >> 28);
  x06 &= M28L;
  x08 += (x07 >> 28);
  x07 &= M28L;
  final r = Int8List(SCALAR_BYTES);
  encode56(x00 | (x01 << 28), r, 0);
  encode56(x02 | (x03 << 28), r, 7);
  encode56(x04 | (x05 << 28), r, 14);
  encode56(x06 | (x07 << 28), r, 21);
  encode32(x08.toInt32().toInt(), r, 28);
  return r;
}

void scalarMultBase(Int8List k, PointAccum r) {
  pointSetNeutralAccum(r);
  final n = Int32List(SCALAR_INTS);
  decodeScalar(k, 0, n);
  // Recode the scalar into signed-digit form, then group comb bits in each block
  cadd(SCALAR_INTS, ~Int32(n[0]) & 1, n, L, n);
  shiftDownBit(SCALAR_INTS, n, 1);
  for (int i = 0; i < SCALAR_INTS; i++) n[i] = shuffle2(Int32(n[i])).toInt();
  final p = PointPrecomp.create();
  var cOff = (PRECOMP_SPACING - 1) * PRECOMP_TEETH;
  while (true) {
    for (int b = 0; b < PRECOMP_BLOCKS; b++) {
      final w = Int32(n[b]).shiftRightUnsigned(cOff);
      final sign = (w.shiftRightUnsigned(PRECOMP_TEETH - 1)) & 1;
      final abs = (w ^ -sign) & PRECOMP_MASK;
      pointLookup(b, abs, p);
      x25519Field.cswap(sign, p.ypx_h, p.ymx_h);
      x25519Field.cnegate(sign, p.xyd);
      pointAddPrecomp(p, r);
    }
    cOff -= PRECOMP_TEETH;
    if (cOff < 0) break;
    pointDouble(r);
  }
}

Int8List createScalarMultBaseEncoded(Int8List s) {
  final r = Int8List(SCALAR_BYTES);
  scalarMultBaseEncoded(s, r, 0);
  return r;
}

void scalarMultBaseEncoded(Int8List k, Int8List r, int rOff) {
  final p = PointAccum.create();
  scalarMultBase(k, p);
  encodePoint(p, r, rOff);
}

void scalarMultStraussVar(
    Int32List nb, Int32List np, PointExt p, PointAccum r) {
  final width = 5;
  final ws_b = getWNAF(nb, WNAF_WIDTH_BASE);
  final ws_p = getWNAF(np, width);
  final tp = pointPrecompVar(p, 1 << (width - 2));
  pointSetNeutralAccum(r);
  var bit = 255;
  while (bit > 0 && (ws_b[bit] | ws_p[bit]) == 0) bit -= 1;
  while (true) {
    final wb = ws_b[bit];
    if (wb != 0) {
      final sign = wb >> 31;
      final index = Int32(wb ^ sign).shiftRightUnsigned(1).toInt32().toInt();
      pointAddVar1(sign != 0, _precompBaseTable[index], r);
    }
    final wp = ws_p[bit];
    if (wp != 0) {
      final sign = wp >> 31;
      final index = Int32(wp ^ sign).shiftRightUnsigned(1).toInt32().toInt();
      pointAddVar1(sign != 0, tp[index], r);
    }
    if (--bit < 0) break;
    pointDouble(r);
  }
}

const POINT_BYTES = 32;
const SCALAR_INTS = 8;
const SCALAR_BYTES = SCALAR_INTS * 4;
const PREHASH_SIZE = 64;
const PUBLIC_KEY_SIZE = POINT_BYTES;
const SECRET_KEY_SIZE = 32;
const SIGNATURE_SIZE = POINT_BYTES + SCALAR_BYTES;
const DOM2_PREFIX = "SigEd25519 no Ed25519 collisions";
final M28L = Int64(0x0fffffff);
final M32L = Int64(0xffffffff);
final P = Int32List.fromList([
  0xffffffed,
  0xffffffff,
  0xffffffff,
  0xffffffff,
  0xffffffff,
  0xffffffff,
  0xffffffff,
  0x7fffffff
]);
final L = Int32List.fromList([
  0x5cf5d3ed,
  0x5812631a,
  0xa2f79cd6,
  0x14def9de,
  0x00000000,
  0x00000000,
  0x00000000,
  0x10000000
]);
final L0 = Int32(0xfcf5d3ed);
final L1 = Int32(0x012631a6);
final L2 = Int32(0x079cd658);
final L3 = Int32(0xff9dea2f);
final L4 = Int32(0x000014df);

final B_x = Int32List.fromList([
  0x0325d51a,
  0x018b5823,
  0x007b2c95,
  0x0304a92d,
  0x00d2598e,
  0x01d6dc5c,
  0x01388c7f,
  0x013fec0a,
  0x029e6b72,
  0x0042d26d
]);

final B_y = Int32List.fromList([
  0x02666658,
  0x01999999,
  0x00666666,
  0x03333333,
  0x00cccccc,
  0x02666666,
  0x01999999,
  0x00666666,
  0x03333333,
  0x00cccccc
]);

final C_d = Int32List.fromList([
  0x035978a3,
  0x02d37284,
  0x018ab75e,
  0x026a0a0e,
  0x0000e014,
  0x0379e898,
  0x01d01e5d,
  0x01e738cc,
  0x03715b7f,
  0x00a406d9
]);

final C_d2 = Int32List.fromList([
  0x02b2f159,
  0x01a6e509,
  0x01156ebd,
  0x00d4141d,
  0x0001c029,
  0x02f3d130,
  0x03a03cbb,
  0x01ce7198,
  0x02e2b6ff,
  0x00480db3
]);

final C_d4 = Int32List.fromList([
  0x0165e2b2,
  0x034dca13,
  0x002add7a,
  0x01a8283b,
  0x00038052,
  0x01e7a260,
  0x03407977,
  0x019ce331,
  0x01c56dff,
  0x00901b67
]);
final WNAF_WIDTH_BASE = 7;
final PRECOMP_BLOCKS = 8;
final PRECOMP_TEETH = 4;
final PRECOMP_SPACING = 8;
final PRECOMP_POINTS = 1 << PRECOMP_TEETH - 1;
final PRECOMP_MASK = PRECOMP_POINTS - 1;
final M = Int64(0xffffffff);

class PointAccum {
  final Int32List x;
  final Int32List y;
  final Int32List z;
  final Int32List u;
  final Int32List v;

  PointAccum(this.x, this.y, this.z, this.u, this.v);

  PointAccum.create()
      : x = x25519Field.create,
        y = x25519Field.create,
        z = x25519Field.create,
        u = x25519Field.create,
        v = x25519Field.create;
}

class PointExt {
  final Int32List x;
  final Int32List y;
  final Int32List z;
  final Int32List t;

  PointExt(this.x, this.y, this.z, this.t);

  PointExt.create()
      : x = x25519Field.create,
        y = x25519Field.create,
        z = x25519Field.create,
        t = x25519Field.create;
}

class PointPrecomp {
  final Int32List ypx_h;
  final Int32List ymx_h;
  final Int32List xyd;

  PointPrecomp(this.ypx_h, this.ymx_h, this.xyd);

  PointPrecomp.create()
      : ypx_h = x25519Field.create,
        ymx_h = x25519Field.create,
        xyd = x25519Field.create;
}

extension IntOps on int {
  int get toByte => (ByteData(1)..setInt8(0, this)).buffer.asInt8List()[0];
}
