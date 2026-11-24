/**
 * Majlis: live voice spaces for WellMate.
 *
 * To merge into WellMate's `functions/` folder:
 *   1. copy this file next to index.js,
 *   2. add "livekit-server-sdk" to package.json,
 *   3. add `Object.assign(exports, require("./majlis"));` to index.js.
 *
 * Voice runs on LiveKit (open source, or LiveKit Cloud). Firestore holds the
 * list of spaces and private profiles. Nothing is ever recorded.
 *
 * Config (see INTEGRATION.md):
 *   LIVEKIT_URL         wss://<project>.livekit.cloud      (param)
 *   LIVEKIT_API_URL     optional server URL, defaults to LIVEKIT_URL (param)
 *   LIVEKIT_API_KEY     (secret)
 *   LIVEKIT_API_SECRET  (secret)
 */
const crypto = require("crypto");
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret, defineString, defineBoolean } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const functionsV1 = require("firebase-functions/v1");
const { initializeApp, getApps } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const {
  AccessToken,
  RoomServiceClient,
  WebhookReceiver,
  DataPacket_Kind,
  TrackSource,
  TrackType,
} = require("livekit-server-sdk");

if (!getApps().length) initializeApp();
const db = getFirestore();

const LIVEKIT_URL = defineString("LIVEKIT_URL");
const LIVEKIT_API_URL = defineString("LIVEKIT_API_URL", { default: "" });
const LIVEKIT_API_KEY = defineSecret("LIVEKIT_API_KEY");
const LIVEKIT_API_SECRET = defineSecret("LIVEKIT_API_SECRET");
// Email/password accounts must verify their email before using Majlis.
const REQUIRE_VERIFIED = defineBoolean("MAJLIS_REQUIRE_VERIFIED_EMAIL", { default: true });
// App Check: turn on once WellMate sends App Check tokens (INTEGRATION.md).
// Then calls from anything but the real app are refused.
const ENFORCE_APP_CHECK = defineBoolean("MAJLIS_ENFORCE_APP_CHECK", { default: false });

// Majlis runs in Delhi, next to WellMate's Firestore (asia-south2), so each
// read and write stays in one region. 1st gen functions can't run there, so
// the one account-deletion trigger (background only) stays in us-central1.
const REGION = "asia-south2";
const V1_REGION = "us-central1";
// Majlis runs as its own service account, which may only read and write
// Firestore (roles/datastore.user) and read the two LiveKit secrets. The
// Learnistan Workspace gives Google's default accounts no roles, and the
// public AI chat should not share Majlis's database access anyway.
const SERVICE_ACCOUNT = "majlis-functions@";
const SECRETS = [LIVEKIT_API_KEY, LIVEKIT_API_SECRET];
const CALL = { region: REGION, secrets: SECRETS, serviceAccount: SERVICE_ACCOUNT };

const TOPICS = ["chai", "sleep", "study", "moms", "poetry", "faith", "hope", "home"];
const LANGS = ["fa", "ps", "en"];
const AUDIENCES = ["open", "women", "invite"];
const REPORT_REASONS = ["unsafe", "harassment", "identity", "spam", "other"];
// The fixed veil names (same list as MajlisCatalog.veils and firestore.rules).
const VEILS = new Set([
  "red_tulip", "almond_blossom", "morning_sun", "night_star", "little_lamp", "kabul_rain",
  "mulberry", "pomegranate", "apricot", "walnut", "saffron_moon", "blue_butterfly",
  "wild_rose", "cypress", "hindu_kush", "soft_cloud", "little_sparrow", "green_apple",
  "honey", "autumn_leaf", "sunflower", "prayer_beads", "little_teapot", "warm_naan",
  "peacock", "cherry", "shomali_grape", "lemon_tree", "clay_jug", "little_lamb",
  "morning_breeze", "silver_moon", "mountain_spring", "salang_snow", "panjshir_river", "bamyan_sky",
  "golden_wheat", "fig_tree", "jasmine", "raindrop", "little_fox",
]);
const MAX_STAGE = 12; // speakers, host included
const AUTO_MUTE_REPORTS = 3; // different people reporting someone in one space
const MAX_SCHEDULED = 5;
const HOST_AWAY_MS = 5 * 60 * 1000; // end a space 5 min after the host drops
const MAX_LIVE_MS = 12 * 60 * 60 * 1000;
const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

// ---- Helpers ----------------------------------------------------------------

const bad = (what) => new HttpsError("invalid-argument", `bad-${what}`);
const spaces = () => db.collection("majlis_spaces");
const profileRef = (uid) => db.doc(`majlis_profiles/${uid}`);

