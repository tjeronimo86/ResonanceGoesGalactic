package com.ryanheise.just_audio;

import androidx.media3.exoplayer.ExoPlayer;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Galactic view: live analysis of what is heard right now (spectrum, peak and RMS levels, EBU R128 loudness,
 * true peak). The app polls {@code frame} once per screen frame; the work happens here on the main thread.
 *
 * <p>Result layout (float[]): 0 version, 1 bands, 2 playing (0/1), 3 sample rate, 4 peakL, 5 peakR (dBFS),
 * 6 rmsL, 7 rmsR (dBFS, sine = peak), 8 momentary, 9 short term, 10 integrated (LUFS, -inf as -200), 11 LRA,
 * 12 max sample peak (dBFS), 13 true peak (dBTP), then the bands (dBFS) mono, left, right.
 */
final class Galactic implements MethodChannel.MethodCallHandler {
    static final int HEADER = 14;
    private static final int N = 8192;
    private static final int BANDS_PER_OCT = 8;
    private static final double F_LOW = 25.0;

    private static final class Entry {
        final GalacticTap tap;
        final ExoPlayer player;

        Entry(GalacticTap tap, ExoPlayer player) {
            this.tap = tap;
            this.player = player;
        }
    }

    private static final Map<String, Entry> entries = new HashMap<>();

    static synchronized void register(String playerId, GalacticTap tap, ExoPlayer player) {
        entries.put(playerId, new Entry(tap, player));
    }

    static synchronized void unregister(String playerId) {
        entries.remove(playerId);
    }

    private static synchronized Entry get(String playerId) {
        return entries.get(playerId);
    }

    // ---------------------------------------------------------------- analysis state

    private final Fft fft = new Fft(N);
    private final double[] re = new double[N], im = new double[N], reR = new double[N], imR = new double[N];
    private int rate = 0;
    private double[] bandFreqs = new double[0];

    private Entry lastEntry;
    private long lastFrame = -1;
    private String lastTrack;

    private double msL, msR;
    private double maxPeak;
    private LoudnessMeter loud = new LoudnessMeter(44100);
    private final TruePeak truePeak = new TruePeak();
    private int loudTick;
    private float integrated = Float.NEGATIVE_INFINITY;
    private float lra;

    private void setup(int sr) {
        rate = sr;
        double top = Math.min(20000.0, sr * 0.47);
        int n = (int) Math.floor(BANDS_PER_OCT * Math.log(top / F_LOW) / Math.log(2)) + 1;
        bandFreqs = new double[n];
        for (int i = 0; i < n; i++) bandFreqs[i] = F_LOW * Math.pow(2, (double) i / BANDS_PER_OCT);
        loud = new LoudnessMeter(sr);
        resetTrack();
    }

    private void resetTrack() {
        loud.reset();
        truePeak.reset();
        maxPeak = 0;
        integrated = Float.NEGATIVE_INFINITY;
        lra = 0;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        if (!"frame".equals(call.method)) {
            result.notImplemented();
            return;
        }
        List<?> ids = call.argument("ids");
        Boolean stereo = call.argument("stereo");
        String track = call.argument("track");
        try {
            result.success(frame(ids == null ? new ArrayList<>() : ids, stereo != null && stereo, track));
        } catch (Exception e) {
            result.error("galactic", e.toString(), null);
        }
    }

