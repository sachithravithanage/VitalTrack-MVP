import { db } from "../config/dataLayer.js";
import { generateId } from "../utils/helpers.js";
import { AuthorizationError, ValidationError } from "../utils/errors.js";

const SRI_LANKA_DISTRICTS = [
  "ampara",
  "anuradhapura",
  "badulla",
  "batticaloa",
  "colombo",
  "galle",
  "gampaha",
  "hambantota",
  "jaffna",
  "kalutara",
  "kandy",
  "kegalle",
  "kilinochchi",
  "kurunegala",
  "mannar",
  "matale",
  "matara",
  "monaragala",
  "mullaitivu",
  "nuwara eliya",
  "polonnaruwa",
  "puttalam",
  "ratnapura",
  "trincomalee",
  "vavuniya",
];

const DISTRICT_KEYWORDS = {
  ampara: ["ampara", "ampaarai"],
  anuradhapura: ["anuradhapura"],
  badulla: ["badulla"],
  batticaloa: ["batticaloa", "mattakalappu"],
  colombo: ["colombo", "kolamba"],
  galle: ["galle", "gaala"],
  gampaha: ["gampaha"],
  hambantota: ["hambantota"],
  jaffna: ["jaffna", "yaal", "yapanaya", "yarl"],
  kalutara: ["kalutara"],
  kandy: ["kandy", "maha nuwara"],
  kegalle: ["kegalle", "kegalla"],
  kilinochchi: ["kilinochchi", "kilinochi"],
  kurunegala: ["kurunegala", "kurunagala"],
  mannar: ["mannar", "mannaram"],
  matale: ["matale", "mathale"],
  matara: ["matara"],
  monaragala: ["monaragala", "monaragala"],
  mullaitivu: ["mullaitivu", "mullaittivu"],
  "nuwara eliya": ["nuwara eliya", "nuwaraeliya", "nuwara"],
  polonnaruwa: ["polonnaruwa", "polonnaruva"],
  puttalam: ["puttalam", "putlam"],
  ratnapura: ["ratnapura", "rathnapura"],
  trincomalee: ["trincomalee", "trinco", "thirukonamalai"],
  vavuniya: ["vavuniya", "vavniya"],
};

const PLACE_WEIGHTS = {
  hometown: 1,
  workplace: 0.8,
  visit: 0.6,
};

const RECENCY_WEIGHTS = [1, 0.8, 0.6, 0.4];

/**
 * Submit hotspot location data
 */
export async function submitHotspotData(patientId, hotspotData) {
  if (!hotspotData.hometown || String(hotspotData.hometown).trim().length < 2) {
    throw new ValidationError("Hometown is required");
  }

  const dataId = generateId();
  const now = new Date();

  const normalizedPlaces = splitPlaces(hotspotData.places);
  const placeRegions = {
    hometown: toRegion(hotspotData.hometown),
    workplace: toRegion(hotspotData.workplace),
    visits: normalizedPlaces.map((place) => toRegion(place)),
  };

  const data = {
    id: dataId,
    patientId,
    subject: hotspotData.subject,
    subjectPatientId: hotspotData.subjectPatientId || patientId,
    submittedBy: hotspotData.submittedBy || patientId,
    submittedByRole: hotspotData.submittedByRole || "patient",
    hometown: hotspotData.hometown,
    workplace: hotspotData.workplace,
    places: normalizedPlaces.join(", "),
    placeRegions,
    disease: hotspotData.disease || "unknown",
    coordinates: hotspotData.coordinates || null, // { latitude, longitude }
    createdAt: now,
  };

  await db.collection("hotspotData").doc(dataId).set(data);

  return data;
}

/**
 * Get hotspot data for a patient
 */
export async function getPatientHotspots(patientId) {
  const snapshot = await db
    .collection("hotspotData")
    .where("patientId", "==", patientId)
    .orderBy("createdAt", "desc")
    .get();

  return snapshot.docs.map((doc) => doc.data());
}

/**
 * Get heatmap data for a geographic area
 * Returns aggregated hotspot data for map visualization
 */
export async function getHeatmapData(bounds = null, disease = null) {
  let query = db.collection("hotspotData");

  if (disease) {
    query = query.where("disease", "==", disease);
  }

  const snapshot = await query.get();

  const heatmapData = [];

  snapshot.forEach((doc) => {
    const data = doc.data();

    // Add hotspot coordinates if available
    if (data.coordinates?.latitude && data.coordinates?.longitude) {
      heatmapData.push({
        ...data,
        type: "point",
      });
    }

    // Also add location names as searchable hotspots
    const locations = [
      { name: data.hometown, type: "hometown" },
      { name: data.workplace, type: "workplace" },
      ...(data.places?.split(",").map((place, i) => ({
        name: place.trim(),
        type: "visit",
      })) || []),
    ];

    locations.forEach((location) => {
      if (location.name && location.name.trim()) {
        heatmapData.push({
          ...data,
          locationName: location.name,
          locationType: location.type,
          type: "location",
        });
      }
    });
  });

  return heatmapData;
}

/**
 * Get regional heatmap summary for Sri Lanka districts
 */
