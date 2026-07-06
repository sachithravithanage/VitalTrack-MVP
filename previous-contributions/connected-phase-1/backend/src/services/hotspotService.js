import { db } from "../config/firebase.js";
import { generateId } from "../utils/helpers.js";
import { NotFoundError } from "../utils/errors.js";

/**
 * Submit hotspot location data
 */
export async function submitHotspotData(patientId, hotspotData) {
  const dataId = generateId();

  const data = {
    id: dataId,
    patientId,
    subject: hotspotData.subject,
    hometown: hotspotData.hometown,
    workplace: hotspotData.workplace,
    places: hotspotData.places,
    disease: hotspotData.disease || "unknown",
    coordinates: hotspotData.coordinates || null, // { latitude, longitude }
    createdAt: new Date(),
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

export default {
  submitHotspotData,
  getPatientHotspots,
  getHeatmapData,
  getHotspotStats,
  findPotentialHotspots,
  getNearByCases,
};
