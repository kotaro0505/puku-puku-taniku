import assert from "node:assert/strict";
import {
  createVerify,
  generateKeyPairSync,
} from "node:crypto";
import { readFile } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import {
  assertRequiredExistingProducts,
  assertRequiredMissingProducts,
  buildAvailabilityPayload,
  buildDesiredProducts,
  buildLocalizationCreatePayload,
  buildPriceSchedulePayload,
  buildProductCreatePayload,
  buildScreenshotReservationPayload,
  buildVersionCreatePayload,
  commandRequiresWrites,
  createJwt,
  expectedPukuPrice,
  inspectionGaps,
  parseExcludedProductIds,
  summarizePriceOptions,
} from "./app_store_connect_iap.mjs";

const TOOL_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(TOOL_DIR, "..");

async function readJson(relativePath) {
  return JSON.parse(
    await readFile(path.join(REPO_ROOT, relativePath), "utf8"),
  );
}

test("catalog has all 36 immutable StoreKit IDs and official game prices", async () => {
  const catalog = await readJson("data/pot-iap-catalog.json");
  const products = buildDesiredProducts(catalog);
  assert.equal(products.length, 36);
  for (let index = 0; index < products.length; index += 1) {
    const number = index + 1;
    assert.equal(
      products[index].productId,
      "pot_unlock_" + String(number).padStart(3, "0"),
    );
    assert.equal(products[index].inGamePukuPrice, expectedPukuPrice(number));
    assert.ok(products[index].displayNameJa.length >= 2);
    assert.ok(products[index].displayNameEn.length >= 2);
  }
  assert.equal(products[0].displayNameJa, "クリスタルゴブレット鉢");
  assert.equal(products[0].displayNameEn, "Crystal Goblet Pot");
  assert.equal(products[9].displayNameEn, "Rose Gold Glass Pot");
  assert.equal(products[35].displayNameJa, "ラーメン鉢");
});

test("approved Japanese and English descriptions stay exact", async () => {
  const config = await readJson("tools/app_store_connect_iap.config.example.json");
  assert.equal(
    config.localizations.ja.description,
    "デザインを永続解放。以後ぷくコインで購入できます。",
  );
  assert.equal(
    config.localizations["en-US"].description,
    "Unlocks this design. Pots cost Puku Coins.",
  );
  assert.equal(config.priceSourceProductId, "");
  assert.equal(config.availabilitySourceProductId, "");
  assert.equal(config.desiredCustomerPrice, "");
  assert.equal(config.sellInAllTerritories, false);
  assert.equal(config.availableInNewTerritories, false);
  assert.deepEqual(config.reviewScreenshots, {});
});

test("local authentication template contains no credential or private key", async () => {
  const auth = await readJson("tools/app_store_connect_iap.auth.example.json");
  assert.equal(auth.schemaVersion, 1);
  assert.equal(auth.keyType, "team");
  assert.equal(auth.keyId, "");
  assert.equal(auth.issuerId, "");
  assert.equal(auth.privateKeyPath, "");
  assert.equal(auth.appId, "");
  const gitignore = await readFile(path.join(REPO_ROOT, ".gitignore"), "utf8");
  assert.equal(gitignore.includes("*.p8"), true);
  assert.equal(
    gitignore.includes("/tools/app_store_connect_iap.auth.local.json"),
    true,
  );
});

test("App Store listing draft contains the approved descriptions for all products", async () => {
  const listing = await readFile(
    path.join(REPO_ROOT, "docs/app-store-listing-draft.md"),
    "utf8",
  );
  assert.equal(
    listing.split("デザインを永続解放。以後ぷくコインで購入できます。").length - 1,
    36,
  );
  assert.equal(
    listing.split("Unlocks this design. Pots cost Puku Coins.").length - 1,
    36,
  );
  assert.equal(listing.includes("以後1ぷくコインで購入できます"), false);
  assert.equal(listing.includes("pots cost 1 Puku Coin"), false);
});