/** The signed-in WellMate user. Error messages are keys the app translates. */
function uidOf(req) {
  if (ENFORCE_APP_CHECK.value() && !req.app) throw new HttpsError("failed-precondition", "app-check");
  const auth = req.auth;
  if (!auth) throw new HttpsError("unauthenticated", "sign-in");
  const provider = auth.token.firebase && auth.token.firebase.sign_in_provider;
  if (provider === "anonymous") throw new HttpsError("permission-denied", "sign-in");
  if (REQUIRE_VERIFIED.value() && provider === "password" && auth.token.email_verified !== true) {
    throw new HttpsError("permission-denied", "verify-email");
  }
  return auth.uid;
}

/**
 * Per-person limits, so one account can't flood a space or run up costs.
 * [how many, per seconds]. Generous for real use.
 */
const LIMITS = {
  create: [6, 3600],
  join: [40, 600],
  stage: [40, 60],
  host: [60, 60],
  whisper: [6, 60],
  tea: [20, 60],
  remind: [30, 600],
  report: [10, 3600],
};

async function limit(uid, kind) {
  const [max, seconds] = LIMITS[kind];
  const ref = db.doc(`majlis_rate/${uid}`);
  const ok = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = Date.now();
    const cur = snap.exists ? snap.get(kind) : null;
    if (!cur || now - cur.start >= seconds * 1000) {
      tx.set(ref, { [kind]: { start: now, n: 1 } }, { merge: true });
      return true;
    }
    if (cur.n >= max) return false;
    tx.set(ref, { [kind]: { start: cur.start, n: cur.n + 1 } }, { merge: true });
    return true;
  });
  if (!ok) throw new HttpsError("resource-exhausted", "slow-down");
}

function cleanText(value, { min = 0, max, what }) {
  if (value === undefined || value === null || value === "") {
    if (min > 0) throw bad(what);
    return null;
  }
  if (typeof value !== "string") throw bad(what);
  const text = value.replace(/\s+/g, " ").trim();
  if (text.length < min || text.length > max) throw bad(what);
  return text.length ? text : null;
}

function idOf(value, what) {
  if (typeof value !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) throw bad(what);
  return value;
}

function roomService() {
  const url = (LIVEKIT_API_URL.value() || LIVEKIT_URL.value()).replace(/^ws/, "http");
  return new RoomServiceClient(url, LIVEKIT_API_KEY.value(), LIVEKIT_API_SECRET.value());
}

async function profileOf(uid) {
  const snap = await profileRef(uid).get();
  if (!snap.exists || !VEILS.has(snap.get("veil"))) throw new HttpsError("failed-precondition", "no-veil");
  return snap.data();
}

/** WellMate guides are added by the team in `majlis_guides/{uid}` ({name}). */
async function guideOf(uid) {
  const snap = await db.doc(`majlis_guides/${uid}`).get();
  if (!snap.exists) return null;
  return { name: String(snap.get("name") || "").slice(0, 24) };
}

/** What other people may see about someone: the veil, never the account. */
function personOf(uid, profile, guide) {
  const p = {
    uid,
    veil: String(profile.veil),
    jewel: Number(profile.jewel) || 0,
    motif: Number(profile.motif) || 0,
  };
  if (guide) {
    p.guide = true;
    p.guideName = guide.name;
  }
  return p;
}

function personFromMetadata(identity, metadata) {
  try {
    const m = JSON.parse(metadata || "{}");
    const p = { uid: identity, veil: VEILS.has(m.veil) ? m.veil : "", jewel: Number(m.jewel) || 0, motif: Number(m.motif) || 0 };
    if (m.guide) {
      p.guide = true;
      p.guideName = String(m.guideName || "");
    }
    return p;
  } catch (_) {
    return { uid: identity, veil: "", jewel: 0, motif: 0 };
  }
}

async function liveSpace(spaceId) {
  const ref = spaces().doc(idOf(spaceId, "space"));
  const snap = await ref.get();
  if (!snap.exists || snap.get("status") !== "live") throw new HttpsError("not-found", "space-gone");
  return { ref, s: snap.data() };
}

function requireHost(s, uid) {
  if (s.hostUid !== uid) throw new HttpsError("permission-denied", "host-only");
}

/** Safety actions: the host, or any WellMate guide (majlis_guides/{uid}). */
const GUIDE_ACTIONS = new Set(["end", "pin", "mute", "muteAll", "remove"]);
async function requireModerator(s, uid) {
  if (s.hostUid === uid) return;
  if (await guideOf(uid)) return;
  throw new HttpsError("permission-denied", "host-only");
}

/**
 * When the person holding the turn leaves the stage, the next speaker gets it
 * (otherwise everyone waits for the 2-minute timer). Returns fields to update.
 */
