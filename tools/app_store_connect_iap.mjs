#!/usr/bin/env node

import {
  createHash,
  createSign,
} from "node:crypto";
import {
  access,
  readFile,
  stat,
} from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import {
  fileURLToPath,
  pathToFileURL,
} from "node:url";

const API_ORIGIN = "https://api.appstoreconnect.apple.com";
const TOOL_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(TOOL_DIR, "..");
const LOCAL_AUTH_PATH = path.join(TOOL_DIR, "app_store_connect_iap.auth.local.json");
const LOCAL_CONFIG_PATH = path.join(TOOL_DIR, "app_store_connect_iap.config.local.json");
const EXAMPLE_CONFIG_PATH = path.join(TOOL_DIR, "app_store_connect_iap.config.example.json");
const EXPECTED_BUNDLE_ID = "com.ohanayanouen.pukupukutaniku";
const EXPECTED_JA_DESCRIPTION = "デザインを永続解放。以後ぷくコインで購入できます。";
const EXPECTED_EN_DESCRIPTION = "Unlocks this design. Pots cost Puku Coins.";
const EXPECTED_PRODUCT_COUNT = 36;
const IAP_TYPE = "NON_CONSUMABLE";
const DRAFT_VERSION_STATE = "PREPARE_FOR_SUBMISSION";
const COMPLETE_ASSET_STATE = "COMPLETE";
const WRITE_COMMANDS = new Set([
  "stage-one",
  "stage-all",
  "apply-one",
  "apply-all",
]);

class ToolError extends Error {
  constructor(message, exitCode = 1) {
    super(message);
    this.name = "ToolError";
    this.exitCode = exitCode;
  }
}

class ApiError extends ToolError {
  constructor(method, url, status, details) {
    super(method + " " + url + " failed (" + status + "): " + details);
    this.name = "ApiError";
    this.status = status;
  }
}

