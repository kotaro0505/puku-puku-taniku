#!/usr/bin/env node

import { createHash } from "node:crypto";
import { readFile, stat } from "node:fs/promises";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

export const PRODUCT_COUNT = 36;
export const BATCH_MANIFEST_FILENAME = "iap-review-capture-manifest.json";

export const APPLE_IPHONE_PORTRAIT_SIZES = new Set([
  "1398x2034", "2007x2853",
  "1260x2736", "1290x2796", "1320x2868",
  "1284x2778", "1242x2688",
  "1179x2556", "1206x2622",
  "1170x2532", "1125x2436", "1080x2340",
  "1242x2208", "750x1334",
  "640x1096", "640x1136", "640x920", "640x960",
]);

export function expectedProductIds() {
  return Array.from({ length: PRODUCT_COUNT }, (_, index) => `pot_unlock_${String(index + 1).padStart(3, "0")}`);
}

export function inspectPng(buffer) {
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (buffer.length < 33 || !buffer.subarray(0, 8).equals(signature)) throw new Error("not_png");
  if (buffer.toString("ascii", 12, 16) !== "IHDR") throw new Error("missing_ihdr");
  const width = buffer.readUInt32BE(16);
  const height = buffer.readUInt32BE(20);
  const bitDepth = buffer[24];
  const colorType = buffer[25];
  return {
    width,
    height,
    bitDepth,
    colorType,
    hasAlpha: colorType === 4 || colorType === 6,
    sha256: createHash("sha256").update(buffer).digest("hex"),
  };
}

function verifyPrice(capture) {
  const storefront = String(capture.storefront_country_code ?? "").toUpperCase();
  const currency = String(capture.storekit_currency_code ?? "").toUpperCase();
  const value = capture.storekit_currency_value;
  const localized = String(capture.storekit_localized_price ?? "").trim();
  if (!/^[A-Z]{3}$/.test(storefront)) throw new Error("storefront_country_code_invalid");
  if (!/^[A-Z]{3}$/.test(currency)) throw new Error("currency_code_invalid");
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) throw new Error("currency_value_invalid");
  if (!localized) throw new Error("localized_price_missing");
  if (storefront === "USA" && currency !== "USD") throw new Error("usa_storefront_currency_mismatch");
  if (storefront === "JPN" && currency !== "JPY") throw new Error("japan_storefront_currency_mismatch");
  return { storefront, currency, value, localized };
}

function verifyComposition(capture, png) {
  if (capture.capture_composition !== "native_screen_with_unscaled_viewport_and_black_letterbox") {
    throw new Error("capture_composition_mismatch");
  }
  if (capture.content_scaled !== false) throw new Error("capture_content_must_not_be_scaled");
  for (const key of [
    "viewport_content_width",
    "viewport_content_height",
    "viewport_offset_x",
    "viewport_offset_y",
    "letterbox_top",
    "letterbox_bottom",
  ]) {
    if (!Number.isInteger(capture[key]) || capture[key] < 0) throw new Error(`capture_geometry_invalid:${key}`);
  }
  if (capture.viewport_content_width !== png.width || capture.viewport_offset_x !== 0) {
    throw new Error("capture_viewport_width_or_offset_invalid");
  }
  if (capture.viewport_content_height > png.height) throw new Error("capture_viewport_height_invalid");
  if (capture.viewport_offset_y !== Math.floor((png.height - capture.viewport_content_height) / 2)) {
    throw new Error("capture_viewport_not_centered");
  }
  if (capture.letterbox_top !== capture.viewport_offset_y) throw new Error("capture_top_letterbox_invalid");
  if (capture.letterbox_bottom !== png.height - capture.viewport_offset_y - capture.viewport_content_height) {
    throw new Error("capture_bottom_letterbox_invalid");
  }
}