function passTurnFrom(s, who) {
  if (!s.turns || !s.turn || s.turn.uid !== who) return {};
  const order = s.speakerUids || [];
  const i = order.indexOf(who);
  const rest = order.filter((u) => u !== who);
  const next = rest.length ? rest[Math.max(0, i) % rest.length] : s.hostUid;
  return { turn: { uid: next, startedAt: FieldValue.serverTimestamp() } };
}

async function ensureRoom(spaceId) {
  await roomService().createRoom({
    name: spaceId,
    emptyTimeout: 10 * 60,
    departureTimeout: 60,
    maxParticipants: 500,
  });
}

async function newInviteCode(spaceId) {
  for (let i = 0; i < 6; i++) {
    let code = "";
    for (let j = 0; j < 6; j++) code += CODE_ALPHABET[crypto.randomInt(CODE_ALPHABET.length)];
    try {
      await db.doc(`majlis_invites/${code}`).create({ spaceId, at: FieldValue.serverTimestamp() });
      return code;
    } catch (e) {
      if (e.code !== 6) throw e; // 6 = ALREADY_EXISTS
    }
  }
  throw new HttpsError("internal", "try-again");
}

async function sendTo(spaceId, identities, topic, payload) {
  const data = new TextEncoder().encode(JSON.stringify(payload || {}));
  await roomService().sendData(spaceId, data, DataPacket_Kind.RELIABLE, {
    destinationIdentities: identities,
    topic,
  });
}

async function setCanSpeak(spaceId, identity, canSpeak) {
  try {
    await roomService().updateParticipant(spaceId, identity, {
      permission: {
        canSubscribe: true,
        canPublish: canSpeak,
        canPublishData: true,
        canPublishSources: [TrackSource.MICROPHONE],
      },
    });
  } catch (e) {
    // They may have left already; their next token follows speakerUids.
    logger.info("setCanSpeak skipped", { spaceId, identity, error: String(e) });
  }
}

/** Recomputes the stage preview and listener count shown in the hallway. */
async function refreshRoom(spaceId) {
  const ref = spaces().doc(spaceId);
  const snap = await ref.get();
  if (!snap.exists || snap.get("status") !== "live") return;
  const s = snap.data();
  let participants;
  try {
    participants = await roomService().listParticipants(spaceId);
  } catch (e) {
    logger.warn("listParticipants failed", { spaceId, error: String(e) });
    return;
  }
  const stage = [];
  let listeners = 0;
  let hostHere = false;
  for (const p of participants) {
    if (p.identity === s.hostUid) hostHere = true;
    if (p.permission && p.permission.canPublish) stage.push(personFromMetadata(p.identity, p.metadata));
    else listeners++;
  }
  stage.sort((a, b) => (a.uid === s.hostUid ? -1 : b.uid === s.hostUid ? 1 : 0));
  await ref.update({
    stage: stage.slice(0, MAX_STAGE),
    listenerCount: listeners,
    hostAwaySince: hostHere ? null : s.hostAwaySince || FieldValue.serverTimestamp(),
  });
}

async function closeSpace(ref, status) {
  const snap = await ref.get();
  if (!snap.exists) return;
  const s = snap.data();
  if (s.status !== "live" && s.status !== "scheduled") return;
  await ref.update({
    status,
    endedAt: FieldValue.serverTimestamp(),
    stage: [],
    listenerCount: 0,
    turn: null,
    invitedUids: [],
    hands: [],
  });
  if (s.inviteCode) await db.doc(`majlis_invites/${s.inviteCode}`).delete().catch(() => {});
  if (s.status === "live") {
    await roomService().deleteRoom(ref.id).catch(() => {});
  }
}

// ---- Spaces -----------------------------------------------------------------