function sleep(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function base64url(value) {
  return Buffer.from(value).toString("base64url");
}

function codePointLength(value) {
  return Array.from(String(value)).length;
}

function normalizedDecimal(value) {
  const text = String(value ?? "").trim();
  if (!/^-?\d+(?:\.\d+)?$/.test(text)) {
    return text;
  }
  const negative = text.startsWith("-");
  const unsigned = negative ? text.slice(1) : text;
  const pieces = unsigned.split(".");
  const whole = pieces[0].replace(/^0+(?=\d)/, "") || "0";
  const fraction = (pieces[1] || "").replace(/0+$/, "");
  return (negative ? "-" : "") + whole + (fraction ? "." + fraction : "");
}

function isPathInside(parentPath, childPath) {
  const relative = path.relative(path.resolve(parentPath), path.resolve(childPath));
  return relative !== "" && !relative.startsWith("..") && !path.isAbsolute(relative);
}

function parseArgs(argv) {
  const command = argv[0] || "help";
  const options = {};
  for (let index = 1; index < argv.length; index += 1) {
    const argument = argv[index];
    if (!argument.startsWith("--")) {
      throw new ToolError("Unknown argument: " + argument);
    }
    const key = argument.slice(2);
    const next = argv[index + 1];
    if (next === undefined || next.startsWith("--")) {
      options[key] = true;
    } else {
      options[key] = next;
      index += 1;
    }
  }
  return { command, options };
}

export function expectedPukuPrice(productNumber) {
  if (productNumber >= 1 && productNumber <= 9) {
    return 2;
  }
  if (productNumber === 10) {
    return 3;
  }
  if (productNumber >= 11 && productNumber <= 14) {
    return 30;
  }
  if (productNumber >= 15 && productNumber <= 23) {
    return 5;
  }
  if (productNumber >= 24 && productNumber <= 35) {
    return 10;
  }
  if (productNumber === 36) {
    return 100;
  }
  throw new ToolError("Unexpected pot product number: " + productNumber);
}

export function buildDesiredProducts(catalog) {
  if (!Array.isArray(catalog) || catalog.length !== EXPECTED_PRODUCT_COUNT) {
    throw new ToolError("The pot IAP catalog must contain exactly 36 products.");
  }
  const productIds = new Set();
  const potIds = new Set();
  return catalog.map((item, zeroBasedIndex) => {
    const number = zeroBasedIndex + 1;
    const expectedProductId = "pot_unlock_" + String(number).padStart(3, "0");
    if (!item || typeof item !== "object") {
      throw new ToolError("Catalog entry " + number + " is not an object.");
    }
    if (item.iap_product_id !== expectedProductId) {
      throw new ToolError(
        "Catalog product order mismatch: expected " + expectedProductId +
        ", got " + String(item.iap_product_id),
      );
    }
    if (item.unlock_type !== "iap_unlock") {
      throw new ToolError(expectedProductId + " must use unlock_type iap_unlock.");
    }
    if (Number(item.price_puku) !== expectedPukuPrice(number)) {
      throw new ToolError(
        expectedProductId + " has an unexpected in-game Puku Coin price. " +
        "This tool never changes game prices.",
      );
    }
    for (const key of ["pot_id", "display_name", "name_hiragana", "name_en"]) {
      if (typeof item[key] !== "string" || item[key].trim() === "") {
        throw new ToolError(expectedProductId + " is missing " + key + ".");
      }
    }
    if (productIds.has(expectedProductId) || potIds.has(item.pot_id)) {
      throw new ToolError("Duplicate catalog identity at " + expectedProductId + ".");
    }
    productIds.add(expectedProductId);
    potIds.add(item.pot_id);
    const referenceName =
      "Pot Unlock " + String(number).padStart(3, "0") + " - " + item.name_en;
    if (codePointLength(referenceName) > 64) {
      throw new ToolError(expectedProductId + " reference name exceeds 64 characters.");
    }
    if (codePointLength(item.display_name) < 2 || codePointLength(item.display_name) > 30) {
      throw new ToolError(expectedProductId + " Japanese display name must be 2-30 characters.");
    }
    if (codePointLength(item.name_en) < 2 || codePointLength(item.name_en) > 30) {
      throw new ToolError(expectedProductId + " English display name must be 2-30 characters.");
    }
    return {
      number,
      productId: expectedProductId,
      potId: item.pot_id,
      displayNameJa: item.display_name,
      displayNameEn: item.name_en,
      nameHiragana: item.name_hiragana,
      inGamePukuPrice: Number(item.price_puku),
      referenceName,
      reviewNote: buildReviewNote(number, item.name_en),
    };
  });
}

function buildReviewNote(number, englishName) {
  const unlockCondition = number <= 14
    ? "The Pots category appears after the opening tutorial; this item appears after discovering six fantasy varieties."
    : "The Pots category appears after the opening tutorial; this item appears after Act III is unlocked.";
  return (
    "Non-consumable purchase that permanently unlocks the " + englishName +
    " design. Open Panda's Shop > Pots. " + unlockCondition +
    " Restore Purchases is at the top of the Pots screen."
  );
}

async function readJsonFile(filePath) {
  let source;
  try {
    source = await readFile(filePath, "utf8");
  } catch (error) {
    throw new ToolError("Unable to read " + filePath + ": " + error.message);
  }
  try {
    return JSON.parse(source);
  } catch (error) {
    throw new ToolError("Invalid JSON in " + filePath + ": " + error.message);
  }
}

async function loadInputs(configOption) {
  const selectedConfigPath = configOption
    ? path.resolve(REPO_ROOT, String(configOption))
    : (existsSync(LOCAL_CONFIG_PATH) ? LOCAL_CONFIG_PATH : EXAMPLE_CONFIG_PATH);
  const config = await readJsonFile(selectedConfigPath);
  validateConfig(config);
  const catalogPath = path.resolve(REPO_ROOT, config.catalogPath);
  if (!isPathInside(REPO_ROOT, catalogPath)) {
    throw new ToolError("catalogPath must stay inside the project repository.");
  }
  const catalog = await readJsonFile(catalogPath);
  const products = buildDesiredProducts(catalog);
  const screenshotPaths = {};
  for (const product of products) {
    const configured = config.reviewScreenshots[product.productId];
    screenshotPaths[product.productId] = configured
      ? path.resolve(REPO_ROOT, configured)
      : "";
  }
  return {
    config,
    configPath: selectedConfigPath,
    catalogPath,
    products,
    screenshotPaths,
  };
}

function validateConfig(config) {
  if (!config || config.schemaVersion !== 1) {
    throw new ToolError("Unsupported App Store Connect IAP config schema.");
  }
  if (config.bundleId !== EXPECTED_BUNDLE_ID) {
    throw new ToolError("The production bundle ID must remain " + EXPECTED_BUNDLE_ID + ".");
  }
  if (config.catalogPath !== "data/pot-iap-catalog.json") {
    throw new ToolError("catalogPath must remain data/pot-iap-catalog.json.");
  }
  if (!/^[A-Z]{3}$/.test(String(config.baseTerritory || ""))) {
    throw new ToolError("baseTerritory must be a three-letter App Store territory code.");
  }
  const ja = config.localizations && config.localizations.ja;
  const en = config.localizations && config.localizations["en-US"];
  if (!ja || ja.locale !== "ja" || ja.description !== EXPECTED_JA_DESCRIPTION) {
    throw new ToolError("The Japanese IAP description differs from the approved text.");
  }
  if (!en || en.locale !== "en-US" || en.description !== EXPECTED_EN_DESCRIPTION) {
    throw new ToolError("The English IAP description differs from the approved text.");
  }
  if (codePointLength(ja.description) > 45 || codePointLength(en.description) > 45) {
    throw new ToolError("An IAP description exceeds Apple's 45-character limit.");
  }
  if (typeof config.reviewScreenshots !== "object" || Array.isArray(config.reviewScreenshots)) {
    throw new ToolError("reviewScreenshots must be a product-ID-to-file-path object.");
  }
  for (const [productId, screenshotPath] of Object.entries(config.reviewScreenshots)) {
    const match = /^pot_unlock_(\d{3})$/.exec(productId);
    const number = match ? Number(match[1]) : 0;
    if (!match || number < 1 || number > EXPECTED_PRODUCT_COUNT) {
      throw new ToolError("Unknown reviewScreenshots product ID: " + productId);
    }
    if (typeof screenshotPath !== "string" || screenshotPath.trim() === "") {
      throw new ToolError("Review screenshot path must be a non-empty string: " + productId);
    }
  }
  if (typeof config.priceSourceProductId !== "string" ||
      typeof config.availabilitySourceProductId !== "string") {
    throw new ToolError("Price and availability source product IDs must be strings.");
  }
  if (typeof config.desiredCustomerPrice !== "string") {
    throw new ToolError("desiredCustomerPrice must be a string.");
  }
  const desiredCustomerPrice = config.desiredCustomerPrice.trim();
  if (
    desiredCustomerPrice &&
    (!Number.isFinite(Number(desiredCustomerPrice)) || Number(desiredCustomerPrice) <= 0)
  ) {
    throw new ToolError("desiredCustomerPrice must be a positive number when set.");
  }
  if (typeof config.sellInAllTerritories !== "boolean" ||
      typeof config.availableInNewTerritories !== "boolean") {
    throw new ToolError(
      "sellInAllTerritories and availableInNewTerritories must be booleans.",
    );
  }
  for (const sourceId of [
    config.priceSourceProductId,
    config.availabilitySourceProductId,
  ]) {
    if (sourceId && !/^pot_unlock_(?:00[1-9]|0[12]\d|03[0-6])$/.test(sourceId)) {
      throw new ToolError("Invalid source product ID: " + sourceId);
    }
  }
  if (typeof config.allowEmptyAvailability !== "boolean") {
    throw new ToolError("allowEmptyAvailability must be a boolean.");
  }
  if (desiredCustomerPrice && config.priceSourceProductId) {
    throw new ToolError(
      "Choose either desiredCustomerPrice or priceSourceProductId, not both.",
    );
  }
  if (config.sellInAllTerritories && config.availabilitySourceProductId) {
    throw new ToolError(
      "Choose either sellInAllTerritories or availabilitySourceProductId, not both.",
    );
  }
  if (!config.sellInAllTerritories && config.availableInNewTerritories) {
    throw new ToolError(
      "availableInNewTerritories requires sellInAllTerritories.",
    );
  }
  if (config.sellInAllTerritories && config.allowEmptyAvailability) {
    throw new ToolError(
      "allowEmptyAvailability cannot be combined with sellInAllTerritories.",
    );
  }
  const hasPricePolicy = Boolean(desiredCustomerPrice || config.priceSourceProductId);
  const hasAvailabilityPolicy = Boolean(
    config.sellInAllTerritories || config.availabilitySourceProductId,
  );
  if (hasPricePolicy !== hasAvailabilityPolicy) {
    throw new ToolError(
      "Configure both the Apple price policy and availability policy, or leave both undecided.",
    );
  }
}

export function createJwt({
  keyId,
  issuerId,
  keyType,
  privateKey,
  nowSeconds = Math.floor(Date.now() / 1000),
}) {
  if (!keyId || !privateKey) {
    throw new ToolError("A key ID and private key are required for JWT creation.");
  }
  const header = {
    alg: "ES256",
    kid: keyId,
    typ: "JWT",
  };
  const payload = {
    aud: "appstoreconnect-v1",
    iat: nowSeconds - 5,
    exp: nowSeconds + 15 * 60,
  };
  if (keyType === "individual") {
    payload.sub = "user";
  } else {
    if (!issuerId) {
      throw new ToolError("ASC_ISSUER_ID is required for a team API key.");
    }
    payload.iss = issuerId;
  }
  const encodedHeader = base64url(JSON.stringify(header));
  const encodedPayload = base64url(JSON.stringify(payload));
  const signingInput = encodedHeader + "." + encodedPayload;
  const signer = createSign("SHA256");
  signer.update(signingInput);
  signer.end();
  const signature = signer.sign({
    key: privateKey,
    dsaEncoding: "ieee-p1363",
  });
  return signingInput + "." + signature.toString("base64url");
}

async function loadAuthentication() {
  let local = {};
  if (existsSync(LOCAL_AUTH_PATH)) {
    local = await readJsonFile(LOCAL_AUTH_PATH);
    if (!local || local.schemaVersion !== 1) {
      throw new ToolError("Unsupported local authentication config schema.");
    }
  }
  const setting = (environmentName, localName) =>
    String(process.env[environmentName] || local[localName] || "").trim();
  const keyId = setting("ASC_KEY_ID", "keyId");
  const issuerId = setting("ASC_ISSUER_ID", "issuerId");
  const privateKeyPathValue = setting("ASC_PRIVATE_KEY_PATH", "privateKeyPath");
  const configuredKeyType = setting("ASC_KEY_TYPE", "keyType").toLowerCase();
  const keyType = configuredKeyType || (issuerId ? "team" : "");
  if (!keyId || !privateKeyPathValue || !keyType) {
    throw new ToolError(
      "Authentication is incomplete. Create " +
      "tools/app_store_connect_iap.auth.local.json or set ASC_KEY_ID, " +
      "ASC_PRIVATE_KEY_PATH, ASC_KEY_TYPE, and ASC_ISSUER_ID for a team key.",
    );
  }
  if (!["team", "individual"].includes(keyType)) {
    throw new ToolError("ASC_KEY_TYPE must be team or individual.");
  }
  if (keyType === "team" && !issuerId) {
    throw new ToolError("ASC_ISSUER_ID is required for a team key.");
  }
  if (!path.isAbsolute(privateKeyPathValue)) {
    throw new ToolError(
      "ASC_PRIVATE_KEY_PATH/privateKeyPath must be an absolute path outside the repository.",
    );
  }
  const privateKeyPath = path.resolve(privateKeyPathValue);
  if (privateKeyPath === REPO_ROOT || isPathInside(REPO_ROOT, privateKeyPath)) {
    throw new ToolError(
      "Refusing to read an App Store Connect private key from inside the repository. " +
      "Move the .p8 file to a private directory outside " + REPO_ROOT + ".",
    );
  }
  let privateKey;
  try {
    privateKey = await readFile(privateKeyPath, "utf8");
  } catch (error) {
    throw new ToolError("Unable to read ASC_PRIVATE_KEY_PATH: " + error.message);
  }
  if (!privateKey.includes("PRIVATE KEY")) {
    throw new ToolError("ASC_PRIVATE_KEY_PATH does not contain a PEM private key.");
  }
  return {
    keyId,
    issuerId,
    keyType,
    privateKey,
    explicitAppId: setting("ASC_APP_ID", "appId"),
  };
}

function appleErrorDetails(parsed, fallbackText) {
  if (parsed && Array.isArray(parsed.errors) && parsed.errors.length > 0) {
    return parsed.errors.map((error) => {
      const pieces = [error.code, error.title, error.detail].filter(Boolean);
      return pieces.join(" - ");
    }).join("; ");
  }
  return String(fallbackText || "Unknown App Store Connect API error").slice(0, 2000);
}

class AppStoreConnectClient {
  constructor(authentication, fetchImplementation = globalThis.fetch) {
    this.authentication = authentication;
    this.fetchImplementation = fetchImplementation;
    this.cachedToken = "";
    this.cachedTokenExpiresAt = 0;
  }

  token() {
    const now = Math.floor(Date.now() / 1000);
    if (!this.cachedToken || this.cachedTokenExpiresAt < now + 60) {
      this.cachedToken = createJwt({
        keyId: this.authentication.keyId,
        issuerId: this.authentication.issuerId,
        keyType: this.authentication.keyType,
        privateKey: this.authentication.privateKey,
        nowSeconds: now,
      });
      this.cachedTokenExpiresAt = now + 15 * 60;
    }
    return this.cachedToken;
  }

  authenticatedUrl(pathOrUrl) {
    const url = new URL(pathOrUrl, API_ORIGIN);
    if (url.origin !== API_ORIGIN) {
      throw new ToolError("Refusing to send an API token to " + url.origin + ".");
    }
    return url;
  }

  async request(method, pathOrUrl, {
    body,
    allow404 = false,
    retryable = ["GET", "HEAD", "PUT", "PATCH"].includes(method),
  } = {}) {
    const url = this.authenticatedUrl(pathOrUrl);
    const maximumAttempts = retryable ? 5 : 1;
    let lastNetworkError;
    for (let attempt = 1; attempt <= maximumAttempts; attempt += 1) {
      let response;
      try {
        response = await this.fetchImplementation(url, {
          method,
          headers: {
            Accept: "application/json",
            Authorization: "Bearer " + this.token(),
            ...(body === undefined ? {} : { "Content-Type": "application/json" }),
          },
          body: body === undefined ? undefined : JSON.stringify(body),
        });
      } catch (error) {
        lastNetworkError = error;
        if (attempt < maximumAttempts) {
          await sleep(500 * (2 ** (attempt - 1)));
          continue;
        }
        throw new ToolError(method + " " + url.pathname + " network error: " + error.message);
      }
      const responseText = await response.text();
      let parsed = null;
      if (responseText) {
        try {
          parsed = JSON.parse(responseText);
        } catch {
          parsed = null;
        }
      }
      if (response.ok) {
        return parsed;
      }
      if (allow404 && response.status === 404) {
        return null;
      }
      const retryAfter = Number(response.headers.get("retry-after") || "0");
      if ((response.status === 429 || response.status >= 500) && attempt < maximumAttempts) {
        const delay = retryAfter > 0
          ? Math.min(retryAfter * 1000, 20000)
          : 500 * (2 ** (attempt - 1));
        await sleep(delay);
        continue;
      }
      throw new ApiError(
        method,
        url.pathname,
        response.status,
        appleErrorDetails(parsed, responseText),
      );
    }
    throw new ToolError(
      method + " request failed: " + (lastNetworkError ? lastNetworkError.message : "unknown error"),
    );
  }

  get(pathOrUrl, options) {
    return this.request("GET", pathOrUrl, options);
  }

  post(pathOrUrl, body) {
    return this.request("POST", pathOrUrl, { body, retryable: false });
  }

  patch(pathOrUrl, body) {
    return this.request("PATCH", pathOrUrl, { body, retryable: true });
  }

  async fetchAll(pathOrUrl) {
    const records = [];
    let next = pathOrUrl;
    while (next) {
      const response = await this.get(next);
      if (!response || !Array.isArray(response.data)) {
        throw new ToolError("Expected a paginated App Store Connect response.");
      }
      records.push(...response.data);
      next = response.links && response.links.next ? response.links.next : "";
    }
    return records;
  }

  async uploadOperation(operation, fileBuffer) {
    const offset = Number(operation.offset);
    const length = Number(operation.length);
    if (!Number.isSafeInteger(offset) || !Number.isSafeInteger(length) ||
        offset < 0 || length < 0 || offset + length > fileBuffer.length) {
      throw new ToolError("Apple returned an invalid screenshot upload byte range.");
    }
    const headers = {};
    for (const header of operation.requestHeaders || []) {
      headers[header.name] = header.value;
    }
    const body = fileBuffer.subarray(offset, offset + length);
    for (let attempt = 1; attempt <= 5; attempt += 1) {
      let response;
      try {
        response = await this.fetchImplementation(operation.url, {
          method: operation.method || "PUT",
          headers,
          body,
        });
      } catch (error) {
        if (attempt < 5) {
          await sleep(500 * (2 ** (attempt - 1)));
          continue;
        }
        throw new ToolError("Screenshot upload network error: " + error.message);
      }
      if (response.ok) {
        return;
      }
      const responseText = await response.text();
      if ((response.status === 429 || response.status >= 500) && attempt < 5) {
        await sleep(500 * (2 ** (attempt - 1)));
        continue;
      }
      throw new ToolError(
        "Screenshot upload failed (" + response.status + "): " +
        responseText.slice(0, 1000),
      );
    }
  }
}

function withQuery(pathname, entries) {
  const url = new URL(pathname, API_ORIGIN);
  for (const [key, value] of Object.entries(entries)) {
    if (value !== undefined && value !== null && value !== "") {
      url.searchParams.set(key, String(value));
    }
  }
  return url.pathname + url.search;
}

export function buildProductCreatePayload(appId, product) {
  return {
    data: {
      type: "inAppPurchases",
      attributes: {
        name: product.referenceName,
        productId: product.productId,
        inAppPurchaseType: IAP_TYPE,
        reviewNote: product.reviewNote,
      },
      relationships: {
        app: {
          data: {
            type: "apps",
            id: appId,
          },
        },
      },
    },
  };
}

export function buildProductUpdatePayload(remoteId, product) {
  return {
    data: {
      type: "inAppPurchases",
      id: remoteId,
      attributes: {
        name: product.referenceName,
        reviewNote: product.reviewNote,
      },
    },
  };
}

export function buildVersionCreatePayload(remoteId) {
  return {
    data: {
      type: "inAppPurchaseVersions",
      relationships: {
        inAppPurchase: {
          data: {
            type: "inAppPurchases",
            id: remoteId,
          },
        },
      },
    },
  };
}

export function buildLocalizationCreatePayload(versionId, locale, name, description) {
  return {
    data: {
      type: "inAppPurchaseLocalizations",
      attributes: {
        locale,
        name,
        description,
      },
      relationships: {
        version: {
          data: {
            type: "inAppPurchaseVersions",
            id: versionId,
          },
        },
      },
    },
  };
}

export function buildLocalizationUpdatePayload(localizationId, name, description) {
  return {
    data: {
      type: "inAppPurchaseLocalizations",
      id: localizationId,
      attributes: {
        name,
        description,
      },
    },
  };
}

export function buildPriceSchedulePayload(remoteId, pricePointId, territory) {
  // App Store Connect requires included resources created inline to use a
  // JSON:API local ID in the literal ${local-id} form.
  const inlinePriceId = "${initial-price}";
  return {
    data: {
      type: "inAppPurchasePriceSchedules",
      relationships: {
        inAppPurchase: {
          data: {
            type: "inAppPurchases",
            id: remoteId,
          },
        },
        manualPrices: {
          data: [{
            type: "inAppPurchasePrices",
            id: inlinePriceId,
          }],
        },
        baseTerritory: {
          data: {
            type: "territories",
            id: territory,
          },
        },
      },
    },
    included: [{
      type: "inAppPurchasePrices",
      id: inlinePriceId,
      attributes: {
        startDate: null,
      },
      relationships: {
        inAppPurchaseV2: {
          data: {
            type: "inAppPurchases",
            id: remoteId,
          },
        },
        inAppPurchasePricePoint: {
          data: {
            type: "inAppPurchasePricePoints",
            id: pricePointId,
          },
        },
      },
    }],
  };
}

export function buildAvailabilityPayload(
  remoteId,
  territoryIds,
  availableInNewTerritories,
) {
  return {
    data: {
      type: "inAppPurchaseAvailabilities",
      attributes: {
        availableInNewTerritories: Boolean(availableInNewTerritories),
      },
      relationships: {
        availableTerritories: {
          data: territoryIds.map((territoryId) => ({
            type: "territories",
            id: territoryId,
          })),
        },
        inAppPurchase: {
          data: {
            type: "inAppPurchases",
            id: remoteId,
          },
        },
      },
    },
  };
}

export function buildScreenshotReservationPayload(remoteId, fileName, fileSize) {
  return {
    data: {
      type: "inAppPurchaseAppStoreReviewScreenshots",
      attributes: {
        fileName,
        fileSize,
      },
      relationships: {
        inAppPurchaseV2: {
          data: {
            type: "inAppPurchases",
            id: remoteId,
          },
        },
      },
    },
  };
}

export function commandRequiresWrites(command) {
  return WRITE_COMMANDS.has(command);
}

export function assertRequiredExistingProducts(
  selectedProducts,
  remoteProducts,
  requireExisting,
) {
  if (!requireExisting) {
    return;
  }
  const missing = selectedProducts
    .map((product) => product.productId)
    .filter((productId) => !remoteProducts.has(productId));
  if (missing.length > 0) {
    throw new ToolError(
      "Existing-product-only write blocked because these products are not registered: " +
      missing.join(", ") + ".",
    );
  }
}

export function parseExcludedProductIds(value, knownProductIds) {
  const text = String(value || "").trim();
  if (!text) {
    return new Set();
  }
  const ids = text.split(",").map((item) => item.trim()).filter(Boolean);
  const unique = new Set(ids);
  if (unique.size !== ids.length) {
    throw new ToolError("Excluded product IDs must not contain duplicates.");
  }
  for (const productId of unique) {
    if (!knownProductIds.has(productId)) {
      throw new ToolError("Unknown excluded product ID: " + productId + ".");
    }
  }
  return unique;
}

export function assertRequiredMissingProducts(
  selectedProducts,
  remoteProducts,
  requireMissing,
) {
  if (!requireMissing) {
    return;
  }
  const existing = selectedProducts
    .map((product) => product.productId)
    .filter((productId) => remoteProducts.has(productId));
  if (existing.length > 0) {
    throw new ToolError(
      "New-product-only write blocked because these products already exist: " +
      existing.join(", ") + ".",
    );
  }
}

async function resolveApp(client, bundleId, explicitAppId) {
  if (explicitAppId) {
    const response = await client.get("/v1/apps/" + encodeURIComponent(explicitAppId));
    const remoteBundleId = response && response.data && response.data.attributes
      ? response.data.attributes.bundleId
      : "";
    if (remoteBundleId !== bundleId) {
      throw new ToolError(
        "ASC_APP_ID points to bundle " + String(remoteBundleId) +
        ", not " + bundleId + ".",
      );
    }
    return response.data;
  }
  const requestPath = withQuery("/v1/apps", {
    "filter[bundleId]": bundleId,
    limit: 2,
  });
  const response = await client.get(requestPath);
  const apps = response && Array.isArray(response.data) ? response.data : [];
  if (apps.length !== 1) {
    throw new ToolError(
      "Expected exactly one App Store Connect app for " + bundleId +
      ", found " + apps.length + ". Set ASC_APP_ID only after verifying it.",
    );
  }
  return apps[0];
}

async function listProducts(client, appId) {
  const requestPath = withQuery(
    "/v1/apps/" + encodeURIComponent(appId) + "/inAppPurchasesV2",
    { limit: 200 },
  );
  const products = await client.fetchAll(requestPath);
  const byProductId = new Map();
  for (const product of products) {
    const productId = product && product.attributes
      ? String(product.attributes.productId || "")
      : "";
    if (!productId) {
      continue;
    }
    if (byProductId.has(productId)) {
      throw new ToolError("App Store Connect returned duplicate product ID " + productId + ".");
    }
    byProductId.set(productId, product);
  }
  return byProductId;
}

function relationshipId(resource, relationshipName) {
  const relationship = resource && resource.relationships
    ? resource.relationships[relationshipName]
    : null;
  const data = relationship ? relationship.data : null;
  if (Array.isArray(data)) {
    return data.map((item) => item.id);
  }
  return data && data.id ? data.id : "";
}

function includedById(response) {
  const map = new Map();
  for (const item of (response && response.included) || []) {
    map.set(item.type + ":" + item.id, item);
  }
  return map;
}

function sortedVersions(versions) {
  return [...versions].sort((left, right) => {
    const leftVersion = Number(left.attributes && left.attributes.version || 0);
    const rightVersion = Number(right.attributes && right.attributes.version || 0);
    return rightVersion - leftVersion;
  });
}

function chooseMetadataVersion(versions) {
  const drafts = versions.filter(
    (version) => version.attributes && version.attributes.state === DRAFT_VERSION_STATE,
  );
  if (drafts.length > 1) {
    throw new ToolError("App Store Connect returned more than one editable IAP version.");
  }
  return drafts[0] || sortedVersions(versions)[0] || null;
}

async function readLocalizations(client, version) {
  if (!version) {
    return new Map();
  }
  const requestPath = withQuery(
    "/v1/inAppPurchaseVersions/" + encodeURIComponent(version.id) + "/localizations",
    { limit: 200 },
  );
  const records = await client.fetchAll(requestPath);
  const localizations = new Map();
  for (const record of records) {
    const locale = record && record.attributes
      ? String(record.attributes.locale || "")
      : "";
    if (locale) {
      localizations.set(locale, record);
    }
  }
  return localizations;
}

function activePriceRecord(records, today) {
  const active = records.filter((record) => {
    const attributes = record.attributes || {};
    const startDate = attributes.startDate;
    const endDate = attributes.endDate;
    return (!startDate || startDate <= today) && (!endDate || endDate >= today);
  });
  active.sort((left, right) => {
    const leftStart = String(left.attributes && left.attributes.startDate || "");
    const rightStart = String(right.attributes && right.attributes.startDate || "");
    return rightStart.localeCompare(leftStart);
  });
  return active[0] || null;
}

async function readPriceRecords(client, scheduleId, relationship, territory) {
  const requestPath = withQuery(
    "/v1/inAppPurchasePriceSchedules/" + encodeURIComponent(scheduleId) +
    "/" + relationship,
    {
      "filter[territory]": territory,
      "fields[inAppPurchasePrices]":
        "startDate,endDate,manual,inAppPurchasePricePoint,territory",
      "fields[inAppPurchasePricePoints]": "customerPrice",
      include: "inAppPurchasePricePoint,territory",
      limit: 200,
    },
  );
  const response = await client.get(requestPath);
  return {
    records: response && Array.isArray(response.data) ? response.data : [],
    included: includedById(response),
  };
}

async function readScheduledPriceTerritoryIds(client, scheduleId, relationship) {
  const requestPath = withQuery(
    "/v1/inAppPurchasePriceSchedules/" + encodeURIComponent(scheduleId) +
    "/" + relationship,
    {
      "fields[inAppPurchasePrices]": "manual,territory",
      "fields[territories]": "currency",
      include: "territory",
      limit: 200,
    },
  );
  const records = await client.fetchAll(requestPath);
  return [...new Set(
    records.map((record) => relationshipId(record, "territory")).filter(Boolean),
  )].sort();
}

async function listPricePoints(client, remoteId, territory) {
  const requestPath = withQuery(
    "/v2/inAppPurchases/" + encodeURIComponent(remoteId) + "/pricePoints",
    {
      "filter[territory]": territory,
      limit: 8000,
    },
  );
  return client.fetchAll(requestPath);
}

export function summarizePriceOptions(pricePoints, requestedPrice) {
  const requested = Number(requestedPrice);
  if (!Number.isFinite(requested) || requested < 0) {
    throw new ToolError("Requested price must be a non-negative number.");
  }
  const numeric = pricePoints.map((point) => ({
    point,
    price: Number(point && point.attributes && point.attributes.customerPrice),
  })).filter((entry) => Number.isFinite(entry.price));
  const exact = numeric.filter((entry) => entry.price === requested);
  const distinctPrices = [...new Set(numeric.map((entry) => entry.price))]
    .sort((left, right) => left - right);
  const lower = [...distinctPrices].reverse().find((price) => price < requested);
  const higher = distinctPrices.find((price) => price > requested);
  return {
    requested,
    exact,
    lower: lower === undefined ? null : lower,
    higher: higher === undefined ? null : higher,
    distinctPriceCount: distinctPrices.length,
  };
}

async function readCurrentPrice(client, remoteId, territory, knownScheduleId = "") {
  let scheduleId = knownScheduleId;
  if (!scheduleId) {
    const relationshipResponse = await client.get(
      "/v2/inAppPurchases/" + encodeURIComponent(remoteId) +
      "/relationships/iapPriceSchedule",
      { allow404: true },
    );
    scheduleId = relationshipResponse && relationshipResponse.data
      ? String(relationshipResponse.data.id || "")
      : "";
  }
  if (!scheduleId) {
    return null;
  }
  const today = new Date().toISOString().slice(0, 10);
  const manual = await readPriceRecords(client, scheduleId, "manualPrices", territory);
  const automatic = await readPriceRecords(client, scheduleId, "automaticPrices", territory);
  const manualActive = activePriceRecord(manual.records, today);
  const automaticActive = activePriceRecord(automatic.records, today);
  const selected = manualActive || automaticActive;
  if (!selected) {
    return {
      scheduleId,
      territory,
      customerPrice: "",
      pricePointId: "",
    };
  }
  const pricePointId = relationshipId(selected, "inAppPurchasePricePoint");
  const combinedIncluded = new Map([...manual.included, ...automatic.included]);
  let point = combinedIncluded.get("inAppPurchasePricePoints:" + pricePointId);
  if (!point || !point.attributes || point.attributes.customerPrice === undefined) {
    const points = await listPricePoints(client, remoteId, territory);
    point = points.find((candidate) => candidate.id === pricePointId);
  }
  const customerPrice = point && point.attributes
    ? String(point.attributes.customerPrice ?? "")
    : "";
  return {
    scheduleId,
    territory,
    customerPrice,
    pricePointId,
  };
}

async function readAvailability(client, remoteId, knownAvailability = null) {
  let availability = knownAvailability;
  if (!availability) {
    const response = await client.get(
      "/v2/inAppPurchases/" + encodeURIComponent(remoteId) +
      "/inAppPurchaseAvailability",
      { allow404: true },
    );
    availability = response ? response.data : null;
  }
  if (!availability) {
    return null;
  }
  const requestPath = withQuery(
    "/v1/inAppPurchaseAvailabilities/" + encodeURIComponent(availability.id) +
    "/relationships/availableTerritories",
    { limit: 200 },
  );
  const territoryRecords = await client.fetchAll(requestPath);
  const territoryIds = territoryRecords.map((item) => item.id).sort();
  return {
    id: availability.id,
    availableInNewTerritories: Boolean(
      availability.attributes && availability.attributes.availableInNewTerritories,
    ),
    territoryIds,
  };
}

async function inspectRemoteProduct(client, remote, territory) {
  const requestPath = withQuery(
    "/v2/inAppPurchases/" + encodeURIComponent(remote.id),
    {
      include:
        "versions,appStoreReviewScreenshot,iapPriceSchedule",
      "limit[versions]": 50,
    },
  );
  const response = await client.get(requestPath);
  const resource = response.data;
  const included = includedById(response);

  const versionIds = relationshipId(resource, "versions") || [];
  const versions = versionIds.map(
    (id) => included.get("inAppPurchaseVersions:" + id),
  ).filter(Boolean);
  const metadataVersion = chooseMetadataVersion(versions);
  const localizations = await readLocalizations(client, metadataVersion);

  const screenshotId = relationshipId(resource, "appStoreReviewScreenshot");
  const screenshot = screenshotId
    ? included.get("inAppPurchaseAppStoreReviewScreenshots:" + screenshotId) || null
    : null;
  const screenshotState = screenshot && screenshot.attributes &&
    screenshot.attributes.assetDeliveryState
    ? String(screenshot.attributes.assetDeliveryState.state || "")
    : "";

  const scheduleId = relationshipId(resource, "iapPriceSchedule");
  const price = await readCurrentPrice(client, remote.id, territory, scheduleId);

  // Apple may return a 404 for the entire product request when an unset
  // availability relationship is requested through `include`. Read the
  // relationship separately so a missing availability remains a normal,
  // read-only "not configured" result.
  const availability = await readAvailability(client, remote.id);

  return {
    resource,
    versions,
    metadataVersion,
    localizations,
    screenshot,
    screenshotState,
    price,
    availability,
  };
}

function localizationMatches(localization, name, description) {
  return Boolean(
    localization &&
    localization.attributes &&
    localization.attributes.name === name &&
    localization.attributes.description === description
  );
}

function sameAvailability(left, right) {
  if (!left || !right) {
    return left === right;
  }
  return (
    left.availableInNewTerritories === right.availableInNewTerritories &&
    left.territoryIds.join(",") === right.territoryIds.join(",")
  );
}

function desiredLocalizationEntries(config, product) {
  return [
    {
      locale: config.localizations.ja.locale,
      name: product.displayNameJa,
      description: config.localizations.ja.description,
    },
    {
      locale: config.localizations["en-US"].locale,
      name: product.displayNameEn,
      description: config.localizations["en-US"].description,
    },
  ];
}

function planAction(product, inspection, priceSource, availabilitySource) {
  if (!inspection) {
    return "CREATE";
  }
  const attributes = inspection.resource.attributes || {};
  if (attributes.inAppPurchaseType !== IAP_TYPE) {
    return "BLOCKED_TYPE";
  }
  const metadataMatches =
    attributes.name === product.referenceName &&
    attributes.reviewNote === product.reviewNote;
  const localizationsMatch =
    localizationMatches(
      inspection.localizations.get("ja"),
      product.displayNameJa,
      EXPECTED_JA_DESCRIPTION,
    ) &&
    localizationMatches(
      inspection.localizations.get("en-US"),
      product.displayNameEn,
      EXPECTED_EN_DESCRIPTION,
    );
  const priceMatches = !priceSource || (
    inspection.price &&
    normalizedDecimal(inspection.price.customerPrice) ===
      normalizedDecimal(priceSource.customerPrice)
  );
  const availabilityMatches =
    !availabilitySource || sameAvailability(inspection.availability, availabilitySource);
  const screenshotMatches = inspection.screenshotState === COMPLETE_ASSET_STATE;
  return metadataMatches && localizationsMatch && priceMatches &&
    availabilityMatches && screenshotMatches
    ? "NO_CHANGE"
    : "RECONCILE";
}

export function inspectionGaps(product, inspection) {
  if (!inspection) {
    return ["product is not registered"];
  }
  const gaps = [];
  const attributes = inspection.resource.attributes || {};
  if (attributes.inAppPurchaseType !== IAP_TYPE) {
    gaps.push("type is not NON_CONSUMABLE");
  }
  if (attributes.name !== product.referenceName) {
    gaps.push("reference name");
  }
  if (attributes.reviewNote !== product.reviewNote) {
    gaps.push("review note");
  }
  if (!inspection.metadataVersion) {
    gaps.push("IAP metadata version");
  }
  if (!localizationMatches(
    inspection.localizations.get("ja"),
    product.displayNameJa,
    EXPECTED_JA_DESCRIPTION,
  )) {
    gaps.push("Japanese localization");
  }
  if (!localizationMatches(
    inspection.localizations.get("en-US"),
    product.displayNameEn,
    EXPECTED_EN_DESCRIPTION,
  )) {
    gaps.push("English localization");
  }
  if (!inspection.price || !inspection.price.customerPrice) {
    gaps.push("JPN price");
  }
  if (!inspection.availability) {
    gaps.push("sale territories");
  }
  if (inspection.screenshotState !== COMPLETE_ASSET_STATE) {
    gaps.push("review screenshot");
  }
  return gaps;
}

function printOfflinePlan(inputs) {
  console.log("App Store Connect IAP registration plan (LOCAL ONLY / NO API)");
  console.log("Config: " + path.relative(REPO_ROOT, inputs.configPath));
  console.log("Bundle ID: " + inputs.config.bundleId);
  console.log("Product type: " + IAP_TYPE);
  const desiredCustomerPrice = inputs.config.desiredCustomerPrice.trim();
  console.log(
    "Apple price: " + (desiredCustomerPrice
      ? inputs.config.baseTerritory + " customer price " + desiredCustomerPrice +
        " (must be revalidated through the API)"
      : "UNDECIDED"),
  );
  console.log(
    "Availability: " + (inputs.config.sellInAllTerritories
      ? "all current App Store territories; automatic future territories " +
        (inputs.config.availableInNewTerritories ? "ON" : "OFF")
      : "UNDECIDED"),
  );
  console.log("Review submission/publication: NOT IMPLEMENTED");
  console.log("");
  console.log("No.  Product ID       Japanese name                  English name                    Game price");
  for (const product of inputs.products) {
    console.log(
      String(product.number).padStart(2, "0") + "   " +
      product.productId.padEnd(17) + " " +
      product.displayNameJa.padEnd(18) + " " +
      product.displayNameEn.padEnd(31) + " " +
      String(product.inGamePukuPrice).padStart(3) + " Puku",
    );
  }
  const configuredScreenshotCount = Object.values(inputs.screenshotPaths)
    .filter(Boolean).length;
  console.log("");
  console.log("Validated local products: " + inputs.products.length + "/36");
  console.log(
    "Game prices: validated only; never sent to App Store Connect and never modified.",
  );
  console.log("Configured real review screenshots: " + configuredScreenshotCount + "/36");
  console.log("API writes performed: 0");
}

async function inspectAllCatalogProducts(client, remoteProducts, inputs) {
  const inspections = new Map();
  for (const product of inputs.products) {
    const remote = remoteProducts.get(product.productId);
    if (!remote) {
      continue;
    }
    inspections.set(
      product.productId,
      await inspectRemoteProduct(client, remote, inputs.config.baseTerritory),
    );
  }
  return inspections;
}

function sourceCandidate(inputs, remoteProducts) {
  const matches = inputs.products.filter((product) => remoteProducts.has(product.productId));
  return matches.length === 1 ? matches[0].productId : "";
}

function printAuthenticatedPlan({
  app,
  inputs,
  remoteProducts,
  inspections,
  priceSource,
  availabilitySource,
}) {
  console.log("App Store Connect IAP authenticated Dry Run (READ ONLY)");
  console.log(
    "App: " + String(app.attributes && app.attributes.name || "") +
    " / " + app.id + " / " + inputs.config.bundleId,
  );
  console.log("Remote catalog matches: " + inspections.size + "/36");
  console.log("");
  console.log(
    "Product ID        Action         Type             JPY price  Territories   Screenshot  State",
  );
  for (const product of inputs.products) {
    const inspection = inspections.get(product.productId);
    const action = planAction(product, inspection, priceSource, availabilitySource);
    const attributes = inspection ? inspection.resource.attributes || {} : {};
    const price = inspection && inspection.price && inspection.price.customerPrice
      ? "JPY " + inspection.price.customerPrice
      : "-";
    const regions = inspection && inspection.availability
      ? String(inspection.availability.territoryIds.length) +
        (inspection.availability.availableInNewTerritories ? "+new" : " fixed")
      : "-";
    const screenshot = inspection && inspection.screenshotState
      ? inspection.screenshotState
      : "-";
    console.log(
      product.productId.padEnd(17) + " " +
      action.padEnd(14) + " " +
      String(attributes.inAppPurchaseType || "-").padEnd(16) + " " +
      price.padEnd(10) + " " +
      regions.padEnd(13) + " " +
      screenshot.padEnd(11) + " " +
      String(attributes.state || "-"),
    );
  }
  const existingProducts = inputs.products.filter(
    (product) => inspections.has(product.productId),
  );
  if (existingProducts.length > 0) {
    console.log("");
    console.log("Existing catalog product gaps:");
    for (const product of existingProducts) {
      const gaps = inspectionGaps(product, inspections.get(product.productId));
      console.log(
        product.productId + ": " + (gaps.length > 0 ? gaps.join(", ") : "none"),
      );
    }
  }
  console.log("");
  console.log("API writes performed: 0");
}

async function imageInfo(filePath) {
  try {
    await access(filePath);
  } catch {
    throw new ToolError("Review screenshot not found: " + filePath);
  }
  const fileStat = await stat(filePath);
  if (!fileStat.isFile() || fileStat.size <= 0) {
    throw new ToolError("Review screenshot is not a non-empty file: " + filePath);
  }
  const buffer = await readFile(filePath);
  let format = "";
  let width = 0;
  let height = 0;
  if (
    buffer.length >= 24 &&
    buffer.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))
  ) {
    format = "PNG";
    width = buffer.readUInt32BE(16);
    height = buffer.readUInt32BE(20);
  } else if (buffer.length >= 4 && buffer[0] === 0xff && buffer[1] === 0xd8) {
    format = "JPEG";
    const dimensions = jpegDimensions(buffer);
    width = dimensions.width;
    height = dimensions.height;
  } else {
    throw new ToolError("Review screenshot must be a real PNG or JPEG file: " + filePath);
  }
  if (!width || !height) {
    throw new ToolError("Unable to read review screenshot dimensions: " + filePath);
  }
  return {
    buffer,
    fileName: path.basename(filePath),
    fileSize: fileStat.size,
    format,
    width,
    height,
    md5: createHash("md5").update(buffer).digest("hex"),
  };
}