export async function getRegionalHeatmapData(disease = null) {
  let query = db.collection("hotspotData");

  if (disease) {
    query = query.where("disease", "==", disease);
  }

  const snapshot = await query.get();

  const districtAgg = new Map();
  for (const district of SRI_LANKA_DISTRICTS) {
    districtAgg.set(district, {
      district,
      score: 0,
      totalEvents: 0,
      hometownCount: 0,
      workplaceCount: 0,
      visitCount: 0,
      uniquePatients: new Set(),
    });
  }

  snapshot.forEach((doc) => {
    const row = doc.data();
    const createdAt = toDate(row.createdAt);
    const recencyWeight = getRecencyWeight(createdAt);

    const regions = row.placeRegions || {
      hometown: toRegion(row.hometown),
      workplace: toRegion(row.workplace),
      visits: splitPlaces(row.places).map((place) => toRegion(place)),
    };

    addRegionEvent(
      districtAgg,
      regions.hometown,
      PLACE_WEIGHTS.hometown * recencyWeight,
      "hometownCount",
      row.subjectPatientId || row.patientId,
    );
    addRegionEvent(
      districtAgg,
      regions.workplace,
      PLACE_WEIGHTS.workplace * recencyWeight,
      "workplaceCount",
      row.subjectPatientId || row.patientId,
    );
    for (const visitDistrict of regions.visits || []) {
      addRegionEvent(
        districtAgg,
        visitDistrict,
        PLACE_WEIGHTS.visit * recencyWeight,
        "visitCount",
        row.subjectPatientId || row.patientId,
      );
    }
  });

  const regions = Array.from(districtAgg.values()).map((item) => {
    const patients = item.uniquePatients.size;
    const level = determineRiskLevel(item.score);
    return {
      district: item.district,
      score: Number(item.score.toFixed(2)),
      riskLevel: level,
      totalEvents: item.totalEvents,
      hometownCount: item.hometownCount,
      workplaceCount: item.workplaceCount,
      visitCount: item.visitCount,
      patients,
    };
  });

  const hotspots = regions
    .filter((item) => item.totalEvents > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, 10);

  return {
    regions,
    hotspots,
    lastUpdatedAt: new Date().toISOString(),
  };
}

/**
 * Get hotspot statistics
 */
export async function getHotspotStats(patientId) {
  const hotspots = await getPatientHotspots(patientId);

  if (hotspots.length === 0) {
    return {
      totalSubmissions: 0,
      diseases: {},
      commonLocations: [],
    };
  }

  const diseases = {};
  const locations = {};

  hotspots.forEach((hotspot) => {
    // Count diseases
    if (hotspot.disease) {
      diseases[hotspot.disease] = (diseases[hotspot.disease] || 0) + 1;
    }

    // Count locations
    const allPlaces = [
      hotspot.hometown,
      hotspot.workplace,
      ...(hotspot.places?.split(",").map((p) => p.trim()) || []),
    ].filter(Boolean);

    allPlaces.forEach((place) => {
      locations[place] = (locations[place] || 0) + 1;
    });
  });

  // Get top locations
  const commonLocations = Object.entries(locations)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([name, count]) => ({ name, count }));

  return {
    totalSubmissions: hotspots.length,
    diseases,
    commonLocations,
  };
}

/**
 * Find potential hotspots (high-frequency locations with disease cases)
 */
export async function findPotentialHotspots(disease = null, minCases = 3) {
  const allData = await getHeatmapData(null, disease);

  const locationCases = {};

  allData.forEach((data) => {
    if (data.type === "location" && data.locationType === "visit") {
      const location = data.locationName;
      if (!locationCases[location]) {
        locationCases[location] = [];
      }
      locationCases[location].push(data);
    }
  });

  // Filter locations with minimum cases
  const potentialHotspots = Object.entries(locationCases)
    .filter(([location, cases]) => cases.length >= minCases)
    .map(([location, cases]) => ({
      location,
      caseCount: cases.length,
      diseases: [...new Set(cases.map((c) => c.disease))],
      coordinates: cases[0].coordinates, // Use first case's coordinates if available
    }));

  return potentialHotspots.sort((a, b) => b.caseCount - a.caseCount);
}

/**
 * Get nearby cases (within radius)
 */
export async function getNearByCases(latitude, longitude, radiusKm = 5) {
  const allData = await getHeatmapData();

  const nearbyCases = allData.filter((data) => {
    if (!data.coordinates?.latitude || !data.coordinates?.longitude) {
      return false;
    }

    const distance = calculateDistance(
      latitude,
      longitude,
      data.coordinates.latitude,
      data.coordinates.longitude,
    );

    return distance <= radiusKm;
  });

  return nearbyCases.sort((a, b) => {
    const distA = calculateDistance(
      latitude,
      longitude,
      a.coordinates.latitude,
      a.coordinates.longitude,
    );
    const distB = calculateDistance(
      latitude,
      longitude,
      b.coordinates.latitude,
      b.coordinates.longitude,
    );
    return distA - distB;
  });
}

