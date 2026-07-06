import crypto from "crypto";
import jwt from "jsonwebtoken";
import { MongoClient } from "mongodb";
import { config } from "./env.js";

const ARRAY_OP_UNION = "__arrayUnion";
const ARRAY_OP_REMOVE = "__arrayRemove";

let mongoClient = null;
let mongoDb = null;

function getMongoDb() {
  if (!mongoDb) {
    throw new Error("MongoDB is not initialized. Call initDataLayer() first.");
  }
  return mongoDb;
}

export async function initDataLayer() {
  if (mongoDb) {
    return mongoDb;
  }

  mongoClient = new MongoClient(config.mongoUri);
  await mongoClient.connect();
  mongoDb = mongoClient.db(config.mongoDbName);
  await mongoDb.command({ ping: 1 });
  return mongoDb;
}

export async function getDataLayerHealth() {
  if (!mongoDb) {
    return {
      connected: false,
      database: config.mongoDbName,
      reason: "not_initialized",
    };
  }

  try {
    await mongoDb.command({ ping: 1 });
    return {
      connected: true,
      database: config.mongoDbName,
    };
  } catch (error) {
    return {
      connected: false,
      database: config.mongoDbName,
      reason: error.message,
    };
  }
}

function normalizeDocument(doc) {
  if (!doc) {
    return null;
  }
  const { _id, ...rest } = doc;
  return {
    ...rest,
    uid: rest.uid || _id,
  };
}

function resolvePathValue(obj, path) {
  return path.split(".").reduce((acc, key) => (acc == null ? undefined : acc[key]), obj);
}

function setPathValue(obj, path, value) {
  const parts = path.split(".");
  let cursor = obj;
  for (let i = 0; i < parts.length - 1; i += 1) {
    const part = parts[i];
    if (typeof cursor[part] !== "object" || cursor[part] === null) {
      cursor[part] = {};
    }
    cursor = cursor[part];
  }
  cursor[parts[parts.length - 1]] = value;
}

function applyFieldValueOperators(existingDoc, updates) {
  const next = { ...updates };
  for (const [key, value] of Object.entries(updates)) {
    if (value?.__op === ARRAY_OP_UNION) {
      const current = resolvePathValue(existingDoc, key);
      const currentArray = Array.isArray(current) ? [...current] : [];
      for (const item of value.values) {
        if (!currentArray.some((existing) => existing === item)) {
          currentArray.push(item);
        }
      }
      setPathValue(next, key, currentArray);
    } else if (value?.__op === ARRAY_OP_REMOVE) {
      const current = resolvePathValue(existingDoc, key);
      const currentArray = Array.isArray(current) ? [...current] : [];
      const filtered = currentArray.filter(
        (item) => !value.values.some((toRemove) => toRemove === item),
      );
      setPathValue(next, key, filtered);
    }
  }
  return next;
}

function matchesFilter(document, filter) {
  return Object.entries(filter).every(([field, condition]) => {
    const value = resolvePathValue(document, field);
    if (condition && typeof condition === "object" && !Array.isArray(condition)) {
      if ("$in" in condition) {
        return condition.$in.includes(value);
      }
      if ("$ne" in condition) {
        return value !== condition.$ne;
      }
      if ("$gte" in condition) {
        return value >= condition.$gte;
      }
      if ("$elemMatch" in condition && "$eq" in condition.$elemMatch) {
        return Array.isArray(value) && value.includes(condition.$elemMatch.$eq);
      }
      return false;
    }
    return value === condition;
  });
}

class DocumentSnapshot {
  constructor(id, raw, collectionName) {
    this.id = id;
    this._raw = raw;
    this.exists = Boolean(raw);
    this.ref = new DocumentReference(collectionName, id);
  }

  data() {
    return normalizeDocument(this._raw);
  }
}

class QueryDocumentSnapshot extends DocumentSnapshot {}

class QuerySnapshot {
  constructor(docs) {
    this.docs = docs;
    this.empty = docs.length === 0;
  }
}

class DocumentReference {
  constructor(collectionName, id) {
    this.collectionName = collectionName;
    this.id = id;
  }

  async get() {
    const raw = await getMongoDb().collection(this.collectionName).findOne({ _id: this.id });
    return new DocumentSnapshot(this.id, raw, this.collectionName);
  }

  async set(data, options = {}) {
    const collection = getMongoDb().collection(this.collectionName);
    const existing = await collection.findOne({ _id: this.id });
    if (options.merge && existing) {
      const merged = applyFieldValueOperators(existing, data);
      await collection.updateOne({ _id: this.id }, { $set: merged });
      return;
    }
    const payload = {
      _id: this.id,
      ...applyFieldValueOperators(existing || {}, data),
      uid: data.uid || this.id,
    };
    await collection.replaceOne({ _id: this.id }, payload, { upsert: true });
  }

  async update(data) {
    const collection = getMongoDb().collection(this.collectionName);
    const existing = await collection.findOne({ _id: this.id });
    if (!existing) {
      throw new Error(`Document ${this.collectionName}/${this.id} not found`);
    }
    const resolved = applyFieldValueOperators(existing, data);
    await collection.updateOne({ _id: this.id }, { $set: resolved });
  }