function jpegDimensions(buffer) {
  let offset = 2;
  while (offset + 9 < buffer.length) {
    if (buffer[offset] !== 0xff) {
      offset += 1;
      continue;
    }
    const marker = buffer[offset + 1];
    offset += 2;
    if (marker === 0xd8 || marker === 0xd9) {
      continue;
    }
    if (offset + 2 > buffer.length) {
      break;
    }
    const segmentLength = buffer.readUInt16BE(offset);
    if (segmentLength < 2 || offset + segmentLength > buffer.length) {
      break;
    }
    const isStartOfFrame =
      marker >= 0xc0 && marker <= 0xcf &&
      ![0xc4, 0xc8, 0xcc].includes(marker);
    if (isStartOfFrame && segmentLength >= 7) {
      return {
        height: buffer.readUInt16BE(offset + 3),
        width: buffer.readUInt16BE(offset + 5),
      };
    }
    offset += segmentLength;
  }
  return { width: 0, height: 0 };
}

async function resolveConfiguredPolicies(client, inputs, remoteProducts, inspections) {
  const desiredCustomerPrice = inputs.config.desiredCustomerPrice.trim();
  const priceSourceProductId = inputs.config.priceSourceProductId.trim();
  const availabilitySourceProductId = inputs.config.availabilitySourceProductId.trim();
  const useAllTerritories = inputs.config.sellInAllTerritories;
  if ((!desiredCustomerPrice && !priceSourceProductId) ||
      (!useAllTerritories && !availabilitySourceProductId)) {
    throw new ToolError(
      "Set an explicit Apple customer price and availability policy only after reviewing " +
      "the authenticated research. No Apple price or territory policy is guessed.",
    );
  }
  const knownIds = new Set(inputs.products.map((product) => product.productId));
  for (const sourceId of [priceSourceProductId, availabilitySourceProductId]) {
    if (!sourceId) {
      continue;
    }
    if (!knownIds.has(sourceId)) {
      throw new ToolError("Configured source is not one of the 36 catalog products: " + sourceId);
    }
    if (!remoteProducts.has(sourceId)) {
      throw new ToolError("Configured source product is not registered: " + sourceId);
    }
  }

  let priceSource;
  if (desiredCustomerPrice) {
    const referenceProduct = inputs.products.find(
      (product) => remoteProducts.has(product.productId),
    );
    if (!referenceProduct) {
      throw new ToolError(
        "At least one registered catalog product is required to verify the explicit price.",
      );
    }
    const referenceRemote = remoteProducts.get(referenceProduct.productId);
    const referencePoints = await listPricePoints(
      client,
      referenceRemote.id,
      inputs.config.baseTerritory,
    );
    const priceSummary = summarizePriceOptions(referencePoints, desiredCustomerPrice);
    if (priceSummary.exact.length !== 1) {
      throw new ToolError(
        "The requested " + inputs.config.baseTerritory + " customer price " +
        desiredCustomerPrice + " did not resolve to exactly one selectable price point. " +
        "Nearest lower: " + (priceSummary.lower === null ? "none" : priceSummary.lower) +
        "; nearest higher: " +
        (priceSummary.higher === null ? "none" : priceSummary.higher) + ".",
      );
    }
    const verifiedPoint = priceSummary.exact[0].point;
    priceSource = {
      territory: inputs.config.baseTerritory,
      customerPrice: String(verifiedPoint.attributes.customerPrice),
      pricePointId: verifiedPoint.id,
      priceTier: String(verifiedPoint.attributes.priceTier || ""),
      productId: "explicit policy verified via " + referenceProduct.productId,
    };
  } else {
    const priceInspection = inspections.get(priceSourceProductId) ||
      await inspectRemoteProduct(
        client,
        remoteProducts.get(priceSourceProductId),
        inputs.config.baseTerritory,
      );
    if (!priceInspection.price || !priceInspection.price.customerPrice) {
      throw new ToolError(
        "The price source has no current " + inputs.config.baseTerritory +
        " customer price: " + priceSourceProductId,
      );
    }
    const sourcePoints = await listPricePoints(
      client,
      priceInspection.resource.id,
      inputs.config.baseTerritory,
    );
    const sourcePoint = sourcePoints.find(
      (point) => point.id === priceInspection.price.pricePointId,
    );
    priceSource = {
      ...priceInspection.price,
      productId: priceSourceProductId,
      priceTier: sourcePoint && sourcePoint.attributes
        ? String(sourcePoint.attributes.priceTier || "")
        : "",
    };
  }

  let availabilitySource;
  if (useAllTerritories) {
    const territories = await client.fetchAll(
      withQuery("/v1/territories", { limit: 200 }),
    );
    const territoryIds = territories.map((territory) => String(territory.id || ""))
      .filter(Boolean)
      .sort();
    if (territoryIds.length === 0 || !territoryIds.includes(inputs.config.baseTerritory)) {
      throw new ToolError(
        "The current App Store territory list is empty or does not include " +
        inputs.config.baseTerritory + ".",
      );
    }
    availabilitySource = {
      territoryIds,
      availableInNewTerritories: inputs.config.availableInNewTerritories,
      productId: "all current App Store territories",
    };
  } else {
    const availabilityInspection = inspections.get(availabilitySourceProductId) ||
      await inspectRemoteProduct(
        client,
        remoteProducts.get(availabilitySourceProductId),
        inputs.config.baseTerritory,
      );
    availabilitySource = availabilityInspection.availability;
    if (!availabilitySource) {
      throw new ToolError(
        "The availability source has no territory configuration: " +
        availabilitySourceProductId,
      );
    }
    if (
      availabilitySource.territoryIds.length === 0 &&
      !inputs.config.allowEmptyAvailability
    ) {
      throw new ToolError(
        "The availability source is removed from sale (zero territories). " +
        "Set allowEmptyAvailability only after explicitly choosing that policy.",
      );
    }
    availabilitySource = {
      ...availabilitySource,
      productId: availabilitySourceProductId,
    };
  }
  return {
    priceSource,
    availabilitySource,
  };
}

