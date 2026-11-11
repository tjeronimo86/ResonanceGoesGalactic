package com.ryanheise.just_audio;

import androidx.media3.common.C;
import androidx.media3.common.audio.AudioProcessor;
import androidx.media3.common.audio.BaseAudioProcessor;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * Galactic view: copies the audio of one player (after its mix effects, before the speed change) into a ring
 * together with the song time of every frame, so the analyzer can read exactly what is heard right now.
 * The audio itself passes through unchanged.
 */
final class GalacticTap extends BaseAudioProcessor {
    static final int CAP = 1 << 18; // frames, ~5 s at 48 kHz
    static final int MASK = CAP - 1;

    final float[] left = new float[CAP];
    final float[] right = new float[CAP];
    /** Song time of each frame (µs), Long.MIN_VALUE when unknown. */
    final long[] timeUs = new long[CAP];

    /** Frames written so far (only grows). */
    volatile long written;
    volatile int sampleRate = 44100;

    private final MixFxProcessor mixFx;

    GalacticTap(MixFxProcessor mixFx) {
        this.mixFx = mixFx;
    }

    @Override
    protected AudioFormat onConfigure(AudioFormat inputAudioFormat) {
        if (inputAudioFormat.encoding != C.ENCODING_PCM_16BIT && inputAudioFormat.encoding != C.ENCODING_PCM_FLOAT) {
            return AudioFormat.NOT_SET;
        }
        if (inputAudioFormat.channelCount < 1) return AudioFormat.NOT_SET;
        return inputAudioFormat;
    }

    @Override
    protected void onFlush() {
        if (inputAudioFormat.sampleRate > 0) sampleRate = inputAudioFormat.sampleRate;
    }

    @Override
    public void queueInput(ByteBuffer input) {
        int bytesPerFrame = inputAudioFormat.bytesPerFrame;
        int channels = inputAudioFormat.channelCount;
        boolean isFloat = inputAudioFormat.encoding == C.ENCODING_PCM_FLOAT;
        int start = input.position();
        int frames = input.remaining() / bytesPerFrame;
        if (frames == 0) return;
        input.order(ByteOrder.nativeOrder());
        int rate = inputAudioFormat.sampleRate > 0 ? inputAudioFormat.sampleRate : sampleRate;

        // The mix processor has just advanced past this buffer: its position is the song time after it.
        Long end = mixFx.position();
        double usPerFrame = 1e6 / rate;
        double t0 = end == null ? Double.NaN : end - frames * usPerFrame;

        long w = written;
        int sampleBytes = isFloat ? 4 : 2;
        for (int f = 0; f < frames; f++) {
            int at = start + f * bytesPerFrame;
            float l = isFloat ? input.getFloat(at) : input.getShort(at) / 32768f;
            float r = channels > 1
                ? (isFloat ? input.getFloat(at + sampleBytes) : input.getShort(at + sampleBytes) / 32768f)
                : l;
            int i = (int) (w & MASK);
            left[i] = l;
            right[i] = r;
            timeUs[i] = Double.isNaN(t0) ? Long.MIN_VALUE : (long) (t0 + f * usPerFrame);
            w++;
        }
        written = w;
        sampleRate = rate;

        ByteBuffer output = replaceOutputBuffer(frames * bytesPerFrame);
        output.put(input);
        output.flip();
    }
}