    private float[] frame(List<?> ids, boolean stereo, String track) {
        // The player that is heard most (AutoMix and crossfades run two players).
        Entry best = null;
        float bestVolume = -1;
        for (Object id : ids) {
            Entry e = id instanceof String ? get((String) id) : null;
            if (e == null) continue;
            if (!e.player.isPlaying()) continue;
            float v = e.player.getVolume();
            if (v > bestVolume) {
                bestVolume = v;
                best = e;
            }
        }
        int bands = bandFreqs.length;
        if (best == null) return empty(bands);

        GalacticTap tap = best.tap;
        int sr = tap.sampleRate;
        if (sr != rate || bands == 0) {
            setup(sr);
            bands = bandFreqs.length;
        }
        if (track != null && !track.equals(lastTrack)) {
            lastTrack = track;
            resetTrack();
        }
        long written = tap.written;
        if (written < N) return empty(bands);

        // Newest frame whose song time is at or before what is heard now.
        long pos = best.player.getCurrentPosition() * 1000L;
        long lo = Math.max(0, written - GalacticTap.CAP + N);
        long f = written - 1;
        while (f - 1024 > lo && tap.timeUs[(int) (f & GalacticTap.MASK)] > pos) f -= 1024;
        while (f + 1 < written && tap.timeUs[(int) ((f + 1) & GalacticTap.MASK)] <= pos) f++;
        while (f > lo && tap.timeUs[(int) (f & GalacticTap.MASK)] > pos) f--;
        if (f < lo) f = lo;

        long from = lastFrame;
        if (best != lastEntry || from < lo || from > f || f - from > sr) from = Math.max(lo, f - sr / 20);
        lastEntry = best;
        lastFrame = f;

        float volume = Math.max(0f, best.player.getVolume());
        double aRms = Math.exp(-1.0 / (0.3 * sr));
        double pk0 = 0, pk1 = 0;
        for (long k = from; k < f; k++) {
            int i = (int) (k & GalacticTap.MASK);
            float l = tap.left[i] * volume, r = tap.right[i] * volume;
            double al = Math.abs(l), ar = Math.abs(r);
            if (al > pk0) pk0 = al;
            if (ar > pk1) pk1 = ar;
            msL = aRms * msL + (1 - aRms) * l * l;
            msR = aRms * msR + (1 - aRms) * r * r;
            loud.add(l, r);
            truePeak.add(l, r);
        }
        if (pk0 > maxPeak) maxPeak = pk0;
        if (pk1 > maxPeak) maxPeak = pk1;
        if (++loudTick % 15 == 0) {
            integrated = loud.integrated();
            lra = loud.range();
        }

        float[] out = new float[HEADER + bands * 3];
        out[0] = 1;
        out[1] = bands;
        out[2] = 1;
        out[3] = sr;
        out[4] = db(pk0);
        out[5] = db(pk1);
        out[6] = db(Math.sqrt(msL * 2));
        out[7] = db(Math.sqrt(msR * 2));
        out[8] = finite(loud.momentary());
        out[9] = finite(loud.shortTerm());
        out[10] = finite(integrated);
        out[11] = lra;
        out[12] = db(maxPeak);
        out[13] = db(Math.max(truePeak.peak(), maxPeak));

        // Spectrum of the window ending at the frame heard now.
        long start = f - N;
        for (int k = 0; k < N; k++) {
            int i = (int) ((start + k) & GalacticTap.MASK);
            double w = fft.window[k] * volume;
            double l = tap.left[i] * w, r = tap.right[i] * w;
            if (stereo) {
                re[k] = l;
                reR[k] = r;
                imR[k] = 0;
            } else {
                re[k] = (l + r) * 0.5;
            }
            im[k] = 0;
        }
        fft.transform(re, im);
        double binHz = (double) sr / N;
        if (stereo) {
            fft.transform(reR, imR);
            fill(out, HEADER + bands, re, im, binHz);
            fill(out, HEADER + 2 * bands, reR, imR, binHz);
            for (int b = 0; b < bands; b++) out[HEADER + b] = Math.max(out[HEADER + bands + b], out[HEADER + 2 * bands + b]);
        } else {
            fill(out, HEADER, re, im, binHz);
            System.arraycopy(out, HEADER, out, HEADER + bands, bands);
            System.arraycopy(out, HEADER, out, HEADER + 2 * bands, bands);
        }
        return out;
    }

    private float[] empty(int bands) {
        float[] out = new float[HEADER + bands * 3];
        out[0] = 1;
        out[1] = bands;
        out[2] = 0;
        out[3] = rate;
        for (int i = 4; i < out.length; i++) out[i] = -200f;
        out[11] = lra;
        out[10] = finite(integrated);
        out[12] = db(maxPeak);
        out[13] = db(Math.max(truePeak.peak(), maxPeak));
        return out;
    }

    private void fill(float[] out, int offset, double[] r, double[] i, double binHz) {
        double half = Math.pow(2, 0.5 / BANDS_PER_OCT);
        double norm = 4.0 / N;
        for (int b = 0; b < bandFreqs.length; b++) {
            double fc = bandFreqs[b];
            double lo = fc / half / binHz, hi = fc * half / binHz;
            int a = (int) Math.ceil(lo), z = (int) Math.floor(hi);
            double m = 0;
            if (z >= a) {
                for (int k = a; k <= Math.min(z, N / 2 - 1); k++) {
                    double v = Math.hypot(r[k], i[k]);
                    if (v > m) m = v;
                }
            } else {
                double x = fc / binHz;
                int k0 = Math.max(0, Math.min(N / 2 - 2, (int) Math.floor(x)));
                double t = x - k0;
                m = Math.hypot(r[k0], i[k0]) * (1 - t) + Math.hypot(r[k0 + 1], i[k0 + 1]) * t;
            }
            out[offset + b] = db(m * norm);
        }
    }