async function runAuthenticatedDryRun(inputs) {
  const authentication = await loadAuthentication();
  const client = new AppStoreConnectClient(authentication);
  const app = await resolveApp(
    client,
    inputs.config.bundleId,
    authentication.explicitAppId,
  );
  const remoteProducts = await listProducts(client, app.id);
  const inspections = await inspectAllCatalogProducts(client, remoteProducts, inputs);

  let priceSource = null;
  let availabilitySource = null;
  const configuredPricePolicy = Boolean(
    inputs.config.desiredCustomerPrice.trim() || inputs.config.priceSourceProductId.trim(),
  );
  const configuredAvailabilityPolicy = Boolean(
    inputs.config.sellInAllTerritories || inputs.config.availabilitySourceProductId.trim(),
  );
  if (configuredPricePolicy && configuredAvailabilityPolicy) {
    const resolved = await resolveConfiguredPolicies(
      client,
      inputs,
      remoteProducts,
      inspections,
    );
    priceSource = resolved.priceSource;
    availabilitySource = resolved.availabilitySource;
  }
  printAuthenticatedPlan({
    app,
    inputs,
    remoteProducts,
    inspections,
    priceSource,
    availabilitySource,
  });

  const candidate = sourceCandidate(inputs, remoteProducts);
  if (!configuredPricePolicy || !configuredAvailabilityPolicy) {
    console.log("");
    if (candidate) {
      const candidateInspection = inspections.get(candidate);
      const candidatePrice = candidateInspection && candidateInspection.price &&
        candidateInspection.price.customerPrice
        ? "JPY " + candidateInspection.price.customerPrice
        : "not configured";
      const candidateRegions = candidateInspection && candidateInspection.availability
        ? candidateInspection.availability.territoryIds.length
        : 0;
      console.log("Existing product candidate (not selected automatically): " + candidate);
      console.log("Observed candidate price: " + candidatePrice);
      console.log("Observed candidate sale territories: " + candidateRegions);
      if (candidateInspection && candidateInspection.availability) {
        console.log(
          "Observed automatic new-territory availability: " +
          (candidateInspection.availability.availableInNewTerritories ? "ON" : "OFF"),
        );
      }
      console.log(
        "After policy approval, configure either explicit policy fields or verified " +
        "source product IDs in the local config.",
      );
    } else {
      console.log(
        "No unique existing source candidate was found. Choose the price and " +
        "availability source explicitly after reviewing App Store Connect.",
      );
    }
  } else {
    console.log("");
    console.log(
      "Configured Apple price policy: JPY " + priceSource.customerPrice +
      " (" + priceSource.productId + "); target-specific price points will be used.",
    );
    console.log(
      "Configured availability policy: " +
      availabilitySource.territoryIds.length + " territories (" +
      availabilitySource.productId + "); automatic new territories " +
      (availabilitySource.availableInNewTerritories ? "ON" : "OFF") + ".",
    );
  }

  const missingScreenshots = inputs.products.filter((product) => {
    const inspection = inspections.get(product.productId);
    return (
      (!inspection || inspection.screenshotState !== COMPLETE_ASSET_STATE) &&
      !inputs.screenshotPaths[product.productId]
    );
  });
  console.log(
    "Products still needing a mapped real review screenshot: " +
    missingScreenshots.length,
  );
  console.log(
    "No review submission or public release endpoint is available in this tool.",
  );
  return {
    client,
    app,
    remoteProducts,
    inspections,
  };
}