/** Opens a space now, or schedules it (startsAt = epoch millis). */
exports.majlisCreateSpace = onCall(CALL, async (req) => {
  const uid = uidOf(req);
  await limit(uid, "create");
  const d = req.data || {};
  const title = cleanText(d.title, { min: 3, max: 90, what: "title" });
  const question = cleanText(d.question, { max: 200, what: "question" });
  if (!TOPICS.includes(d.topic)) throw bad("topic");
  if (!LANGS.includes(d.lang)) throw bad("lang");
  if (!AUDIENCES.includes(d.audience)) throw bad("audience");
  let when = null;
  if (d.startsAt !== undefined && d.startsAt !== null) {
    const ms = Number(d.startsAt);
    const now = Date.now();
    if (!Number.isFinite(ms) || ms < now + 5 * 60 * 1000 || ms > now + 8 * 24 * 3600 * 1000) throw bad("time");
    when = Timestamp.fromMillis(ms);
  }

  const profile = await profileOf(uid);
  if (d.audience === "women" && profile.womenSpaces !== true) {
    throw new HttpsError("failed-precondition", "women-confirm");
  }
  const host = personOf(uid, profile, await guideOf(uid));

  const mine = await spaces().where("hostUid", "==", uid).where("status", "in", ["live", "scheduled"]).get();
  const live = mine.docs.filter((x) => x.get("status") === "live");
  if (!when && live.length) {
    throw new HttpsError("already-exists", "already-hosting", { spaceId: live[0].id });
  }
  if (when && mine.size - live.length >= MAX_SCHEDULED) {
    throw new HttpsError("resource-exhausted", "too-many-scheduled");
  }

  const ref = spaces().doc();
  const inviteCode = d.audience === "invite" ? await newInviteCode(ref.id) : null;
  const now = FieldValue.serverTimestamp();
  const batch = db.batch();
  batch.set(ref, {
    title,
    topic: d.topic,
    lang: d.lang,
    audience: d.audience,
    question,
    turns: d.turns === true,
    hostUid: uid,
    host,
    status: when ? "scheduled" : "live",
    scheduledFor: when,
    startedAt: when ? null : now,
    endedAt: null,
    createdAt: now,
    inviteCode,
    speakerUids: [uid],
    invitedUids: [],
    hands: [],
    stage: [host],
    listenerCount: 0,
    pinned: question ? { text: question, whisper: false } : null,
    turn: !when && d.turns === true ? { uid, startedAt: now } : null,
    goingCount: when ? 1 : 0,
    // The host counts as away until their app connects.
    hostAwaySince: when ? null : now,
  });
  if (when) batch.set(ref.collection("going").doc(uid), { uid, at: now });
  else batch.set(profileRef(uid), { stats: { hosted: FieldValue.increment(1) } }, { merge: true });
  await batch.commit();
  if (!when) await ensureRoom(ref.id);
  return { spaceId: ref.id, inviteCode };
});

/**
 * Lets a signed-in user into a live space and returns a LiveKit token.
 * Pass {spaceId} or {code} (an invite code).
 */
exports.majlisJoin = onCall(CALL, async (req) => {
  const uid = uidOf(req);
  await limit(uid, "join");
  const d = req.data || {};
  let spaceId = typeof d.spaceId === "string" ? idOf(d.spaceId, "space") : null;
  let viaCode = false;
  if (!spaceId && typeof d.code === "string") {
    const code = d.code.toUpperCase().replace(/[^A-Z0-9]/g, "");
    if (code.length !== 6) throw new HttpsError("not-found", "bad-code");
    const invite = await db.doc(`majlis_invites/${code}`).get();
    if (!invite.exists) throw new HttpsError("not-found", "bad-code");
    spaceId = invite.get("spaceId");
    viaCode = true;
  }
  if (!spaceId) throw bad("space");

  const ref = spaces().doc(spaceId);
  const [snap, profile, removed, member] = await Promise.all([
    ref.get(),
    profileOf(uid),
    ref.collection("removed").doc(uid).get(),
    ref.collection("members").doc(uid).get(),
  ]);
  if (!snap.exists) throw new HttpsError("not-found", "space-gone");
  const s = snap.data();
  const isHost = s.hostUid === uid;

  if (removed.exists) throw new HttpsError("permission-denied", "removed");
  if (!isHost) {
    const hostProfile = await profileRef(s.hostUid).get();
    if ((hostProfile.get("blocked") || []).includes(uid)) throw new HttpsError("permission-denied", "unavailable");
    if ((profile.blocked || []).includes(s.hostUid)) throw new HttpsError("permission-denied", "you-blocked-host");
    if (s.audience === "women" && profile.womenSpaces !== true) {
      throw new HttpsError("failed-precondition", "women-confirm");
    }
    if (s.audience === "invite" && !viaCode && !member.exists) {
      throw new HttpsError("permission-denied", "invite-needed");
    }
  }
  // An invite code for a space that hasn't started: remember the person and
  // let the app show the event (they can then read it).
  if (s.status === "scheduled") {
    if (viaCode) await ref.collection("members").doc(uid).set({ uid, at: FieldValue.serverTimestamp() }, { merge: true });
    if (viaCode || isHost) return { spaceId, status: "scheduled" };
    throw new HttpsError("failed-precondition", "not-started");
  }
  if (s.status !== "live") throw new HttpsError("not-found", "space-gone");

  const me = personOf(uid, profile, await guideOf(uid));
  const canSpeak = isHost || (s.speakerUids || []).includes(uid);
  await ref.collection("members").doc(uid).set({ uid, at: FieldValue.serverTimestamp() }, { merge: true });
  await ensureRoom(spaceId);

  const token = new AccessToken(LIVEKIT_API_KEY.value(), LIVEKIT_API_SECRET.value(), {
    identity: uid,
    name: me.veil,
    metadata: JSON.stringify(me),
    ttl: "6h",
  });
  token.addGrant({
    room: spaceId,
    roomJoin: true,
    canSubscribe: true,
    canPublish: canSpeak,
    canPublishSources: [TrackSource.MICROPHONE],
    canPublishData: true,
    canUpdateOwnMetadata: false,
  });
  return {
    spaceId,
    status: "live",
    token: await token.toJwt(),
    url: LIVEKIT_URL.value(),
    role: isHost ? "host" : canSpeak ? "speaker" : "listener",
    moderator: isHost || !!me.guide,
  };
});

