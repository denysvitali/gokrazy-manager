# Firmware Upload Protocol

This document describes how gokrazy-manager uploads firmware images to gokrazy devices.

## Overview

The upload process transfers a squashfs image to the device's **inactive root partition**. The device writes the image while simultaneously computing a SHA-256 hash for verification.

## HTTP Protocol

### Endpoint

```
PUT /update/root
```

### Request

- **Content-Type**: `application/octet-stream`
- **Authorization**: Basic auth (username:password)
- **Body**: Raw binary image data (squashfs, possibly gzip-compressed)

### Response

- **Success**: HTTP 200 with SHA-256 hash of uploaded data as plaintext
- **Error**: HTTP 4xx/5xx with error message

### Example

```bash
curl -X PUT https://device/update/root \
  -H "Content-Type: application/octet-stream" \
  -u "gokrazy:password" \
  --data-binary @image.squashfs
# Response: <sha256-hash>
```

## Server-Side Processing

On the gokrazy device (`update.go`):

1. The `/update/root` handler uses a mutex to ensure only one update runs at a time
2. Data is streamed directly from the HTTP request body to the block device
3. A `TeeReader` computes SHA-256 while data is written
4. After all data is written, the computed hash is returned

```go
// Simplified from update.go
func nonConcurrentUpdateHandler(dest string) func(...) {
    return func(w http.ResponseWriter, r *http.Request) {
        hash := sha256.New()
        streamRequestTo(dest, 0, io.TeeReader(r.Body, hash))
        fmt.Fprintf(w, "%x", hash.Sum(nil))
    }
}
```

## Client-Side Processing

In gokrazy-manager (`api.dart`):

1. File is read as a stream (via `file_picker`)
2. Optional gzip decompression is applied
3. Stream is simultaneously:
   - Sent to the device via HTTP PUT
   - Hashed locally for verification
4. Device's hash is compared against local hash

### Progress Tracking Limitation

The progress callback fires when data chunks are buffered in Dart's HTTP client, **not** when data is actually transmitted over the network. For large images (500MB+), the progress bar may reach 100% while the device is still writing to storage.

The UI displays "Waiting for device to write image..." when local buffering is complete to indicate this state.

## File Format Support

| Extension | Decompress | Notes |
|-----------|------------|-------|
| `.squashfs` | No | Raw squashfs image |
| `.img` | No | Raw disk image |
| `.gz` | Yes | Gzip-compressed squashfs |
| `.bin` | No | Binary firmware |

## Security

- All communication should use HTTPS (self-signed certificates are pinned)
- XSRF protection is handled separately for state-changing operations
- The SHA-256 hash ensures data integrity

## Related

- [gokrazy update.go](../../gokrazy/update.go) - Server-side implementation
- [API client](../../lib/api.dart) - Client-side implementation
- [Upload UI](../../lib/home.dart) - Flutter upload interface