  async delete() {
    await getMongoDb().collection(this.collectionName).deleteOne({ _id: this.id });
  }
}

class QueryBuilder {
  constructor(collectionName, conditions = [], sort = null, limitValue = null) {
    this.collectionName = collectionName;
    this.conditions = conditions;
    this.sort = sort;
    this.limitValue = limitValue;
  }

  where(field, operator, value) {
    return new QueryBuilder(
      this.collectionName,
      [...this.conditions, { field, operator, value }],
      this.sort,
      this.limitValue,
    );
  }

  orderBy(field, direction = "asc") {
    return new QueryBuilder(this.collectionName, this.conditions, { field, direction }, this.limitValue);
  }

  limit(value) {
    return new QueryBuilder(this.collectionName, this.conditions, this.sort, value);
  }

  buildFilter() {
    const filter = {};
    for (const condition of this.conditions) {
      const { field, operator, value } = condition;
      if (operator === "==") {
        filter[field] = value;
      } else if (operator === "in") {
        filter[field] = { $in: value };
      } else if (operator === "!=") {
        filter[field] = { $ne: value };
      } else if (operator === ">=") {
        filter[field] = { $gte: value };
      } else if (operator === "array-contains") {
        filter[field] = { $elemMatch: { $eq: value } };
      } else {
        throw new Error(`Unsupported where operator: ${operator}`);
      }
    }
    return filter;
  }

  async get() {
    const filter = this.buildFilter();
    let docs = await getMongoDb().collection(this.collectionName).find(filter).toArray();

    // Fallback matcher to handle any edge conversion behavior consistently.
    docs = docs.filter((doc) => matchesFilter(doc, filter));

    if (this.sort) {
      const direction = this.sort.direction === "desc" ? -1 : 1;
      docs.sort((a, b) => {
        const aValue = resolvePathValue(a, this.sort.field);
        const bValue = resolvePathValue(b, this.sort.field);
        if (aValue === bValue) return 0;
        return aValue > bValue ? direction : -direction;
      });
    }

    if (typeof this.limitValue === "number") {
      docs = docs.slice(0, this.limitValue);
    }

    const snapshots = docs.map(
      (doc) => new QueryDocumentSnapshot(String(doc._id), doc, this.collectionName),
    );
    return new QuerySnapshot(snapshots);
  }
}

class CollectionReference extends QueryBuilder {
  constructor(collectionName) {
    super(collectionName);
    this.collectionName = collectionName;
  }

  doc(id) {
    return new DocumentReference(this.collectionName, id);
  }

  async add(data) {
    const id = crypto.randomUUID();
    const payload = { _id: id, ...data, uid: data.uid || id };
    await getMongoDb().collection(this.collectionName).insertOne(payload);
    return this.doc(id);
  }
}

export const db = {
  collection(name) {
    return new CollectionReference(name);
  },
};

async function findUserByField(field, value) {
  const user = await getMongoDb().collection("users").findOne({ [field]: value });
  if (!user) {
    const error = new Error("User not found");
    error.code = "auth/user-not-found";
    throw error;
  }
  return {
    uid: String(user._id),
    email: user.email || null,
    phoneNumber: user.phone ? `+${user.phone}` : null,
    displayName: user.name || "",
    emailVerified: user.emailVerified === true,
  };
}

export const auth = {
  async verifyIdToken(token) {
    const decoded = jwt.verify(token, config.jwtSecret);
    return {
      uid: decoded.uid,
      email: decoded.email,
      email_verified: decoded.emailVerified === true,
    };
  },
  async getUserByEmail(email) {
    return findUserByField("email", String(email).toLowerCase());
  },
  async getUserByPhoneNumber(phoneNumber) {
    const normalized = String(phoneNumber).replace(/^\+/, "");
    return findUserByField("phone", normalized);
  },
  async createUser(payload) {
    return {
      uid: crypto.randomUUID(),
      ...payload,
    };
  },
  async updateUser(uid) {
    const user = await getMongoDb().collection("users").findOne({ _id: uid });
    return {
      uid,
      email: user?.email || null,
      phoneNumber: user?.phone ? `+${user.phone}` : null,
      displayName: user?.name || "",
    };
  },
  async createCustomToken(uid) {
    const user = await getMongoDb().collection("users").findOne({ _id: uid });
    return jwt.sign(
      {
        uid,
        email: user?.email || null,
        emailVerified: user?.emailVerified === true,
      },
      config.jwtSecret,
      { expiresIn: config.jwtExpire },
    );
  },
};

export const bucket = null;
export const messaging = {
  async send() {
    return `disabled_${Date.now()}`;
  },
};

const admin = {
  firestore: {
    FieldValue: {
      arrayUnion(...values) {
        return { __op: ARRAY_OP_UNION, values };
      },
      arrayRemove(...values) {
        return { __op: ARRAY_OP_REMOVE, values };
      },
    },
  },
};

export default admin;