    private static float db(double a) {
        return a <= 1e-9 ? -200f : (float) (20 * Math.log10(a));
    }

    private static float finite(float v) {
        return Float.isInfinite(v) || Float.isNaN(v) ? -200f : v;
    }

    // ---------------------------------------------------------------- DSP

    private static final class Biquad {
        final double b0, b1, b2, a1, a2;
        double z1, z2;

        Biquad(double b0, double b1, double b2, double a1, double a2) {
            this.b0 = b0;
            this.b1 = b1;
            this.b2 = b2;
            this.a1 = a1;
            this.a2 = a2;
        }

        double process(double x) {
            double y = b0 * x + z1;
            z1 = b1 * x - a1 * y + z2;
            z2 = b2 * x - a2 * y;
            return y;
        }

        void reset() {
            z1 = 0;
            z2 = 0;
        }
    }

    /** K-weighting after ITU-R BS.1770 for any sample rate (formulas as in libebur128). */
    private static Biquad[] kWeighting(double rate) {
        double f0 = 1681.974450955533, g = 3.999843853973347, q = 0.7071752369554196;
        double k = Math.tan(Math.PI * f0 / rate);
        double vh = Math.pow(10, g / 20), vb = Math.pow(vh, 0.4996667741545416);
        double a0 = 1 + k / q + k * k;
        Biquad shelf = new Biquad((vh + vb * k / q + k * k) / a0, 2 * (k * k - vh) / a0,
            (vh - vb * k / q + k * k) / a0, 2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0);
        f0 = 38.13547087602444;
        q = 0.5003270373238773;
        k = Math.tan(Math.PI * f0 / rate);
        a0 = 1 + k / q + k * k;
        Biquad hp = new Biquad(1, -2, 1, 2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0);
        return new Biquad[] {shelf, hp};
    }

    /** EBU R128: momentary (400 ms), short term (3 s), gated integrated loudness and loudness range. */
    private static final class LoudnessMeter {
        private final Biquad[] kl, kr;
        private final int blockLen;
        private double acc;
        private int count;
        private double[] sub = new double[4096];
        private int subCount;
        private double[] gated = new double[4096];
        private int gatedCount;
        private double[] shortT = new double[4096];
        private int shortCount;

        LoudnessMeter(int rate) {
            kl = kWeighting(rate);
            kr = kWeighting(rate);
            blockLen = Math.max(1, rate / 10);
        }

        void reset() {
            for (Biquad b : kl) b.reset();
            for (Biquad b : kr) b.reset();
            acc = 0;
            count = 0;
            subCount = 0;
            gatedCount = 0;
            shortCount = 0;
        }

        void add(float l, float r) {
            double a = kl[1].process(kl[0].process(l));
            double b = kr[1].process(kr[0].process(r));
            acc += a * a + b * b;
            if (++count >= blockLen) {
                push(acc / count);
                acc = 0;
                count = 0;
            }
        }

        private void push(double e) {
            if (subCount == sub.length) sub = java.util.Arrays.copyOf(sub, sub.length * 2);
            sub[subCount++] = e;
            if (subCount >= 4) {
                if (gatedCount == gated.length) gated = java.util.Arrays.copyOf(gated, gated.length * 2);
                gated[gatedCount++] = meanLast(4);
            }
            if (subCount >= 30) {
                if (shortCount == shortT.length) shortT = java.util.Arrays.copyOf(shortT, shortT.length * 2);
                shortT[shortCount++] = meanLast(30);
            }
        }

        private double meanLast(int k) {
            double s = 0;
            for (int i = subCount - k; i < subCount; i++) s += sub[i];
            return s / k;
        }

        private static float lufs(double e) {
            return e <= 1e-12 ? Float.NEGATIVE_INFINITY : (float) (-0.691 + 10 * Math.log10(e));
        }

        float momentary() {
            return subCount == 0 ? Float.NEGATIVE_INFINITY : lufs(meanLast(Math.min(4, subCount)));
        }

        float shortTerm() {
            return subCount == 0 ? Float.NEGATIVE_INFINITY : lufs(meanLast(Math.min(30, subCount)));
        }

        float integrated() {
            double abs = Math.pow(10, (-70 + 0.691) / 10);
            double s = 0;
            int n = 0;
            for (int i = 0; i < gatedCount; i++) if (gated[i] > abs) { s += gated[i]; n++; }
            if (n == 0) return Float.NEGATIVE_INFINITY;
            double rel = s / n * 0.1;
            s = 0;
            n = 0;
            for (int i = 0; i < gatedCount; i++) if (gated[i] > abs && gated[i] > rel) { s += gated[i]; n++; }
            return n == 0 ? Float.NEGATIVE_INFINITY : lufs(s / n);
        }

