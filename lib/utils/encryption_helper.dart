import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' hide Key;
import 'package:pointycastle/export.dart' as pc;

class EncryptionHelper {
  // Hardcoded key for QR code (legacy/simple obfuscation)
  static final _qrKey = Key(
    Uint8List.fromList(
      utf8.encode('webdavx_qr_encryption_key_2025'.padRight(32, '0')),
    ),
  );
  static final _qrIv = IV(
    Uint8List.fromList(utf8.encode('webdavx_init_vec'.padRight(16, '0'))),
  );
  static final _qrEncrypter = Encrypter(AES(_qrKey, mode: AESMode.cbc));

  // --- QR Code Logic (Keep existing logic for config sharing) ---

  static String encryptConfig(
    String username,
    String password,
    String encryptionPassword,
  ) {
    final configData = jsonEncode({
      'username': username,
      'password': password,
      'encryptionPassword': encryptionPassword,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final encrypted = _qrEncrypter.encrypt(configData, iv: _qrIv);
    return encrypted.base64;
  }

  static Map<String, dynamic>? decryptConfig(String encryptedData) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      final decrypted = _qrEncrypter.decrypt(encrypted, iv: _qrIv);
      final config = jsonDecode(decrypted) as Map<String, dynamic>;

      if (config.containsKey('username') &&
          config.containsKey('password') &&
          config.containsKey('encryptionPassword') &&
          config.containsKey('timestamp')) {
        return {
          'username': config['username'],
          'password': config['password'],
          'encryptionPassword': config['encryptionPassword'],
          'timestamp': config['timestamp'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('QR Decryption error: $e');
      return null;
    }
  }

  // --- File Encryption Logic (New Robust Implementation) ---

  /// Calculates the expected size of the encrypted file.
  /// Size = Header(32) + Data(Padded to 16-byte blocks)
  static int calculateEncryptedSize(int originalSize) {
    // Header: Salt (16) + IV (16) = 32
    // Body: PKCS7 padding always adds 1 to 16 bytes to ensure multiple of 16.
    // Number of blocks = (originalSize ~/ 16) + 1
    // Body Size = Number of blocks * 16
    return 32 + ((originalSize ~/ 16) + 1) * 16;
  }

  /// Derives a 32-byte key from [password] and [salt] using PBKDF2.
  static Uint8List _deriveKey(String password, Uint8List salt) {
    final pbkdf2 = pc.KeyDerivator('SHA-256/HMAC/PBKDF2');
    final params = pc.Pbkdf2Parameters(
      salt,
      10000,
      32,
    ); // 10k iterations, 32 bytes output
    pbkdf2.init(params);
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// Generates a secure random salt of [length] bytes.
  static Uint8List _generateRandomBytes(int length) {
    final rnd = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = rnd.nextInt(256);
    }
    return bytes;
  }

  /// Encrypts a stream of data using AES-CBC with PKCS7 padding.
  /// Output Format: [Salt (16B)] [IV (16B)] [Encrypted Data Stream]
  static Stream<List<int>> encryptStream(
    Stream<List<int>> source,
    String password,
  ) async* {
    final salt = _generateRandomBytes(16);
    final iv = _generateRandomBytes(16);

    final key = _deriveKey(password, salt);

    final engine = pc.BlockCipher('AES/CBC');
    final params = pc.ParametersWithIV(pc.KeyParameter(key), iv);
    engine.init(true, params); // true = encrypt

    // Yield Header
    yield [...salt, ...iv];

    List<int> remainder = [];
    final blockSize = engine.blockSize;

    await for (final chunk in source) {
      List<int> currentBatch;
      if (remainder.isEmpty) {
        currentBatch = chunk;
      } else {
        currentBatch = [...remainder, ...chunk];
        remainder = [];
      }

      int offset = 0;
      while (offset + blockSize <= currentBatch.length) {
        final input = Uint8List.fromList(
          currentBatch.sublist(offset, offset + blockSize),
        );
        final output = Uint8List(blockSize);
        engine.processBlock(input, 0, output, 0);
        yield output;
        offset += blockSize;
      }

      if (offset < currentBatch.length) {
        remainder = currentBatch.sublist(offset);
      }
    }

    // Apply PKCS7 padding to remainder (handles empty files too)
    // For empty data, remainder.length is 0, so padLen will be blockSize (16)
    final padLen = blockSize - (remainder.length % blockSize);
    // Ensure padLen is never 0 by using modulo
    final actualPadLen = padLen == 0 ? blockSize : padLen;
    final padded = Uint8List(remainder.length + actualPadLen);

    // Copy remainder data if any
    if (remainder.isNotEmpty) {
      padded.setAll(0, remainder);
    }

    // Add padding bytes
    for (var i = remainder.length; i < padded.length; i++) {
      padded[i] = actualPadLen;
    }

    // Encrypt padded block(s)
    for (var offset = 0; offset < padded.length; offset += blockSize) {
      final output = Uint8List(blockSize);
      engine.processBlock(padded, offset, output, 0);
      yield output;
    }
  }

  /// Decrypts a stream of data.
  /// Expects Format: [Salt (16B)] [IV (16B)] [Encrypted Data Stream]
  static Stream<List<int>> decryptStream(
    Stream<List<int>> source,
    String password,
  ) async* {
    List<int> headerBuffer = [];
    bool headerParsed = false;
    pc.BlockCipher? engine;
    List<int> remainder = []; // Buffer for incoming encrypted data remainder
    List<int> decryptedBuffer =
        []; // Buffer for decrypted data waiting to be yielded
    final blockSize = 16; // AES

    await for (final chunk in source) {
      List<int> currentBatch = chunk;
      int currentBatchOffset = 0;

      if (!headerParsed) {
        // Combine with any previous header data
        if (headerBuffer.isNotEmpty) {
          headerBuffer.addAll(chunk);
          currentBatch = []; // Consumed by headerBuffer for now
        } else {
          // Check if we have enough for header in this chunk
          if (chunk.length >= 32) {
            headerBuffer.addAll(chunk.sublist(0, 32));
            currentBatch = chunk;
            currentBatchOffset = 32;
          } else {
            headerBuffer.addAll(chunk);
            currentBatch = [];
          }
        }

        if (headerBuffer.length >= 32) {
          final salt = Uint8List.fromList(headerBuffer.sublist(0, 16));
          final iv = Uint8List.fromList(headerBuffer.sublist(16, 32));
          // If headerBuffer had more than 32 bytes (from accumulation), add to currentBatch
          if (headerBuffer.length > 32) {
            // This case happens if we accumulated multiple small chunks
            // We need to process the rest
            final extra = headerBuffer.sublist(32);
            currentBatch = [...extra, ...currentBatch];
            currentBatchOffset = 0; // Reset offset as we rebuilt currentBatch
          }

          final key = _deriveKey(password, salt);
          engine = pc.BlockCipher('AES/CBC');
          engine.init(false, pc.ParametersWithIV(pc.KeyParameter(key), iv));

          headerParsed = true;
        }
      }

      if (headerParsed && engine != null) {
        // Combine remainder with available data
        List<int> dataToProcess;
        if (remainder.isEmpty) {
          if (currentBatchOffset > 0) {
            dataToProcess = currentBatch.sublist(currentBatchOffset);
          } else {
            dataToProcess = currentBatch;
          }
        } else {
          if (currentBatchOffset > 0) {
            dataToProcess = [
              ...remainder,
              ...currentBatch.sublist(currentBatchOffset),
            ];
          } else {
            dataToProcess = [...remainder, ...currentBatch];
          }
          remainder = [];
        }

        int offset = 0;
        while (offset + blockSize <= dataToProcess.length) {
          final input = Uint8List.fromList(
            dataToProcess.sublist(offset, offset + blockSize),
          );
          final output = Uint8List(blockSize);
          engine.processBlock(input, 0, output, 0);
          decryptedBuffer.addAll(output);
          offset += blockSize;

          // Yield everything except the last block
          if (decryptedBuffer.length > blockSize) {
            final yieldLen = decryptedBuffer.length - blockSize;
            yield decryptedBuffer.sublist(0, yieldLen);
            decryptedBuffer = decryptedBuffer.sublist(yieldLen);
          }
        }

        if (offset < dataToProcess.length) {
          remainder = dataToProcess.sublist(offset);
        }
      }
    }

    if (!headerParsed) {
      throw Exception('File too short or invalid header');
    }

    if (remainder.isNotEmpty) {
      throw Exception(
        'Encrypted file corrupted (length not multiple of block size)',
      );
    }

    // Handle padding in decryptedBuffer
    if (decryptedBuffer.isEmpty) {
      return;
    }

    // Remove padding with error handling
    try {
      final lastByte = decryptedBuffer.last;
      if (lastByte < 1 || lastByte > blockSize) {
        throw Exception('Invalid padding: padding byte out of range');
      }

      for (var i = 0; i < lastByte; i++) {
        if (decryptedBuffer[decryptedBuffer.length - 1 - i] != lastByte) {
          throw Exception('Invalid padding: inconsistent padding bytes');
        }
      }

      final validLen = decryptedBuffer.length - lastByte;
      if (validLen > 0) {
        yield decryptedBuffer.sublist(0, validLen);
      }
    } catch (e) {
      // Wrap any error (ArgumentError, RangeError, etc.) as Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Decryption failed: ${e.toString()}');
    }
  }
}
