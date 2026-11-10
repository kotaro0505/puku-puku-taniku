import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import test from "node:test";

import {
  expectedProductIds,
  inspectPng,
  verifyBatchManifest,
  verifyCapture,
} from "./verify_iap_review_capture.mjs";

function pngHeader(width = 1125, height = 2436, colorType = 2) {
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

function capture(buffer, productId = "pot_unlock_001") {
  return {
    product_id: productId,
    pot_id: `pot_${productId}`,
    pot_name: `鉢 ${productId}`,
    catalog_image_path: `res://assets/${productId}.png`,
    iap_type: "NON_CONSUMABLE",
    puku_price: 2,
    storefront_country_code: "USA",
    storekit_currency_code: "USD",
    storekit_currency_value: 0.49,
    storekit_localized_price: "$0.49",
    filename: `${productId}-app-review.png`,
    width: 1125,
    height: 2436,
    viewport_content_width: 1125,
    viewport_content_height: 2000,
    viewport_offset_x: 0,
    viewport_offset_y: 218,
    letterbox_top: 218,
    letterbox_bottom: 218,
    capture_composition: "native_screen_with_unscaled_viewport_and_black_letterbox",
    content_scaled: false,
    format: "PNG",
    pixel_format: "RGB8",
    has_alpha: false,
    sha256: createHash("sha256").update(buffer).digest("hex"),
    content_checks: {
      product_id_matches_card: true,
      card_fully_visible: true,
      pot_image_visible: true,
      pot_image_fully_inside: true,
      japanese_name_visible: true,
      japanese_name_fully_inside: true,
      permanent_unlock_visible: true,
      puku_price_visible: true,
      storekit_button_visible: true,
      storekit_price_valid: true,
    },
  };
}

function batch(buffer) {
  const captures = expectedProductIds().map((productId) => capture(buffer, productId));
  return {
    schema_version: 2,
    capture_mode: "iap_review_capture_batch",
    product_count: 36,
    expected_product_ids: expectedProductIds(),
    storefront_country_code: "USA",
    currency_code: "USD",
    width: 1125,
    height: 2436,
    viewport_content_width: 1125,
    viewport_content_height: 2000,
    capture_composition: "native_screen_with_unscaled_viewport_and_black_letterbox",
    content_scaled: false,
    format: "PNG",
    pixel_format: "RGB8",
    has_alpha: false,
    captures,
  };
}

test("accepts a real US StoreKit price without replacing it with JPY", () => {
  const buffer = pngHeader();
  const result = verifyCapture(buffer, capture(buffer));
  assert.equal(result.width, 1125);
  assert.equal(result.storefront, "USA");
  assert.equal(result.currency, "USD");
  assert.equal(result.localized, "$0.49");
});

test("accepts the exact 36-product batch contract", () => {
  const buffer = pngHeader();
  const captures = verifyBatchManifest(batch(buffer));
  assert.equal(captures.length, 36);
  assert.equal(captures[35].product_id, "pot_unlock_036");
});

test("rejects an alpha-channel PNG", () => {
  const buffer = pngHeader(1320, 2868, 6);
  assert.equal(inspectPng(buffer).hasAlpha, true);
  assert.throws(() => verifyCapture(buffer, capture(buffer)), /png_must_be_rgb8_without_alpha/);
});

test("rejects the logical 576x1024 viewport size", () => {
  const buffer = pngHeader(576, 1024, 2);
  const data = capture(buffer);
  data.width = 576;
  data.height = 1024;
  assert.throws(() => verifyCapture(buffer, data), /unsupported_dimensions:576x1024/);
});

test("rejects scaled or incorrectly centered capture composition", () => {
  const buffer = pngHeader();
  const scaled = capture(buffer);
  scaled.content_scaled = true;
  assert.throws(() => verifyCapture(buffer, scaled), /capture_content_must_not_be_scaled/);
  const offCenter = capture(buffer);
  offCenter.viewport_offset_y = 217;
  assert.throws(() => verifyCapture(buffer, offCenter), /capture_viewport_not_centered/);
});

test("rejects a bool currency value and storefront/currency mismatch", () => {
  const buffer = pngHeader();
  const boolPrice = capture(buffer);
  boolPrice.storekit_currency_value = true;
  assert.throws(() => verifyCapture(buffer, boolPrice), /currency_value_invalid/);
  const mismatch = capture(buffer);
  mismatch.storekit_currency_code = "JPY";
  assert.throws(() => verifyCapture(buffer, mismatch), /usa_storefront_currency_mismatch/);
});

test("rejects missing, duplicate, or misordered product ids", () => {
  const buffer = pngHeader();
  const duplicate = batch(buffer);
  duplicate.captures[35] = { ...duplicate.captures[34] };
  assert.throws(() => verifyBatchManifest(duplicate), /batch_duplicate_product_id/);
  const missing = batch(buffer);
  missing.captures.pop();
  assert.throws(() => verifyBatchManifest(missing), /batch_product_count_mismatch/);
  const swapped = batch(buffer);
  [swapped.captures[0], swapped.captures[1]] = [swapped.captures[1], swapped.captures[0]];
  assert.throws(() => verifyBatchManifest(swapped), /batch_missing_or_out_of_order_product_id/);
});

test("rejects a missing visible-content check", () => {
  const buffer = pngHeader();
  const data = capture(buffer);
  data.content_checks.storekit_button_visible = false;
  assert.throws(() => verifyCapture(buffer, data), /content_check_failed:storekit_button_visible/);
});