async function runPolicyResearch(inputs, options) {
  const authentication = await loadAuthentication();
  const client = new AppStoreConnectClient(authentication);
  const app = await resolveApp(
    client,
    inputs.config.bundleId,
    authentication.explicitAppId,
  );
  const remoteProducts = await listProducts(client, app.id);
  const requestedProductId = String(options["product-id"] || "").trim() ||
    sourceCandidate(inputs, remoteProducts);
  if (!requestedProductId || !remoteProducts.has(requestedProductId)) {
    throw new ToolError(
      "Choose an existing catalog product with --product-id before researching price points.",
    );
  }
  const remote = remoteProducts.get(requestedProductId);
  const requestedAmount = String(options.amount || "100").trim();
  const territory = inputs.config.baseTerritory;
  const pricePoints = await listPricePoints(client, remote.id, territory);
  const summary = summarizePriceOptions(pricePoints, requestedAmount);
  const territories = await client.fetchAll(
    withQuery("/v1/territories", { limit: 200 }),
  );

  console.log("App Store Connect IAP policy research (READ ONLY)");
  console.log("App: " + app.id + " / " + inputs.config.bundleId);
  console.log("Reference product: " + requestedProductId);
  console.log("Base territory: " + territory);
  console.log("Requested customer price: JPY " + summary.requested);
  console.log("Selectable price points returned: " + pricePoints.length);
  console.log("Distinct customer prices returned: " + summary.distinctPriceCount);
  console.log("Exact JPY price-point matches: " + summary.exact.length);
  console.log(
    "Nearest lower selectable price: " +
    (summary.lower === null ? "none" : "JPY " + summary.lower),
  );
  console.log(
    "Nearest higher selectable price: " +
    (summary.higher === null ? "none" : "JPY " + summary.higher),
  );
  console.log("Current App Store territories returned: " + territories.length);

  if (summary.exact.length === 1) {
    const point = summary.exact[0].point;
    const equalizationPath = withQuery(
      "/v1/inAppPurchasePricePoints/" + encodeURIComponent(point.id) +
      "/equalizations",
      {
        "fields[inAppPurchasePricePoints]": "customerPrice,territory",
        "fields[territories]": "currency",
        include: "territory",
        limit: 8000,
      },
    );
    const equalizationResponse = await client.get(equalizationPath);
    const equalizations = equalizationResponse && Array.isArray(equalizationResponse.data)
      ? equalizationResponse.data
      : [];
    const equalizedTerritories = new Set(
      equalizations.map((candidate) => relationshipId(candidate, "territory"))
        .filter(Boolean),
    );
    console.log("Apple equalized overseas price points returned: " + equalizations.length);
    console.log("Equalized overseas territories returned: " + equalizedTerritories.size);
  } else {
    console.log(
      "Equalization lookup skipped because the requested price did not resolve to exactly one point.",
    );
  }
  console.log("API writes performed: 0");
}

