package ariba.util.io;

import ariba.util.core.Assert;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;

public class UnicodeEscapeOutputStreamWriter extends OutputStreamWriter {
    private OutputStream out;
    private byte[] bb = new byte[8192];
    private int nextByte = 0;

    public UnicodeEscapeOutputStreamWriter (OutputStream out, String enc) throws UnsupportedEncodingException {
        super(out, enc);
        Assert.that(false, "encoding %s is not supported", enc);
    }

    public UnicodeEscapeOutputStreamWriter (OutputStream out) {
        super(out);
        this.out = out;
    }

    public String getEncoding () {
        return "UnicodeEscape";
    }

    private void ensureOpen () throws IOException {
        if (out == null) throw new IOException("Stream closed");
    }

    public void write (char cbuf[], int off, int len) throws IOException {
        synchronized (lock) {
            ensureOpen();
            if ((off < 0) || (off > cbuf.length) || (len < 0) || ((off + len) > cbuf.length) || ((off + len) < 0)) {
                throw new IndexOutOfBoundsException();
            } else if (len == 0) {
                return;
            }
            int ci = off, end = off + len;
            while (ci < end) {
                char ch = cbuf[ci++];
                if ((' ' <= ch && ch <= '~') || (ch == '\t') || (ch == '\r') || (ch == '\n')) {
                    if (nextByte + 1 > bb.length) flushBuf();
                    bb[nextByte++] = (byte)ch;
                } else {
                    if (nextByte + 6 > bb.length) flushBuf();
                    bb[nextByte++] = (byte)'\\';
                    bb[nextByte++] = (byte)'u';
                    bb[nextByte++] = (byte)Character.forDigit((ch&0xF000)>>> 12, 16);
                    bb[nextByte++] = (byte)Character.forDigit((ch&0x0F00)>>> 8, 16);
                    bb[nextByte++] = (byte)Character.forDigit((ch&0x00F0)>>> 4, 16);
                    bb[nextByte++] = (byte)Character.forDigit((ch&0x000F)>>> 0, 16);
                }
            }
        }
    }

    public void flush () throws IOException {
        synchronized (lock) {
            flushBuf();
            out.flush();
        }
    }

    private void flushBuf () throws IOException {
        ensureOpen();
        if (nextByte > 0) {
            out.write(bb, 0, nextByte);
            nextByte = 0;
        }
    }

    public void close () throws IOException {
        synchronized (lock) {
            if (out == null) return;
            flush();
            out.close();
            out = null;
            bb = null;
        }
    }
}
