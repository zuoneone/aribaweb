package ariba.util.io;

import ariba.util.core.Assert;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;

public class UnicodeEscapeInputStreamReader extends InputStreamReader {
    private InputStream in;
    private byte[] bb = new byte[8192];
    private int nBytes = 0;
    private int nextByte = 0;

    private static final int StateNormal    = 0;
    private static final int StateBackslash = 1;
    private static final int StateU         = 2;
    private static final int StateFirst     = 3;
    private static final int StateSecond    = 4;
    private static final int StateThird     = 5;

    private int state = StateNormal;
    private char escapedChar;

    public UnicodeEscapeInputStreamReader (InputStream in) {
        super(in);
        this.in = in;
    }

    public UnicodeEscapeInputStreamReader (InputStream in, String enc) throws UnsupportedEncodingException {
        super(in, enc);
        Assert.that(false, "encoding %s is not supported", enc);
    }

    public String getEncoding () {
        return "UnicodeEscape";
    }

    private void ensureOpen () throws IOException {
        if (in == null) throw new IOException("Stream closed");
    }

    private boolean inReady () {
        try { return in.available() > 0; } catch (IOException x) { return false; }
    }

    public int read (char cbuf[], int off, int len) throws IOException {
        synchronized (lock) {
            ensureOpen();
            if ((off < 0) || (off > cbuf.length) || (len < 0) ||
                ((off + len) > cbuf.length) || ((off + len) < 0)) {
                throw new IndexOutOfBoundsException();
            } else if (len == 0) {
                return 0;
            }

            int charCount = 0;
            while (charCount < len) {
                if (nextByte >= nBytes) {
                    if (charCount > 0 && !inReady()) break;
                    nBytes = in.read(bb);
                    if (nBytes == -1) {
                        nBytes = 0;
                        if (charCount == 0 && state == StateNormal) return -1;
                        break;
                    }
                    nextByte = 0;
                }

                while (nextByte < nBytes && charCount < len) {
                    byte by = bb[nextByte++];
                    switch (state) {
                        case StateNormal:
                            if (by == '\\') { state = StateBackslash; }
                            else { cbuf[off + charCount++] = (char)by; }
                            break;
                        case StateBackslash:
                            if (by == 'u') { state = StateU; }
                            else {
                                cbuf[off + charCount++] = '\\';
                                nextByte--; // Retry this byte in normal state
                                state = StateNormal;
                            }
                            break;
                        case StateU:
                            int dU = Character.digit((char)by, 16);
                            if (dU == -1) throw new IOException("Malformed \\u escape");
                            escapedChar = (char)(dU << 12);
                            state = StateFirst;
                            break;
                        case StateFirst:
                            int d1 = Character.digit((char)by, 16);
                            if (d1 == -1) throw new IOException("Malformed \\u escape");
                            escapedChar |= d1 << 8;
                            state = StateSecond;
                            break;
                        case StateSecond:
                            int d2 = Character.digit((char)by, 16);
                            if (d2 == -1) throw new IOException("Malformed \\u escape");
                            escapedChar |= d2 << 4;
                            state = StateThird;
                            break;
                        case StateThird:
                            int d3 = Character.digit((char)by, 16);
                            if (d3 == -1) throw new IOException("Malformed \\u escape");
                            escapedChar |= d3;
                            cbuf[off + charCount++] = escapedChar;
                            state = StateNormal;
                            break;
                    }
                }
            }
            return charCount > 0 ? charCount : -1;
        }
    }

    public boolean ready () throws IOException {
        synchronized (lock) {
            ensureOpen();
            return (nextByte < nBytes) || inReady();
        }
    }

    public void close () throws IOException {
        synchronized (lock) {
            super.close();
            in = null;
            bb = null;
        }
    }
}
