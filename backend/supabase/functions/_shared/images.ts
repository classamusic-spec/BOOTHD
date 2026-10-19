// Structural checks of uploaded images (AC-0908): the bytes must be a
// complete JPEG or PNG of the declared size. The booth decodes every file
// before upload; the server checks the type from the bytes themselves
// (never the declared content type), the pixel size from the image header
// and that the file is complete, so a truncated or substituted upload is
// refused before anything is sent.

export type ImageFormat = 'jpeg' | 'png';

export type ImageFacts =
  | { ok: true; format: ImageFormat; width: number; height: number }
  | { ok: false; problem: 'IMAGE_TYPE' | 'IMAGE_TRUNCATED' | 'IMAGE_HEADER' };

const pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

export function inspectImage(bytes: Uint8Array): ImageFacts {
  if (bytes.length >= 4 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return inspectJpeg(bytes);
  }
  if (bytes.length >= 8 && pngSignature.every((byte, i) => bytes[i] === byte)) {
    return inspectPng(bytes);
  }
  return { ok: false, problem: 'IMAGE_TYPE' };
}

function inspectJpeg(bytes: Uint8Array): ImageFacts {
  // A complete JPEG ends with the end-of-image marker.
  if (bytes[bytes.length - 2] !== 0xff || bytes[bytes.length - 1] !== 0xd9) {
    return { ok: false, problem: 'IMAGE_TRUNCATED' };
  }
  let offset = 2;
  while (offset + 4 <= bytes.length) {
    if (bytes[offset] !== 0xff) return { ok: false, problem: 'IMAGE_HEADER' };
    const marker = bytes[offset + 1];
    // Padding and markers without a length.
    if (marker === 0xff) {
      offset += 1;
      continue;
    }
    if (marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) {
      offset += 2;
      continue;
    }
    if (marker === 0xd9 || marker === 0xda) break;
    const length = (bytes[offset + 2] << 8) | bytes[offset + 3];
    if (length < 2 || offset + 2 + length > bytes.length) {
      return { ok: false, problem: 'IMAGE_TRUNCATED' };
    }
    // Start-of-frame markers (baseline, extended, progressive, lossless).
    const frame = marker >= 0xc0 && marker <= 0xcf && marker !== 0xc4 && marker !== 0xc8 &&
      marker !== 0xcc;
    if (frame) {
      if (length < 7) return { ok: false, problem: 'IMAGE_HEADER' };
      const height = (bytes[offset + 5] << 8) | bytes[offset + 6];
      const width = (bytes[offset + 7] << 8) | bytes[offset + 8];
      if (width === 0 || height === 0) return { ok: false, problem: 'IMAGE_HEADER' };
      return { ok: true, format: 'jpeg', width, height };
    }
    offset += 2 + length;
  }
  return { ok: false, problem: 'IMAGE_HEADER' };
}

function readUint32(bytes: Uint8Array, offset: number): number {
  return ((bytes[offset] << 24) >>> 0) + (bytes[offset + 1] << 16) + (bytes[offset + 2] << 8) +
    bytes[offset + 3];
}

function inspectPng(bytes: Uint8Array): ImageFacts {
  let offset = 8;
  let width = 0;
  let height = 0;
  let first = true;
  while (offset + 12 <= bytes.length) {
    const length = readUint32(bytes, offset);
    const type = String.fromCharCode(...bytes.subarray(offset + 4, offset + 8));
    const end = offset + 12 + length;
    if (end > bytes.length) return { ok: false, problem: 'IMAGE_TRUNCATED' };
    if (first) {
      if (type !== 'IHDR' || length !== 13) return { ok: false, problem: 'IMAGE_HEADER' };
      width = readUint32(bytes, offset + 8);
      height = readUint32(bytes, offset + 12);
      if (width === 0 || height === 0) return { ok: false, problem: 'IMAGE_HEADER' };
      first = false;
    }
    if (type === 'IEND') {
      return end === bytes.length
        ? { ok: true, format: 'png', width, height }
        : { ok: false, problem: 'IMAGE_HEADER' };
    }
    offset = end;
  }
  return { ok: false, problem: 'IMAGE_TRUNCATED' };
}