test("JWT uses ES256 P1363 and never embeds the private key", () => {
  const { privateKey, publicKey } = generateKeyPairSync("ec", {
    namedCurve: "prime256v1",
  });
  const token = createJwt({
    keyId: "TESTKEY123",
    issuerId: "00000000-0000-0000-0000-000000000000",
    keyType: "team",
    privateKey,
    nowSeconds: 1700000000,
  });
  const pieces = token.split(".");
  assert.equal(pieces.length, 3);
  const header = JSON.parse(Buffer.from(pieces[0], "base64url").toString("utf8"));
  const payload = JSON.parse(Buffer.from(pieces[1], "base64url").toString("utf8"));
  assert.deepEqual(header, {
    alg: "ES256",
    kid: "TESTKEY123",
    typ: "JWT",
  });
  assert.equal(payload.aud, "appstoreconnect-v1");
  assert.equal(payload.iss, "00000000-0000-0000-0000-000000000000");
  assert.equal(payload.exp - payload.iat, 905);
  const verifier = createVerify("SHA256");
  verifier.update(pieces[0] + "." + pieces[1]);
  verifier.end();
  assert.equal(
    verifier.verify(
      { key: publicKey, dsaEncoding: "ieee-p1363" },
      Buffer.from(pieces[2], "base64url"),
    ),
    true,
  );
});

test("individual JWT uses sub=user instead of an issuer", () => {
  const { privateKey } = generateKeyPairSync("ec", {
    namedCurve: "prime256v1",
  });
  const token = createJwt({
    keyId: "INDIVIDUAL",
    issuerId: "",
    keyType: "individual",
    privateKey,
    nowSeconds: 1700000000,
  });
  const payload = JSON.parse(
    Buffer.from(token.split(".")[1], "base64url").toString("utf8"),
  );
  assert.equal(payload.sub, "user");
  assert.equal(Object.hasOwn(payload, "iss"), false);
});

test("payloads use current versioned IAP APIs and non-consumable type", async () => {
  const catalog = await readJson("data/pot-iap-catalog.json");
  const product = buildDesiredProducts(catalog)[0];
  const create = buildProductCreatePayload("APP123", product);
  assert.equal(create.data.type, "inAppPurchases");
  assert.equal(create.data.attributes.inAppPurchaseType, "NON_CONSUMABLE");
  assert.equal(create.data.attributes.productId, "pot_unlock_001");
  assert.equal(create.data.relationships.app.data.id, "APP123");

  const version = buildVersionCreatePayload("IAP123");
  assert.equal(version.data.type, "inAppPurchaseVersions");
  assert.equal(version.data.relationships.inAppPurchase.data.id, "IAP123");

  const localization = buildLocalizationCreatePayload(
    "VERSION123",
    "ja",
    product.displayNameJa,
    "デザインを永続解放。以後ぷくコインで購入できます。",
  );
  assert.equal(localization.data.type, "inAppPurchaseLocalizations");
  assert.equal(localization.data.relationships.version.data.type, "inAppPurchaseVersions");
  assert.equal(localization.data.relationships.version.data.id, "VERSION123");
});

test("price and territory payloads copy explicit Apple-side policy only", () => {
  const price = buildPriceSchedulePayload("IAP123", "POINT123", "JPN");
  assert.equal(price.data.type, "inAppPurchasePriceSchedules");
  assert.equal(price.data.relationships.baseTerritory.data.id, "JPN");
  assert.equal(price.data.relationships.inAppPurchase.data.id, "IAP123");
  assert.equal(
    price.data.relationships.manualPrices.data[0].id,
    "${initial-price}",
  );
  assert.equal(price.included[0].id, "${initial-price}");
  assert.equal(
    price.included[0].relationships.inAppPurchasePricePoint.data.id,
    "POINT123",
  );
  assert.equal(
    price.included[0].relationships.inAppPurchaseV2.data.type,
    "inAppPurchases",
  );

  const availability = buildAvailabilityPayload(
    "IAP123",
    ["JPN", "USA"],
    false,
  );
  assert.deepEqual(
    availability.data.relationships.availableTerritories.data.map((item) => item.id),
    ["JPN", "USA"],
  );
  assert.equal(
    availability.data.attributes.availableInNewTerritories,
    false,
  );

  const worldwideAvailability = buildAvailabilityPayload(
    "IAP123",
    ["JPN", "USA"],
    true,
  );
  assert.equal(
    worldwideAvailability.data.attributes.availableInNewTerritories,
    true,
  );
});

