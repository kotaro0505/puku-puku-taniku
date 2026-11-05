#!/usr/bin/env node

import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { pathToFileURL } from "node:url";

export const TARGET = Object.freeze({
  productId: "pot_unlock_001",
  potId: "g1_crystal_goblet",
  potName: "クリスタルゴブレット鉢",
  pukuPrice: 2,
  japanPriceYen: 100,
});

export const APPLE_IPHONE_PORTRAIT_SIZES = new Set([
  "1398x2034", "2007x2853",
  "1260x2736", "1290x2796", "1320x2868",
  "1284x2778", "1242x2688",
  "1179x2556", "1206x2622",
  "1170x2532", "1125x2436", "1080x2340",
  "1242x2208", "750x1334",
  "640x1096", "640x1136", "640x920", "640x960",
]);

export function inspectPng(buffer) {
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (buffer.length < 33 || !buffer.subarray(0, 8).equals(signature)) {
    throw new Error("not_png");
  }
  if (buffer.toString("ascii", 12, 16) !== "IHDR") {
    throw new Error("missing_ihdr");
  }
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

export function verifyCapture(pngBuffer, manifest) {
  const png = inspectPng(pngBuffer);
  const size = `${png.width}x${png.height}`;
  if (!APPLE_IPHONE_PORTRAIT_SIZES.has(size)) throw new Error(`unsupported_dimensions:${size}`);
  if (png.bitDepth !== 8 || png.colorType !== 2 || png.hasAlpha) throw new Error("png_must_be_rgb8_without_alpha");
  if (manifest.product_id !== TARGET.productId) throw new Error("product_id_mismatch");
  if (manifest.pot_id !== TARGET.potId) throw new Error("pot_id_mismatch");
  if (manifest.pot_name !== TARGET.potName) throw new Error("pot_name_mismatch");
  if (manifest.iap_type !== "NON_CONSUMABLE") throw new Error("iap_type_mismatch");
  if (manifest.puku_price !== TARGET.pukuPrice) throw new Error("puku_price_mismatch");
  if (manifest.expected_japan_price_yen !== TARGET.japanPriceYen) throw new Error("japan_price_mismatch");
  if (manifest.width !== png.width || manifest.height !== png.height) throw new Error("manifest_dimensions_mismatch");
  if (manifest.format !== "PNG" || manifest.pixel_format !== "RGB8" || manifest.has_alpha !== false) {
    throw new Error("manifest_format_mismatch");
  }
  if (manifest.sha256 !== png.sha256) throw new Error("sha256_mismatch");
  const contentChecks = manifest.content_checks ?? {};
  const requiredChecks = [
    "card_fully_visible",
    "pot_image_visible",
    "japanese_name_visible",
    "permanent_unlock_visible",
    "puku_price_visible",
    "storekit_button_visible",
    "storekit_price_is_jpy_100",
  ];
  for (const key of requiredChecks) {
    if (contentChecks[key] !== true) throw new Error(`content_check_failed:${key}`);
  }
  return { ...png, productId: manifest.product_id, localizedPrice: manifest.storekit_localized_price };
}

async function main() {
  const pngPath = process.argv[2];
  if (!pngPath || pngPath === "--help") {
    console.log("usage: node tools/verify_iap_review_capture.mjs <pot_unlock_001-app-review.png> [manifest.json]");
    return;
  }
  const manifestPath = process.argv[3] ?? pngPath.replace(/\.png$/i, ".json");
  const [pngBuffer, manifestText] = await Promise.all([
    readFile(pngPath),
    readFile(manifestPath, "utf8"),
  ]);
  const result = verifyCapture(pngBuffer, JSON.parse(manifestText));
  console.log(
    `IAP_REVIEW_CAPTURE_VERIFY_OK product_id=${result.productId} size=${result.width}x${result.height} ` +
    `format=PNG pixel_format=RGB8 alpha=false storekit_price=${JSON.stringify(result.localizedPrice)}`,
  );
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) {
  main().catch((error) => {
    console.error(`IAP_REVIEW_CAPTURE_VERIFY_FAILED reason=${error.message}`);
    process.exitCode = 1;
  });
}