/**
 * Calculate distance between two coordinates using Haversine formula
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in kilometers
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(degrees) {
  return degrees * (Math.PI / 180);
}

function splitPlaces(placesValue) {
  if (!placesValue) {
    return [];
  }

  if (Array.isArray(placesValue)) {
    return placesValue
      .map((place) => String(place || "").trim())
      .filter((place) => place.length > 0);
  }

  return String(placesValue)
    .split(",")
    .map((place) => place.trim())
    .filter((place) => place.length > 0);
}

function toRegion(rawValue) {
  if (!rawValue) {
    return null;
  }

  const normalized = String(rawValue)
    .toLowerCase()
    .replace(/[^a-z\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  if (!normalized) {
    return null;
  }

  const compactNormalized = normalized.replace(/\s+/g, "");

  // 1) Exact alias match (strongest and deterministic)
  for (const district of SRI_LANKA_DISTRICTS) {
    const keywords = DISTRICT_KEYWORDS[district] || [district];
    if (
      keywords.some(
        (keyword) => compactNormalized === String(keyword).replace(/\s+/g, ""),
      )
    ) {
      return district;
    }
  }

  // 2) Word-boundary alias match (prevents "kegalle" matching "galle")
  const boundaryCandidates = [];
  for (const district of SRI_LANKA_DISTRICTS) {
    const keywords = DISTRICT_KEYWORDS[district] || [district];
    for (const keyword of keywords) {
      const normalizedKeyword = String(keyword).trim().toLowerCase();
      const boundaryRegex = new RegExp(
        `(^|\\s)${escapeRegExp(normalizedKeyword)}($|\\s)`,
      );
      if (boundaryRegex.test(normalized)) {
        boundaryCandidates.push({
          district,
          keywordLength: normalizedKeyword.length,
        });
      }
    }
  }

  if (boundaryCandidates.length > 0) {
    boundaryCandidates.sort((a, b) => b.keywordLength - a.keywordLength);
    return boundaryCandidates[0].district;
  }

  // 3) Conservative fuzzy fallback for small typos only
  let bestDistrict = null;
  let bestDistance = Infinity;

  for (const district of SRI_LANKA_DISTRICTS) {
    const keywords = DISTRICT_KEYWORDS[district] || [district];
    for (const keyword of keywords) {
      const candidate = String(keyword).replace(/\s+/g, "");
      const distance = levenshteinDistance(compactNormalized, candidate);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestDistrict = district;
      }
    }
  }

  if (bestDistance <= 2) {
    return bestDistrict;
  }

  return null;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function levenshteinDistance(a, b) {
  if (a === b) {
    return 0;
  }
  if (a.length === 0) {
    return b.length;
  }
  if (b.length === 0) {
    return a.length;
  }

  const matrix = Array.from({ length: a.length + 1 }, () =>
    Array(b.length + 1).fill(0),
  );

  for (let i = 0; i <= a.length; i += 1) {
    matrix[i][0] = i;
  }
  for (let j = 0; j <= b.length; j += 1) {
    matrix[0][j] = j;
  }

  for (let i = 1; i <= a.length; i += 1) {
    for (let j = 1; j <= b.length; j += 1) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      matrix[i][j] = Math.min(
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost,
      );
    }
  }

  return matrix[a.length][b.length];
}

function toDate(value) {
  if (!value) {
    return new Date();
  }
  if (value instanceof Date) {
    return value;
  }
  if (typeof value.toDate === "function") {
    return value.toDate();
  }
  return new Date(value);
}

function getRecencyWeight(date) {
  const now = new Date();
  const dayDiff = Math.floor(
    (now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24),
  );
  if (dayDiff < 0) {
    return RECENCY_WEIGHTS[0];
  }
  if (dayDiff >= RECENCY_WEIGHTS.length) {
    return 0.2;
  }
  return RECENCY_WEIGHTS[dayDiff];
}

function addRegionEvent(aggMap, district, weightedScore, countKey, patientId) {
  if (!district || !aggMap.has(district)) {
    return;
  }

  const row = aggMap.get(district);
  row.score += weightedScore;
  row.totalEvents += 1;
  row[countKey] += 1;
  if (patientId) {
    row.uniquePatients.add(String(patientId));
  }
}

function determineRiskLevel(score) {
  if (score >= 8) {
    return "critical";
  }
  if (score >= 4) {
    return "high";
  }
  if (score >= 2) {
    return "medium";
  }
  return "low";
}

export async function validateCaregiverPatientAccess(caregiverId, patientId) {
  const relationships = await db
    .collection("relationships")
    .where("caregiverId", "==", caregiverId)
    .where("patientId", "==", patientId)
    .get();

  const hasAccess = relationships.docs.some(
    (doc) => String(doc.data().status || "active") === "active",
  );

  if (!hasAccess) {
    throw new AuthorizationError(
      "Caregiver does not have access to this patient",
    );
  }

  return true;
}

export default {
  submitHotspotData,
  getPatientHotspots,
  getHeatmapData,
  getRegionalHeatmapData,
  getHotspotStats,
  findPotentialHotspots,
  getNearByCases,
  validateCaregiverPatientAccess,
};