test("review screenshot payload targets the parent IAP", () => {
  const payload = buildScreenshotReservationPayload(
    "IAP123",
    "real-app-screen.png",
    123456,
  );
  assert.equal(payload.data.type, "inAppPurchaseAppStoreReviewScreenshots");
  assert.equal(payload.data.attributes.fileName, "real-app-screen.png");
  assert.equal(payload.data.attributes.fileSize, 123456);
  assert.equal(payload.data.relationships.inAppPurchaseV2.data.id, "IAP123");
});

test("plan and dry-run are read-only; only explicit write commands can write", () => {
  assert.equal(commandRequiresWrites("plan"), false);
  assert.equal(commandRequiresWrites("dry-run"), false);
  assert.equal(commandRequiresWrites("policy-research"), false);
  assert.equal(commandRequiresWrites("verify-catalog"), false);
  assert.equal(commandRequiresWrites("stage-one"), true);
  assert.equal(commandRequiresWrites("stage-all"), true);
  assert.equal(commandRequiresWrites("apply-one"), true);
  assert.equal(commandRequiresWrites("apply-all"), true);
});

test("existing-product-only writes cannot enter the product creation path", () => {
  const selected = [{ productId: "pot_unlock_002" }];
  assert.doesNotThrow(() => {
    assertRequiredExistingProducts(
      selected,
      new Map([["pot_unlock_002", { id: "REMOTE002" }]]),
      true,
    );
  });
  assert.throws(
    () => assertRequiredExistingProducts(selected, new Map(), true),
    /Existing-product-only write blocked/,
  );
});

test("approved batch selection excludes protected products and requires new IDs", () => {
  const known = new Set([
    "pot_unlock_001",
    "pot_unlock_002",
    "pot_unlock_003",
  ]);
  const excluded = parseExcludedProductIds(
    "pot_unlock_001,pot_unlock_002",
    known,
  );
  assert.deepEqual([...excluded], ["pot_unlock_001", "pot_unlock_002"]);
  const selected = [{ productId: "pot_unlock_003" }];
  assert.doesNotThrow(() => {
    assertRequiredMissingProducts(selected, new Map(), true);
  });
  assert.throws(
    () => assertRequiredMissingProducts(
      selected,
      new Map([["pot_unlock_003", { id: "REMOTE003" }]]),
      true,
    ),
    /New-product-only write blocked/,
  );
});

test("price research reports exact and neighboring selectable prices", () => {
  const summary = summarizePriceOptions([
    { id: "LOW", attributes: { customerPrice: "90" } },
    { id: "EXACT", attributes: { customerPrice: "100" } },
    { id: "HIGH", attributes: { customerPrice: "120" } },
  ], "100");
  assert.equal(summary.exact.length, 1);
  assert.equal(summary.exact[0].point.id, "EXACT");
  assert.equal(summary.lower, 90);
  assert.equal(summary.higher, 120);
});

test("product inspection tolerates an unset availability relationship", async () => {
  const source = await readFile(
    path.join(TOOL_DIR, "app_store_connect_iap.mjs"),
    "utf8",
  );
  assert.equal(
    source.includes(
      '"versions,appStoreReviewScreenshot,iapPriceSchedule,inAppPurchaseAvailability"',
    ),
    false,
  );
  assert.equal(
    source.includes("await readAvailability(client, remote.id);"),
    true,
  );
});

test("read-only inspection reports every missing registration input", async () => {
  const catalog = await readJson("data/pot-iap-catalog.json");
  const product = buildDesiredProducts(catalog)[0];
  const gaps = inspectionGaps(product, {
    resource: {
      attributes: {
        inAppPurchaseType: "NON_CONSUMABLE",
        name: product.referenceName,
        reviewNote: product.reviewNote,
      },
    },
    metadataVersion: null,
    localizations: new Map(),
    price: null,
    availability: null,
    screenshotState: "",
  });
  assert.deepEqual(gaps, [
    "IAP metadata version",
    "Japanese localization",
    "English localization",
    "JPN price",
    "sale territories",
    "review screenshot",
  ]);
});

test("tool contains no review-submission or release endpoint", async () => {
  const source = await readFile(
    path.join(TOOL_DIR, "app_store_connect_iap.mjs"),
    "utf8",
  );
  assert.equal(source.includes("/v1/reviewSubmissions"), false);
  assert.equal(source.includes("/v1/reviewSubmissionItems"), false);
  assert.equal(source.includes("/v1/inAppPurchaseSubmissions"), false);
});