/**
 * Hands and stage. The host invites; only the invited person can accept, so
 * nobody's microphone is ever opened without their own tap.
 *   hand {up} · accept · decline · leave           (yourself)
 *   invite · lower · remove (with target)          (host)
 */
exports.majlisStage = onCall(CALL, async (req) => {
  const uid = uidOf(req);
  await limit(uid, "stage");
  const d = req.data || {};
  const { ref, s } = await liveSpace(d.spaceId);
  const spaceId = ref.id;
  const target = d.target === undefined ? null : idOf(d.target, "target");

  switch (d.action) {
    case "hand": {
      if ((s.speakerUids || []).includes(uid)) return { ok: true };
      await ref.update({ hands: d.up === true ? FieldValue.arrayUnion(uid) : FieldValue.arrayRemove(uid) });
      return { ok: true };
    }
    case "lower": {
      requireHost(s, uid);
      if (!target) throw bad("target");
      await ref.update({ hands: FieldValue.arrayRemove(target) });
      await sendTo(spaceId, [target], "majlis.lowered", {}).catch(() => {});
      return { ok: true };
    }
    case "invite": {
      requireHost(s, uid);
      if (!target || target === uid) throw bad("target");
      if ((s.speakerUids || []).length >= MAX_STAGE) throw new HttpsError("resource-exhausted", "stage-full");
      await ref.update({ invitedUids: FieldValue.arrayUnion(target), hands: FieldValue.arrayRemove(target) });
      await sendTo(spaceId, [target], "majlis.invite", {});
      return { ok: true };
    }
    case "accept": {
      const ok = await db.runTransaction(async (tx) => {
        const fresh = (await tx.get(ref)).data();
        if (!(fresh.invitedUids || []).includes(uid)) return false;
        if ((fresh.speakerUids || []).length >= MAX_STAGE) return false;
        tx.update(ref, {
          invitedUids: FieldValue.arrayRemove(uid),
          hands: FieldValue.arrayRemove(uid),
          speakerUids: FieldValue.arrayUnion(uid),
        });
        return true;
      });
      if (!ok) throw new HttpsError("failed-precondition", "invite-expired");
      await setCanSpeak(spaceId, uid, true);
      await refreshRoom(spaceId);
      return { ok: true };
    }
    case "decline": {
      await ref.update({ invitedUids: FieldValue.arrayRemove(uid) });
      return { ok: true };
    }
    case "leave":
    case "remove": {
      const who = d.action === "leave" ? uid : target;
      if (d.action === "remove") await requireModerator(s, uid);
      if (!who || who === s.hostUid) throw bad("target");
      await ref.update({
        speakerUids: FieldValue.arrayRemove(who),
        invitedUids: FieldValue.arrayRemove(who),
        ...passTurnFrom(s, who),
      });
      await setCanSpeak(spaceId, who, false);
      await refreshRoom(spaceId);
      return { ok: true };
    }
    default:
      throw bad("action");
  }
});