        float range() {
            double abs = Math.pow(10, (-70 + 0.691) / 10);
            double s = 0;
            int n = 0;
            for (int i = 0; i < shortCount; i++) if (shortT[i] > abs) { s += shortT[i]; n++; }
            if (n < 2) return 0;
            double rel = s / n * 0.01;
            double[] vals = new double[n];
            int m = 0;
            for (int i = 0; i < shortCount; i++) {
                if (shortT[i] > abs && shortT[i] > rel) vals[m++] = -0.691 + 10 * Math.log10(shortT[i]);
            }
            if (m < 2) return 0;
            java.util.Arrays.sort(vals, 0, m);
            return (float) (vals[(int) ((m - 1) * 0.95)] - vals[(int) ((m - 1) * 0.10)]);
        }
    }

    /** True peak with 4× oversampling (polyphase FIR, 48 taps). */
    private static final class TruePeak {
        private static final int TAPS = 12;
        private final double[][] phases = new double[4][TAPS];
        private final double[][] hist = new double[2][TAPS];
        private int pos;
        private double peak;

        TruePeak() {
            for (int p = 0; p < 4; p++) {
                double sum = 0;
                for (int j = 0; j < TAPS; j++) {
                    int k = p + 4 * j;
                    double x = (k - 23.5) / 4.0;
                    double v = Math.sin(Math.PI * x) / (Math.PI * x) * (0.5 - 0.5 * Math.cos(2 * Math.PI * (k + 0.5) / 48.0));
                    phases[p][j] = v;
                    sum += v;
                }
                for (int j = 0; j < TAPS; j++) phases[p][j] /= sum;
            }
        }

        void reset() {
            for (double[] h : hist) java.util.Arrays.fill(h, 0);
            pos = 0;
            peak = 0;
        }

        double peak() {
            return peak;
        }

        void add(float l, float r) {
            pos = (pos + 1) % TAPS;
            hist[0][pos] = l;
            hist[1][pos] = r;
            for (int c = 0; c < 2; c++) {
                double[] h = hist[c];
                double x = Math.abs(h[pos]);
                if (x > peak) peak = x;
                double prev = Math.abs(h[(pos - 1 + TAPS) % TAPS]);
                if (Math.max(x, prev) * 1.6 < peak) continue;
                for (int p = 0; p < 4; p++) {
                    double[] ph = phases[p];
                    double y = 0;
                    int idx = pos;
                    for (int j = 0; j < TAPS; j++) {
                        y += ph[j] * h[idx];
                        idx = idx == 0 ? TAPS - 1 : idx - 1;
                    }
                    double a = Math.abs(y);
                    if (a > peak) peak = a;
                }
            }
        }
    }

    /** Radix-2 FFT, in place, with a Hann window. */
    private static final class Fft {
        final int n;
        final double[] window;
        private final double[] cos, sin;
        private final int[] rev;

        Fft(int n) {
            this.n = n;
            int levels = Integer.numberOfTrailingZeros(n);
            cos = new double[n / 2];
            sin = new double[n / 2];
            for (int i = 0; i < n / 2; i++) {
                cos[i] = Math.cos(2 * Math.PI * i / n);
                sin[i] = Math.sin(2 * Math.PI * i / n);
            }
            rev = new int[n];
            for (int i = 0; i < n; i++) rev[i] = Integer.reverse(i) >>> (32 - levels);
            window = new double[n];
            for (int i = 0; i < n; i++) window[i] = 0.5 - 0.5 * Math.cos(2 * Math.PI * i / (n - 1));
        }

        void transform(double[] re, double[] im) {
            for (int i = 0; i < n; i++) {
                int j = rev[i];
                if (j > i) {
                    double t = re[i];
                    re[i] = re[j];
                    re[j] = t;
                    t = im[i];
                    im[i] = im[j];
                    im[j] = t;
                }
            }
            for (int size = 2; size <= n; size *= 2) {
                int half = size / 2, step = n / size;
                for (int i = 0; i < n; i += size) {
                    int k = 0;
                    for (int j = i; j < i + half; j++) {
                        int l = j + half;
                        double tr = re[l] * cos[k] + im[l] * sin[k];
                        double ti = -re[l] * sin[k] + im[l] * cos[k];
                        re[l] = re[j] - tr;
                        im[l] = im[j] - ti;
                        re[j] += tr;
                        im[j] += ti;
                        k += step;
                    }
                }
            }
        }
    }
}