export function verifyCapture(pngBuffer, capture) {
  const png = inspectPng(pngBuffer);
  const size = `${png.width}x${png.height}`;
  if (!APPLE_IPHONE_PORTRAIT_SIZES.has(size)) throw new Error(`unsupported_dimensions:${size}`);
  if (png.bitDepth !== 8 || png.colorType !== 2 || png.hasAlpha) throw new Error("png_must_be_rgb8_without_alpha");
  if (!expectedProductIds().includes(capture.product_id)) throw new Error("product_id_invalid");
  if (capture.filename !== `${capture.product_id}-app-review.png`) throw new Error("filename_product_id_mismatch");
  if (!String(capture.pot_id ?? "").trim()) throw new Error("pot_id_missing");
  if (!String(capture.pot_name ?? "").trim()) throw new Error("pot_name_missing");
  if (capture.iap_type !== "NON_CONSUMABLE") throw new Error("iap_type_mismatch");
  if (!Number.isInteger(capture.puku_price) || capture.puku_price < 0) throw new Error("puku_price_invalid");
  if (capture.width !== png.width || capture.height !== png.height) throw new Error("manifest_dimensions_mismatch");
  if (capture.format !== "PNG" || capture.pixel_format !== "RGB8" || capture.has_alpha !== false) {
    throw new Error("manifest_format_mismatch");
  }
  if (capture.sha256 !== png.sha256) throw new Error("sha256_mismatch");
  verifyComposition(capture, png);
  const price = verifyPrice(capture);
  const checks = capture.content_checks ?? {};
  for (const key of [
    "product_id_matches_card",
    "card_fully_visible",
    "pot_image_visible",
    "pot_image_fully_inside",
    "japanese_name_visible",
    "japanese_name_fully_inside",
    "permanent_unlock_visible",
    "puku_price_visible",
    "storekit_button_visible",
    "storekit_price_valid",
  ]) {
    if (checks[key] !== true) throw new Error(`content_check_failed:${key}`);
  }
  return { ...png, productId: capture.product_id, ...price };
}

export function verifyBatchManifest(manifest) {
  if (manifest.schema_version !== 2 || manifest.capture_mode !== "iap_review_capture_batch") {
    throw new Error("batch_schema_mismatch");
  }
  if (manifest.product_count !== PRODUCT_COUNT || !Array.isArray(manifest.captures) || manifest.captures.length !== PRODUCT_COUNT) {
    throw new Error("batch_product_count_mismatch");
  }
  const expected = expectedProductIds();
  if (JSON.stringify(manifest.expected_product_ids) !== JSON.stringify(expected)) throw new Error("batch_expected_ids_mismatch");
  const actual = manifest.captures.map((capture) => capture.product_id);
  if (new Set(actual).size !== PRODUCT_COUNT) throw new Error("batch_duplicate_product_id");
  if (JSON.stringify(actual) !== JSON.stringify(expected)) throw new Error("batch_missing_or_out_of_order_product_id");
  if (!APPLE_IPHONE_PORTRAIT_SIZES.has(`${manifest.width}x${manifest.height}`)) throw new Error("batch_dimensions_invalid");
  if (manifest.capture_composition !== "native_screen_with_unscaled_viewport_and_black_letterbox" || manifest.content_scaled !== false) {
    throw new Error("batch_capture_composition_mismatch");
  }
  if (!Number.isInteger(manifest.viewport_content_width) || !Number.isInteger(manifest.viewport_content_height)) {
    throw new Error("batch_viewport_dimensions_invalid");
  }
  for (const capture of manifest.captures) {
    if (capture.width !== manifest.width || capture.height !== manifest.height) throw new Error("batch_capture_dimensions_mismatch");
    if (capture.viewport_content_width !== manifest.viewport_content_width || capture.viewport_content_height !== manifest.viewport_content_height) {
      throw new Error("batch_viewport_dimensions_mismatch");
    }
  }
  if (manifest.format !== "PNG" || manifest.pixel_format !== "RGB8" || manifest.has_alpha !== false) {
    throw new Error("batch_format_mismatch");
  }
  return manifest.captures;
}

async function main() {
  const directory = process.argv[2];
  if (!directory || directory === "--help") {
    console.log("usage: node tools/verify_iap_review_capture.mjs <extracted-capture-directory> [batch-manifest.json]");
    return;
  }
  const directoryStat = await stat(directory);
  if (!directoryStat.isDirectory()) throw new Error("capture_directory_required_extract_zip_first");
  const manifestPath = process.argv[3] ?? join(directory, BATCH_MANIFEST_FILENAME);
  const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
  const captures = verifyBatchManifest(manifest);
  let storefront = "";
  let currency = "";
  for (const capture of captures) {
    const result = verifyCapture(await readFile(join(directory, capture.filename)), capture);
    if (!storefront) {
      storefront = result.storefront;
      currency = result.currency;
    } else if (result.storefront !== storefront || result.currency !== currency) {
      throw new Error(`batch_price_context_changed:${capture.product_id}`);
    }
  }
  console.log(
    `IAP_REVIEW_CAPTURE_VERIFY_OK products=${captures.length} size=${manifest.width}x${manifest.height} ` +
    `format=PNG pixel_format=RGB8 alpha=false storefront=${storefront} currency=${currency}`,
  );
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) {
  main().catch((error) => {
    console.error(`IAP_REVIEW_CAPTURE_VERIFY_FAILED reason=${error.message}`);
    process.exitCode = 1;
  });
}