/** Host tools. */
exports.majlisHost = onCall(CALL, async (req) => {
  const uid = uidOf(req);
  await limit(uid, "host");
  const d = req.data || {};
  const ref = spaces().doc(idOf(d.spaceId, "space"));
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "space-gone");
  const s = snap.data();
  if (GUIDE_ACTIONS.has(d.action)) await requireModerator(s, uid);
  else requireHost(s, uid);
  const now = FieldValue.serverTimestamp();

  if (d.action === "start") {
    if (s.status !== "scheduled") throw new HttpsError("failed-precondition", "space-gone");
    const already = await spaces().where("hostUid", "==", uid).where("status", "==", "live").limit(1).get();
    if (!already.empty) throw new HttpsError("already-exists", "already-hosting", { spaceId: already.docs[0].id });
    await ref.update({
      status: "live",
      startedAt: now,
      hostAwaySince: now,
      stage: [s.host],
      turn: s.turns ? { uid, startedAt: now } : null,
    });
    await profileRef(uid).set({ stats: { hosted: FieldValue.increment(1) } }, { merge: true });
    await ensureRoom(ref.id);
    return { ok: true };
  }
  if (d.action === "cancel") {
    if (s.status !== "scheduled") throw new HttpsError("failed-precondition", "space-gone");
    await closeSpace(ref, "cancelled");
    return { ok: true };
  }
  if (s.status !== "live") throw new HttpsError("not-found", "space-gone");

  switch (d.action) {
    case "end":
      await closeSpace(ref, "ended");
      return { ok: true };
    case "pin": {
      let text = cleanText(d.text, { max: 200, what: "text" });
      let whisper = false;
      if (typeof d.whisperId === "string") {
        const w = await ref.collection("whispers").doc(idOf(d.whisperId, "whisper")).get();
        if (!w.exists) throw bad("whisper");
        text = w.get("text");
        whisper = true;
        await w.ref.update({ pinned: true });
      }
      await ref.update({ pinned: text ? { text, whisper } : null });
      return { ok: true };
    }
    case "turns": {
      const on = d.on === true;
      await ref.update({ turns: on, turn: on ? { uid: (s.speakerUids || [uid])[0], startedAt: now } : null });
      return { ok: true };
    }
    case "nextTurn": {
      const order = s.speakerUids || [uid];
      const i = s.turn ? order.indexOf(s.turn.uid) : -1;
      await ref.update({ turn: { uid: order[(i + 1) % order.length], startedAt: now } });
      return { ok: true };
    }
    case "mute":
    case "muteAll": {
      const target = d.action === "mute" ? idOf(d.target, "target") : null;
      const participants = await roomService().listParticipants(ref.id);
      for (const p of participants) {
        if (p.identity === uid || (target && p.identity !== target)) continue;
        for (const t of p.tracks || []) {
          if (t.type === TrackType.AUDIO && !t.muted) {
            await roomService().mutePublishedTrack(ref.id, p.identity, t.sid, true).catch(() => {});
          }
        }
      }
      return { ok: true };
    }
    case "remove": {
      const target = idOf(d.target, "target");
      if (target === uid || target === s.hostUid) throw bad("target");
      await ref.collection("removed").doc(target).set({ at: now });
      await ref.update({
        speakerUids: FieldValue.arrayRemove(target),
        invitedUids: FieldValue.arrayRemove(target),
        hands: FieldValue.arrayRemove(target),
        ...passTurnFrom(s, target),
      });
      await roomService().removeParticipant(ref.id, target).catch(() => {});
      await refreshRoom(ref.id);
      return { ok: true };
    }
    default:
      throw bad("action");
  }
});

/** "Write instead of speaking": the host sees the text, never the name. */
exports.majlisWhisper = onCall(CALL, async (req) => {
  const uid = uidOf(req);
  await limit(uid, "whisper");
  const d = req.data || {};
  const text = cleanText(d.text, { min: 1, max: 280, what: "text" });
  const { ref } = await liveSpace(d.spaceId);
  const memberRef = ref.collection("members").doc(uid);
  const member = await memberRef.get();
  if (!member.exists) throw new HttpsError("permission-denied", "join-first");
  const last = member.get("lastWhisperAt");
  if (last && Date.now() - last.toMillis() < 20 * 1000) throw new HttpsError("resource-exhausted", "slow-down");

  const w = ref.collection("whispers").doc();
  const batch = db.batch();
  batch.set(w, { text, at: FieldValue.serverTimestamp(), pinned: false });
  // Kept apart, for safety reviews only. No app can read it.
  batch.set(db.doc(`majlis_whisper_log/${w.id}`), { uid, spaceId: ref.id, at: FieldValue.serverTimestamp() });
  batch.update(memberRef, { lastWhisperAt: FieldValue.serverTimestamp() });
  await batch.commit();
  return { ok: true };
});

/** Pour tea: adds to the private "cups of tea received" count. */
exports.majlisTea = onCall(CALL, async (req) => {
  const uid = uidOf(req);
  await limit(uid, "tea");
  const d = req.data || {};
  const to = idOf(d.to, "target");
  if (to === uid) throw bad("target");
  const { ref } = await liveSpace(d.spaceId);
  const memberRef = ref.collection("members").doc(uid);
  const member = await memberRef.get();
  if (!member.exists) throw new HttpsError("permission-denied", "join-first");
  const last = member.get("lastTeaAt");
  if (last && Date.now() - last.toMillis() < 2000) return { ok: false };
  const target = await profileRef(to).get();
  if (!target.exists) return { ok: false };
  await Promise.all([
    profileRef(to).set({ stats: { tea: FieldValue.increment(1) } }, { merge: true }),
    memberRef.update({ lastTeaAt: FieldValue.serverTimestamp() }),
  ]);
  return { ok: true };
});

