// SPDX-License-Identifier: MIT
.pragma library

function project(point) {
    const lon = point[0], lat = point[1];
    if (!Number.isFinite(lon) || !Number.isFinite(lat) || Math.abs(lon) > 180 || Math.abs(lat) >= 85)
        throw new Error("Invalid map coordinate");
    return [lon, -Math.log(Math.tan(Math.PI / 4 + lat * Math.PI / 360)) * 180 / Math.PI];
}

function prepareGeometry(collection) {
    if (!collection || collection.type !== "FeatureCollection" || !Array.isArray(collection.features) || !collection.features.length)
        throw new Error("Invalid map boundaries");
    const bounds = [Infinity, Infinity, -Infinity, -Infinity];
    const keys = {}, regions = [];
    for (const feature of collection.features) {
        const props = feature.properties || {};
        if (typeof props.key !== "string" || !props.key || keys["@" + props.key])
            throw new Error("Missing or duplicate map key");
        keys["@" + props.key] = true;
        const geometry = feature.geometry;
        if (!geometry || !["Polygon", "MultiPolygon"].includes(geometry.type))
            throw new Error("Unsupported map geometry");
        const raw = geometry.type === "Polygon" ? [geometry.coordinates] : geometry.coordinates;
        if (!Array.isArray(raw) || !raw.length) throw new Error("Empty map geometry");
        let labelPoint = null, largestArea = -1;
        const polygons = raw.map(function(polygon) {
            if (!Array.isArray(polygon) || !polygon.length) throw new Error("Empty polygon");
            return polygon.map(function(ring, index) {
                if (!Array.isArray(ring) || ring.length < 4) throw new Error("Invalid polygon ring");
                const points = ring.map(function(p) {
                    const xy = project(p);
                    bounds[0] = Math.min(bounds[0], xy[0]); bounds[1] = Math.min(bounds[1], xy[1]);
                    bounds[2] = Math.max(bounds[2], xy[0]); bounds[3] = Math.max(bounds[3], xy[1]);
                    return xy;
                });
                if (index === 0) {
                    let area = 0, cx = 0, cy = 0;
                    for (let i = 0; i < points.length - 1; ++i) {
                        const a = points[i], b = points[i + 1];
                        const cross = a[0] * b[1] - b[0] * a[1];
                        area += cross; cx += (a[0] + b[0]) * cross; cy += (a[1] + b[1]) * cross;
                    }
                    if (Math.abs(area) > largestArea && Math.abs(area) > 1e-10) {
                        largestArea = Math.abs(area);
                        labelPoint = [cx / (3 * area), cy / (3 * area)];
                    }
                }
                return points;
            });
        });
        if (!labelPoint) throw new Error("Degenerate map geometry");
        const label = (props.region || props.name || props.rayon || props.key)
            .replace(" область", "").replace("Автономна Республіка Крим", "Крим");
        regions.push({key: props.key, label: label, polygons: polygons, center: labelPoint});
    }
    if (bounds[2] <= bounds[0] || bounds[3] <= bounds[1]) throw new Error("Empty map extent");
    return {regions: regions, keys: keys, bounds: bounds};
}

function parseSnapshot(payload, oblasts, raions) {
    if (!payload || !Array.isArray(payload.raions) || !Array.isArray(payload.oblasts))
        throw new Error("Invalid alert response");
    const result = {raions: {}, oblasts: {}, count: 0};
    for (const kind of ["raions", "oblasts"]) {
        const geometry = kind === "raions" ? raions : oblasts;
        for (const entry of payload[kind]) {
            if (!entry || typeof entry.key !== "string" || !geometry.keys["@" + entry.key])
                throw new Error("Alert region missing from map boundaries");
            const level = entry.level === undefined ? "red" : entry.level;
            if (level !== "red" && level !== "yellow") throw new Error("Unknown alert level");
            const key = "@" + entry.key;
            if (!result[kind][key]) ++result.count;
            if (result[kind][key] !== "red") result[kind][key] = level;
        }
    }
    return result;
}

function isStale(lastSuccess, now, failed) {
    return failed || lastSuccess <= 0 || now - lastSuccess >= 90000;
}
