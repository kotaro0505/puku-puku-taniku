import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import test from "node:test";

import { inspectPng, verifyCapture } from "./verify_iap_review_capture.mjs";

function pngHeader(width = 1320, height = 2868, colorType = 2) {
  const bytes = Buffer.alloc(33);
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]).copy(bytes, 0);
  bytes.writeUInt32BE(13, 8);
  bytes.write("IHDR", 12, "ascii");
  bytes.writeUInt32BE(width, 16);
  bytes.writeUInt32BE(height, 20);
  bytes[24] = 8;
  bytes[25] = colorType;
  return bytes;
}

function manifest(buffer) {
  return {
    product_id: "pot_unlock_001",
    pot_id: "g1_crystal_goblet",
    pot_name: "クリスタルゴブレット鉢",
    iap_type: "NON_CONSUMABLE",
    puku_price: 2,
    expected_japan_price_yen: 100,
    storekit_localized_price: "¥100",
    width: 1320,
    height: 2868,
    format: "PNG",
    pixel_format: "RGB8",
    has_alpha: false,
    sha256: createHash("sha256").update(buffer).digest("hex"),
    content_checks: {
      card_fully_visible: true,
      pot_image_visible: true,
      japanese_name_visible: true,
      permanent_unlock_visible: true,
      puku_price_visible: true,
      storekit_button_visible: true,
      storekit_price_is_jpy_100: true,
    },
  };
}

test("accepts the exact pot_unlock_001 RGB review capture contract", () => {
  const buffer = pngHeader();
  const result = verifyCapture(buffer, manifest(buffer));
  assert.equal(result.width, 1320);
  assert.equal(result.height, 2868);
  assert.equal(result.hasAlpha, false);
});

test("rejects an alpha-channel PNG", () => {
  const buffer = pngHeader(1320, 2868, 6);
  assert.equal(inspectPng(buffer).hasAlpha, true);
  assert.throws(() => verifyCapture(buffer, manifest(buffer)), /png_must_be_rgb8_without_alpha/);
});

test("rejects the logical 576x1024 viewport size", () => {
  const buffer = pngHeader(576, 1024, 2);
  const data = manifest(buffer);
  data.width = 576;
  data.height = 1024;
  assert.throws(() => verifyCapture(buffer, data), /unsupported_dimensions:576x1024/);
});

test("rejects a missing visible-content check", () => {
  const buffer = pngHeader();
  const data = manifest(buffer);
  data.content_checks.storekit_button_visible = false;
  assert.throws(() => verifyCapture(buffer, data), /content_check_failed:storekit_button_visible/);
});