async function runCatalogVerification(inputs, options) {
  const authentication = await loadAuthentication();
  const client = new AppStoreConnectClient(authentication);
  const app = await resolveApp(
    client,
    inputs.config.bundleId,
    authentication.explicitAppId,
  );
  if (app.id !== "6807694389") {
    throw new ToolError(
      "Catalog verification expected App ID 6807694389, received " + app.id + ".",
    );
  }
  const remoteProducts = await listProducts(client, app.id);
  const inspections = await inspectAllCatalogProducts(client, remoteProducts, inputs);
  const territories = await client.fetchAll(
    withQuery("/v1/territories", { limit: 200 }),
  );
  const allTerritoryIds = territories.map((territory) => String(territory.id || ""))
    .filter(Boolean)
    .sort();
  const expectedAutomaticTerritories = allTerritoryIds.filter(
    (territoryId) => territoryId !== inputs.config.baseTerritory,
  );
  const expectedAvailability = {
    territoryIds: allTerritoryIds,
    availableInNewTerritories: true,
  };
  const requestedProductId = String(options["product-id"] || "").trim();
  const productsToVerify = requestedProductId
    ? inputs.products.filter((product) => product.productId === requestedProductId)
    : inputs.products;
  if (productsToVerify.length === 0) {
    throw new ToolError("Unknown verification product ID: " + requestedProductId + ".");
  }
  const failures = [];

  console.log("App Store Connect IAP full catalog verification (READ ONLY)");
  console.log("App: " + app.id + " / " + inputs.config.bundleId);
  console.log("Expected products: " + productsToVerify.length);
  console.log("Current territories: " + allTerritoryIds.length);
  console.log("");
  console.log("Product ID        Result  Type             JPN price  Manual  Automatic  Availability");

  for (const product of productsToVerify) {
    const inspection = inspections.get(product.productId);
    const problems = [];
    if (!inspection) {
      problems.push("product missing");
    } else {
      problems.push(...inspectionGaps(product, inspection).filter(
        (gap) => gap !== "review screenshot",
      ));
      const attributes = inspection.resource.attributes || {};
      if (attributes.inAppPurchaseType !== IAP_TYPE) {
        problems.push("unexpected type");
      }
      if (!inspection.price ||
          normalizedDecimal(inspection.price.customerPrice) !== "100") {
        problems.push("JPN price is not 100");
      }
      if (!sameAvailability(inspection.availability, expectedAvailability)) {
        problems.push("availability differs from all current + future territories");
      }
    }

    let manualTerritoryIds = [];
    let automaticTerritoryIds = [];
    const scheduleId = inspection && inspection.price
      ? String(inspection.price.scheduleId || "")
      : "";
    if (scheduleId) {
      manualTerritoryIds = await readScheduledPriceTerritoryIds(
        client,
        scheduleId,
        "manualPrices",
      );
      automaticTerritoryIds = await readScheduledPriceTerritoryIds(
        client,
        scheduleId,
        "automaticPrices",
      );
      if (manualTerritoryIds.join(",") !== inputs.config.baseTerritory) {
        problems.push("manual prices are not limited to JPN");
      }
      if (automaticTerritoryIds.join(",") !== expectedAutomaticTerritories.join(",")) {
        problems.push("automatic overseas territory set differs");
      }
    } else {
      problems.push("price schedule missing");
    }

    if (problems.length > 0) {
      failures.push(product.productId + ": " + problems.join(", "));
    }
    console.log(
      product.productId.padEnd(17) + " " +
      (problems.length === 0 ? "OK" : "FAIL").padEnd(7) + " " +
      String(inspection && inspection.resource.attributes &&
        inspection.resource.attributes.inAppPurchaseType || "-").padEnd(16) + " " +
      (inspection && inspection.price && inspection.price.customerPrice
        ? ("JPY " + inspection.price.customerPrice)
        : "-").padEnd(10) + " " +
      String(manualTerritoryIds.length).padEnd(7) + " " +
      String(automaticTerritoryIds.length).padEnd(10) + " " +
      (inspection && inspection.availability
        ? String(inspection.availability.territoryIds.length) +
          (inspection.availability.availableInNewTerritories ? "+new" : " fixed")
        : "-"),
    );
  }

  console.log("");
  console.log("Review screenshots expected later: " + productsToVerify.length);
  console.log("API writes performed: 0");
  if (failures.length > 0) {
    throw new ToolError(
      "Catalog verification failed:\n" + failures.join("\n"),
    );
  }
  console.log(
    "Verified products: " + productsToVerify.length + "/" + productsToVerify.length,
  );
}