/** Going / reminder for a scheduled space. */
exports.majlisRemind = onCall(CALL, async (req) => {
  const uid = uidOf(req);
  await limit(uid, "remind");
  const d = req.data || {};
  const ref = spaces().doc(idOf(d.spaceId, "space"));
  const on = d.on === true;
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists || snap.get("status") !== "scheduled") throw new HttpsError("not-found", "space-gone");
    if (snap.get("hostUid") === uid) return { going: true, goingCount: snap.get("goingCount") || 1 };
    const goingRef = ref.collection("going").doc(uid);
    const going = await tx.get(goingRef);
    let count = snap.get("goingCount") || 0;
    if (on && !going.exists) {
      tx.set(goingRef, { uid, at: FieldValue.serverTimestamp() });
      tx.update(ref, { goingCount: FieldValue.increment(1) });
      count++;
    } else if (!on && going.exists) {
      tx.delete(goingRef);
      tx.update(ref, { goingCount: FieldValue.increment(-1) });
      count--;
    }
    return { going: on, goingCount: Math.max(count, 0) };
  });
});

/** Reports go to the WellMate team (majlis_reports), never to the person. */
exports.majlisReport = onCall(CALL, async (req) => {
  const uid = uidOf(req);
  await limit(uid, "report");
  const d = req.data || {};
  if (!REPORT_REASONS.includes(d.reason)) throw bad("reason");
  const note = cleanText(d.note, { max: 300, what: "note" });
  const target = d.target ? idOf(d.target, "target") : null;
  const spaceId = d.spaceId ? idOf(d.spaceId, "space") : null;
  let space = null;
  if (spaceId) {
    const snap = await spaces().doc(spaceId).get();
    if (snap.exists) space = { id: spaceId, title: snap.get("title"), hostUid: snap.get("hostUid") };
  }
  await db.collection("majlis_reports").add({
    by: uid,
    target: target || (space && space.hostUid) || null,
    aboutSpace: !target,
    space,
    reason: d.reason,
    note,
    at: FieldValue.serverTimestamp(),
    status: "new",
  });
  if (target && space && target !== uid) await countReport(spaceId, target, uid);
  return { ok: true };
});

/**
 * When several different people report the same person in one live space,
 * stop their voice at once instead of waiting for the host: mute their mic
 * and move them back to listening (a host is only muted). The host gets a
 * note, and the reports stay in majlis_reports for the team.
 */
async function countReport(spaceId, target, by) {
  const ref = spaces().doc(spaceId);
  const tally = ref.collection("reports").doc(target);
  const act = await db.runTransaction(async (tx) => {
    const [s, t] = await Promise.all([tx.get(ref), tx.get(tally)]);
    if (!s.exists || s.get("status") !== "live") return null;
    const byList = new Set(t.exists ? t.get("by") || [] : []);
    byList.add(by);
    const reached = byList.size >= AUTO_MUTE_REPORTS && !(t.exists && t.get("actioned"));
    tx.set(tally, { by: [...byList], actioned: reached || (t.exists && !!t.get("actioned")), at: FieldValue.serverTimestamp() });
    if (!reached) return null;
    const data = s.data();
    if (target !== data.hostUid) {
      tx.update(ref, {
        speakerUids: FieldValue.arrayRemove(target),
        invitedUids: FieldValue.arrayRemove(target),
        hands: FieldValue.arrayRemove(target),
        ...passTurnFrom(data, target),
      });
    }
    return { hostUid: data.hostUid };
  });
  if (!act) return;
  logger.info("auto-muted after reports", { spaceId, target });
  try {
    const p = await roomService().getParticipant(spaceId, target);
    for (const t of p.tracks || []) {
      if (t.type === TrackType.AUDIO && !t.muted) await roomService().mutePublishedTrack(spaceId, target, t.sid, true);
    }
  } catch (_) { /* not in the room any more */ }
  if (target !== act.hostUid) {
    await setCanSpeak(spaceId, target, false);
    await refreshRoom(spaceId);
  }
  await sendTo(spaceId, [act.hostUid], "majlis.autoMuted", { target }).catch(() => {});
}

// ---- LiveKit webhook ----------------------------------------------------------

/**
 * Point LiveKit's webhook at this URL. It keeps the hallway's counts honest
 * and records private stats (spaces joined, minutes listened).
 */
exports.majlisWebhook = onRequest({ region: REGION, secrets: SECRETS, serviceAccount: SERVICE_ACCOUNT }, async (req, res) => {
  let event;
  try {
    const receiver = new WebhookReceiver(LIVEKIT_API_KEY.value(), LIVEKIT_API_SECRET.value());
    event = await receiver.receive(req.rawBody.toString("utf8"), req.get("Authorization"));
  } catch (e) {
    res.status(401).send("unauthorized");
    return;
  }
  const spaceId = event.room && event.room.name;
  try {
    if (spaceId && /^[A-Za-z0-9]{10,40}$/.test(spaceId)) {
      if (event.event === "participant_joined") {
        await enforceSeat(spaceId, event.participant);
        await refreshRoom(spaceId);
      } else if (event.event === "participant_left" && event.participant) {
        await onParticipantLeft(spaceId, event.participant);
        await refreshRoom(spaceId);
      } else if (event.event === "room_finished") {
        await closeSpace(spaces().doc(spaceId), "ended");
      }
    }
  } catch (e) {
    logger.error("majlisWebhook", { event: event.event, spaceId, error: String(e) });
  }
  res.status(200).send("ok");
});