function confirmWriteCommand(command, options, selectedProductId = "") {
  const supplied = String(options.confirm || "");
  if (command === "stage-one") {
    const expected = "STAGE_WITHOUT_SCREENSHOT:" + selectedProductId;
    if (supplied !== expected) {
      throw new ToolError(
        "Staging write blocked. Re-run with --confirm " + expected +
        " only after explicit approval.",
      );
    }
  } else if (command === "stage-all") {
    const expected = "STAGE_ALL_WITHOUT_SCREENSHOTS";
    if (supplied !== expected) {
      throw new ToolError(
        "Batch staging blocked. Re-run with --confirm " + expected +
        " only after the one-product pilot succeeds and explicit approval is given.",
      );
    }
  } else if (command === "apply-one") {
    const expected = "CREATE_OR_RECONCILE:" + selectedProductId;
    if (supplied !== expected) {
      throw new ToolError(
        "Write blocked. Re-run with --confirm " + expected +
        " only after explicit approval.",
      );
    }
  } else if (command === "apply-all") {
    const expected = "RECONCILE_ALL_36_IAPS";
    if (supplied !== expected) {
      throw new ToolError(
        "Batch write blocked. Re-run with --confirm " + expected +
        " only after the one-product pilot succeeds and explicit approval is given.",
      );
    }
  }
}

async function prepareWrite({
  command,
  options,
  inputs,
  client,
  app,
  remoteProducts,
  inspections,
}) {
  const isSingleProduct = command === "stage-one" || command === "apply-one";
  const includeScreenshots = command === "apply-one" || command === "apply-all";
  let selectedProducts;
  if (isSingleProduct) {
    const productId = String(options["product-id"] || "");
    const product = inputs.products.find((candidate) => candidate.productId === productId);
    if (!product) {
      throw new ToolError("--product-id must be one of pot_unlock_001 through pot_unlock_036.");
    }
    confirmWriteCommand(command, options, productId);
    selectedProducts = [product];
  } else {
    confirmWriteCommand(command, options);
    if (inspections.size < 2) {
      throw new ToolError(
        "Batch registration is blocked until App Store Connect contains the original " +
        "product plus one successfully verified pilot product.",
      );
    }
    const knownProductIds = new Set(
      inputs.products.map((product) => product.productId),
    );
    const excludedProductIds = parseExcludedProductIds(
      options["exclude-product-ids"],
      knownProductIds,
    );
    selectedProducts = inputs.products.filter(
      (product) => !excludedProductIds.has(product.productId),
    );
    if (selectedProducts.length === 0) {
      throw new ToolError("Batch write has no selected products after exclusions.");
    }
  }

  assertRequiredExistingProducts(
    selectedProducts,
    remoteProducts,
    Boolean(options["require-existing"]),
  );
  assertRequiredMissingProducts(
    selectedProducts,
    remoteProducts,
    Boolean(options["require-missing"]),
  );

  for (const product of selectedProducts) {
    const remote = remoteProducts.get(product.productId);
    if (
      remote &&
      remote.attributes &&
      remote.attributes.inAppPurchaseType !== IAP_TYPE
    ) {
      throw new ToolError(
        product.productId + " already exists with type " +
        String(remote.attributes.inAppPurchaseType) + "; expected " + IAP_TYPE + ".",
      );
    }
  }

  const sources = await resolveConfiguredPolicies(
    client,
    inputs,
    remoteProducts,
    inspections,
  );
  const screenshotInputs = new Map();
  for (const product of selectedProducts) {
    const inspection = inspections.get(product.productId);
    if (inspection && inspection.price && inspection.price.customerPrice) {
      if (
        normalizedDecimal(inspection.price.customerPrice) !==
        normalizedDecimal(sources.priceSource.customerPrice)
      ) {
        throw new ToolError(
          product.productId + " already has JPY " +
          inspection.price.customerPrice + ", which differs from the approved source JPY " +
          sources.priceSource.customerPrice +
          ". This tool will not overwrite an existing Apple price.",
        );
      }
    }
    if (
      inspection &&
      inspection.availability &&
      !sameAvailability(inspection.availability, sources.availabilitySource)
    ) {
      throw new ToolError(
        product.productId +
        " has a different availability policy. This tool will not overwrite it.",
      );
    }
    if (includeScreenshots &&
      inspection &&
      inspection.screenshotState &&
      inspection.screenshotState !== COMPLETE_ASSET_STATE &&
      inspection.screenshotState !== "AWAITING_UPLOAD" &&
      inspection.screenshotState !== "UPLOAD_COMPLETE"
    ) {
      throw new ToolError(
        product.productId + " has review screenshot state " +
        inspection.screenshotState + ". Resolve it in App Store Connect before writing.",
      );
    }
    if (includeScreenshots &&
        (!inspection || inspection.screenshotState !== COMPLETE_ASSET_STATE)) {
      const screenshotPath = inputs.screenshotPaths[product.productId];
      if (!screenshotPath) {
        throw new ToolError(
          "No real in-app review screenshot is mapped for " + product.productId + ".",
        );
      }
      const info = await imageInfo(screenshotPath);
      screenshotInputs.set(product.productId, info);
      console.log(
        "Screenshot preflight " + product.productId + ": " +
        info.format + " " + info.width + "x" + info.height +
        " (" + info.fileSize + " bytes)",
      );
    }
  }

  console.log("");
  console.log("WRITE PREFLIGHT PASSED");
  console.log("App: " + app.id + " / " + inputs.config.bundleId);
  console.log("Selected products: " + selectedProducts.length);
  console.log(
    "Apple price policy: " + sources.priceSource.productId +
    " -> JPY " + sources.priceSource.customerPrice,
  );
  console.log(
    "Availability policy: " + sources.availabilitySource.productId +
    " -> " + sources.availabilitySource.territoryIds.length + " territories",
  );
  console.log(
    "Review screenshots: " + (includeScreenshots
      ? "required and uploaded when missing"
      : "deferred so real TestFlight screens can be captured"),
  );
  console.log("Review submission/publication: disabled");
  console.log("");
  return {
    selectedProducts,
    screenshotInputs,
    includeScreenshots,
    ...sources,
  };
}

async function listVersions(client, remoteId) {
  const requestPath = withQuery(
    "/v2/inAppPurchases/" + encodeURIComponent(remoteId) + "/versions",
    { limit: 50 },
  );
  return client.fetchAll(requestPath);
}

async function ensureProductResource(client, appId, product, remoteProducts) {
  let remote = remoteProducts.get(product.productId);
  if (!remote) {
    console.log(product.productId + ": creating " + IAP_TYPE + " product");
    const response = await client.post(
      "/v2/inAppPurchases",
      buildProductCreatePayload(appId, product),
    );
    remote = response.data;
    remoteProducts.set(product.productId, remote);
  } else {
    const attributes = remote.attributes || {};
    if (attributes.inAppPurchaseType !== IAP_TYPE) {
      throw new ToolError(
        product.productId + " has immutable type " +
        String(attributes.inAppPurchaseType) + ", expected " + IAP_TYPE + ".",
      );
    }
  }

  const attributes = remote.attributes || {};
  if (
    attributes.name !== product.referenceName ||
    attributes.reviewNote !== product.reviewNote
  ) {
    console.log(product.productId + ": updating reference name/review note");
    const response = await client.patch(
      "/v2/inAppPurchases/" + encodeURIComponent(remote.id),
      buildProductUpdatePayload(remote.id, product),
    );
    remote = response.data;
    remoteProducts.set(product.productId, remote);
  }
  return remote;
}

async function ensureEditableVersion(client, remoteId) {
  const versions = await listVersions(client, remoteId);
  const drafts = versions.filter(
    (version) => version.attributes && version.attributes.state === DRAFT_VERSION_STATE,
  );
  if (drafts.length > 1) {
    throw new ToolError("More than one editable IAP version exists for " + remoteId + ".");
  }
  if (drafts.length === 1) {
    return drafts[0];
  }
  const response = await client.post(
    "/v1/inAppPurchaseVersions",
    buildVersionCreatePayload(remoteId),
  );
  return response.data;
}

async function ensureLocalizations(client, version, product, config) {
  const existing = await readLocalizations(client, version);
  for (const desired of desiredLocalizationEntries(config, product)) {
    const current = existing.get(desired.locale);
    if (!current) {
      console.log(product.productId + ": creating locale " + desired.locale);
      await client.post(
        "/v2/inAppPurchaseLocalizations",
        buildLocalizationCreatePayload(
          version.id,
          desired.locale,
          desired.name,
          desired.description,
        ),
      );
    } else if (!localizationMatches(current, desired.name, desired.description)) {
      console.log(product.productId + ": updating locale " + desired.locale);
      await client.patch(
        "/v2/inAppPurchaseLocalizations/" + encodeURIComponent(current.id),
        buildLocalizationUpdatePayload(
          current.id,
          desired.name,
          desired.description,
        ),
      );
    }
  }
}