/**
 * A voice token can't be taken back (it is valid for hours). So every join is
 * checked against the space: someone who was removed is sent out again, and
 * only the host and the current speakers may publish (an old speaker token
 * reused after being moved back to listening).
 */
async function enforceSeat(spaceId, participant) {
  const uid = participant && participant.identity;
  if (!uid) return;
  const ref = spaces().doc(spaceId);
  const [snap, removed] = await Promise.all([ref.get(), ref.collection("removed").doc(uid).get()]);
  if (!snap.exists) return;
  if (removed.exists) {
    await roomService().removeParticipant(spaceId, uid).catch(() => {});
    return;
  }
  const s = snap.data();
  const speaker = uid === s.hostUid || (s.speakerUids || []).includes(uid);
  if (!speaker && participant.permission && participant.permission.canPublish) {
    await setCanSpeak(spaceId, uid, false);
  }
}

async function onParticipantLeft(spaceId, participant) {
  const uid = participant.identity;
  if (!uid) return;
  const joinedAt = Number(participant.joinedAt || 0) * 1000;
  const minutes = joinedAt ? Math.max(0, Math.round((Date.now() - joinedAt) / 60000)) : 0;
  await profileRef(uid).set(
    { stats: { joined: FieldValue.increment(1), minutes: FieldValue.increment(minutes) } },
    { merge: true },
  );
  const ref = spaces().doc(spaceId);
  const snap = await ref.get();
  if (snap.exists && snap.get("hostUid") !== uid && snap.get("status") === "live") {
    // People who leave come back as listeners.
    await ref.update({
      speakerUids: FieldValue.arrayRemove(uid),
      invitedUids: FieldValue.arrayRemove(uid),
      hands: FieldValue.arrayRemove(uid),
      ...passTurnFrom(snap.data(), uid),
    });
  }
}

// ---- Housekeeping -------------------------------------------------------------

exports.majlisSweep = onSchedule({ schedule: "every 10 minutes", region: REGION, secrets: SECRETS, serviceAccount: SERVICE_ACCOUNT }, async () => {
  const now = Date.now();
  const live = await spaces().where("status", "==", "live").get();
  for (const doc of live.docs) {
    const away = doc.get("hostAwaySince");
    const started = doc.get("startedAt");
    if ((away && now - away.toMillis() > HOST_AWAY_MS) || (started && now - started.toMillis() > MAX_LIVE_MS)) {
      await closeSpace(doc.ref, "ended");
    } else {
      await refreshRoom(doc.id);
    }
  }
  const missed = await spaces()
    .where("status", "==", "scheduled")
    .where("scheduledFor", "<", Timestamp.fromMillis(now - 60 * 60 * 1000))
    .get();
  for (const doc of missed.docs) await closeSpace(doc.ref, "missed");
});

/** When a WellMate account is deleted, its Majlis data goes too. */
exports.majlisOnUserDeleted = functionsV1
  .region(V1_REGION)
  .runWith({ secrets: ["LIVEKIT_API_KEY", "LIVEKIT_API_SECRET"], serviceAccount: SERVICE_ACCOUNT })
  .auth.user()
  .onDelete(async (user) => {
    const uid = user.uid;
    const hosted = await spaces().where("hostUid", "==", uid).where("status", "in", ["live", "scheduled"]).get();
    for (const doc of hosted.docs) {
      await closeSpace(doc.ref, doc.get("status") === "live" ? "ended" : "cancelled");
    }
    const going = await db.collectionGroup("going").where("uid", "==", uid).get();
    for (const doc of going.docs) {
      const space = doc.ref.parent.parent;
      await db.runTransaction(async (tx) => {
        tx.delete(doc.ref);
        tx.update(space, { goingCount: FieldValue.increment(-1) });
      }).catch(() => {});
    }
    const members = await db.collectionGroup("members").where("uid", "==", uid).get();
    for (const doc of members.docs) await doc.ref.delete().catch(() => {});
    const logs = await db.collection("majlis_whisper_log").where("uid", "==", uid).get();
    for (const doc of logs.docs) await doc.ref.update({ uid: "deleted" });
    await profileRef(uid).delete().catch(() => {});
    await db.doc(`majlis_guides/${uid}`).delete().catch(() => {});
    await db.doc(`majlis_rate/${uid}`).delete().catch(() => {});
  });