async function ensurePrice(client, remote, territory, priceSource) {
  const current = await readCurrentPrice(client, remote.id, territory);
  if (current && current.customerPrice) {
    if (
      normalizedDecimal(current.customerPrice) !==
      normalizedDecimal(priceSource.customerPrice)
    ) {
      throw new ToolError(
        "Refusing to change existing price for " + remote.id +
        " from " + current.customerPrice + " to " + priceSource.customerPrice + ".",
      );
    }
    return;
  }
  const pricePoints = await listPricePoints(client, remote.id, territory);
  let matches = [];
  if (priceSource.priceTier) {
    matches = pricePoints.filter(
      (point) => point.attributes &&
      String(point.attributes.priceTier || "") === priceSource.priceTier,
    );
  }
  if (matches.length !== 1) {
    matches = pricePoints.filter(
      (point) => point.attributes &&
      normalizedDecimal(point.attributes.customerPrice) ===
        normalizedDecimal(priceSource.customerPrice),
    );
  }
  if (matches.length !== 1) {
    throw new ToolError(
      "Could not identify exactly one target-specific " + territory +
      " price point for customer price " + priceSource.customerPrice +
      ". No price was set.",
    );
  }
  console.log(
    String(remote.attributes && remote.attributes.productId || remote.id) +
    ": setting Apple customer price " + territory + " " + priceSource.customerPrice,
  );
  await client.post(
    "/v1/inAppPurchasePriceSchedules",
    buildPriceSchedulePayload(remote.id, matches[0].id, territory),
  );
}

async function ensureAvailability(client, remote, availabilitySource) {
  const current = await readAvailability(client, remote.id);
  if (current) {
    if (!sameAvailability(current, availabilitySource)) {
      throw new ToolError(
        "Refusing to overwrite different availability for " +
        String(remote.attributes && remote.attributes.productId || remote.id) + ".",
      );
    }
    return;
  }
  console.log(
    String(remote.attributes && remote.attributes.productId || remote.id) +
    ": setting " + availabilitySource.territoryIds.length + " sale territories",
  );
  await client.post(
    "/v1/inAppPurchaseAvailabilities",
    buildAvailabilityPayload(
      remote.id,
      availabilitySource.territoryIds,
      availabilitySource.availableInNewTerritories,
    ),
  );
}

async function readScreenshot(client, remoteId) {
  const relationship = await client.get(
    "/v2/inAppPurchases/" + encodeURIComponent(remoteId) +
    "/relationships/appStoreReviewScreenshot",
    { allow404: true },
  );
  const screenshotId = relationship && relationship.data
    ? String(relationship.data.id || "")
    : "";
  if (!screenshotId) {
    return null;
  }
  const response = await client.get(
    "/v1/inAppPurchaseAppStoreReviewScreenshots/" + encodeURIComponent(screenshotId),
  );
  return response.data;
}

function assetState(screenshot) {
  return screenshot && screenshot.attributes && screenshot.attributes.assetDeliveryState
    ? String(screenshot.attributes.assetDeliveryState.state || "")
    : "";
}

async function pollScreenshot(client, screenshotId) {
  let screenshot = null;
  for (let attempt = 0; attempt < 16; attempt += 1) {
    const response = await client.get(
      "/v1/inAppPurchaseAppStoreReviewScreenshots/" +
      encodeURIComponent(screenshotId),
    );
    screenshot = response.data;
    const state = assetState(screenshot);
    if (state === COMPLETE_ASSET_STATE) {
      return screenshot;
    }
    if (state === "FAILED") {
      const errors = screenshot.attributes.assetDeliveryState.errors || [];
      throw new ToolError(
        "Apple rejected the review screenshot: " + JSON.stringify(errors),
      );
    }
    await sleep(2000);
  }
  console.warn(
    "Screenshot " + screenshotId +
    " is still processing. Re-run authenticated dry-run to verify it later.",
  );
  return screenshot;
}

async function ensureScreenshot(client, remote, screenshotInput) {
  let screenshot = await readScreenshot(client, remote.id);
  let state = assetState(screenshot);
  if (state === COMPLETE_ASSET_STATE) {
    return;
  }
  if (!screenshotInput) {
    throw new ToolError(
      "A real review screenshot is required for " +
      String(remote.attributes && remote.attributes.productId || remote.id) + ".",
    );
  }
  if (state === "FAILED") {
    throw new ToolError(
      "The existing review screenshot failed processing. This tool never deletes " +
      "review assets; resolve it in App Store Connect.",
    );
  }
  if (!screenshot) {
    const reservation = await client.post(
      "/v1/inAppPurchaseAppStoreReviewScreenshots",
      buildScreenshotReservationPayload(
        remote.id,
        screenshotInput.fileName,
        screenshotInput.fileSize,
      ),
    );
    screenshot = reservation.data;
    state = assetState(screenshot);
  }
  if (state === "UPLOAD_COMPLETE") {
    await pollScreenshot(client, screenshot.id);
    return;
  }
  if (state && state !== "AWAITING_UPLOAD") {
    await pollScreenshot(client, screenshot.id);
    return;
  }
  const attributes = screenshot.attributes || {};
  if (
    Number(attributes.fileSize) !== screenshotInput.fileSize ||
    String(attributes.fileName || "") !== screenshotInput.fileName
  ) {
    throw new ToolError(
      "An unfinished screenshot reservation exists for a different file. " +
      "This tool will not delete it.",
    );
  }
  const operations = attributes.uploadOperations || [];
  if (operations.length === 0) {
    throw new ToolError("Apple returned no upload operations for the review screenshot.");
  }
  for (const operation of operations) {
    await client.uploadOperation(operation, screenshotInput.buffer);
  }
  await client.patch(
    "/v1/inAppPurchaseAppStoreReviewScreenshots/" +
    encodeURIComponent(screenshot.id),
    {
      data: {
        type: "inAppPurchaseAppStoreReviewScreenshots",
        id: screenshot.id,
        attributes: {
          uploaded: true,
          sourceFileChecksum: screenshotInput.md5,
        },
      },
    },
  );
  await pollScreenshot(client, screenshot.id);
}

async function applyProducts({
  client,
  app,
  inputs,
  remoteProducts,
  prepared,
}) {
  let completed = 0;
  for (const product of prepared.selectedProducts) {
    console.log(
      "[" + (completed + 1) + "/" + prepared.selectedProducts.length + "] " +
      product.productId + " " + product.displayNameJa,
    );
    const remote = await ensureProductResource(
      client,
      app.id,
      product,
      remoteProducts,
    );
    const version = await ensureEditableVersion(client, remote.id);
    await ensureLocalizations(client, version, product, inputs.config);
    await ensurePrice(
      client,
      remote,
      inputs.config.baseTerritory,
      prepared.priceSource,
    );
    await ensureAvailability(client, remote, prepared.availabilitySource);
    if (prepared.includeScreenshots) {
      await ensureScreenshot(
        client,
        remote,
        prepared.screenshotInputs.get(product.productId),
      );
    }
    completed += 1;
    console.log(
      product.productId + (prepared.includeScreenshots
        ? ": reconciled without review submission"
        : ": staged without review screenshot or submission"),
    );
  }
  console.log("");
  console.log("Write run completed: " + completed + "/" + prepared.selectedProducts.length);
  console.log("Review submissions created: 0");
  console.log("Public releases triggered: 0");
}

async function runWrite(command, options, inputs) {
  const authentication = await loadAuthentication();
  const client = new AppStoreConnectClient(authentication);
  const app = await resolveApp(
    client,
    inputs.config.bundleId,
    authentication.explicitAppId,
  );
  const remoteProducts = await listProducts(client, app.id);
  const inspections = await inspectAllCatalogProducts(client, remoteProducts, inputs);
  const prepared = await prepareWrite({
    command,
    options,
    inputs,
    client,
    app,
    remoteProducts,
    inspections,
  });
  await applyProducts({
    client,
    app,
    inputs,
    remoteProducts,
    prepared,
  });
}

function printHelp() {
  console.log("App Store Connect automation for the 36 pot design IAPs");
  console.log("");
  console.log("Read-only commands:");
  console.log("  node tools/app_store_connect_iap.mjs plan");
  console.log("  node tools/app_store_connect_iap.mjs dry-run");
  console.log("  node tools/app_store_connect_iap.mjs verify-catalog");
  console.log(
    "  node tools/app_store_connect_iap.mjs policy-research --amount 100",
  );
  console.log("");
  console.log("Write commands (blocked without exact confirmation):");
  console.log(
    "  node tools/app_store_connect_iap.mjs stage-one " +
    "--product-id pot_unlock_NNN --confirm STAGE_WITHOUT_SCREENSHOT:pot_unlock_NNN",
  );
  console.log(
    "  node tools/app_store_connect_iap.mjs stage-all " +
    "--confirm STAGE_ALL_WITHOUT_SCREENSHOTS",
  );
  console.log(
    "  node tools/app_store_connect_iap.mjs apply-one " +
    "--product-id pot_unlock_NNN --confirm CREATE_OR_RECONCILE:pot_unlock_NNN",
  );
  console.log(
    "  node tools/app_store_connect_iap.mjs apply-all " +
    "--confirm RECONCILE_ALL_36_IAPS",
  );
  console.log("");
  console.log(
    "Use --config tools/app_store_connect_iap.config.local.json to select a config.",
  );
  console.log("The tool never submits an IAP for review and never releases an IAP.");
}

async function main() {
  const { command, options } = parseArgs(process.argv.slice(2));
  if (command === "help" || options.help) {
    printHelp();
    return;
  }
  if (!["plan", "dry-run", "policy-research", "verify-catalog", "stage-one", "stage-all", "apply-one", "apply-all"].includes(command)) {
    throw new ToolError("Unknown command: " + command);
  }
  const inputs = await loadInputs(options.config);
  if (command === "plan") {
    printOfflinePlan(inputs);
    return;
  }
  if (command === "dry-run") {
    await runAuthenticatedDryRun(inputs);
    return;
  }
  if (command === "policy-research") {
    await runPolicyResearch(inputs, options);
    return;
  }
  if (command === "verify-catalog") {
    await runCatalogVerification(inputs, options);
    return;
  }
  if (command === "stage-one" || command === "apply-one") {
    const productId = String(options["product-id"] || "");
    if (!inputs.products.some((product) => product.productId === productId)) {
      throw new ToolError(
        "--product-id must be one of pot_unlock_001 through pot_unlock_036.",
      );
    }
    confirmWriteCommand(command, options, productId);
  } else {
    confirmWriteCommand(command, options);
  }
  await runWrite(command, options, inputs);
}

const invokedAsMain = process.argv[1] &&
  pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url;
if (invokedAsMain) {
  main().catch((error) => {
    const prefix = error instanceof ToolError ? "ERROR" : "UNEXPECTED ERROR";
    console.error(prefix + ": " + error.message);
    process.exitCode = error instanceof ToolError ? error.exitCode : 1;
  });
}
