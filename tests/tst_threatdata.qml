import QtQuick
import QtTest
import "../package/contents/ui/MapData.js" as Data

TestCase {
    name: "ThreatData"

    function threat(overrides) {
        return Object.assign({id: "one", type: "uav", lat: 50, lon: 30,
                              status: "active", heading: null}, overrides || {});
    }

    function test_typesAndCounts_data() {
        return ["uav", "fpv", "recon", "missile", "ballistic", "kab", "mig31k", "unknown"]
            .map(function(type) { return {tag: type, type: type}; });
    }

    function test_typesAndCounts(row) {
        const result = Data.parseThreats({threats: [threat({type: row.type, count: 3})]});
        compare(result.points.length, 1);
        compare(result.points[0].type, row.type);
        compare(result.points[0].count, 3);
        compare(result.points[0].point, Data.project([30, 50]));
        verify(result.points[0].label.length > 0);
    }

    function test_regionOnlyReportNeverBecomesAPoint() {
        const result = Data.parseThreats({threats: [threat({areaOnly: true,
            region: "Одеська область", heading: 42, advisory: true, type: "mig31k"})]});
        compare(result.points.length, 0);
        compare(result.areas.length, 1);
        compare(result.areas[0].region, "Одеська область");
        compare(result.areas[0].point, null);
        compare(result.areas[0].heading, null);
        verify(result.areas[0].advisory);
    }

    function test_fullSnapshotRemovesFinishedThreats() {
        const result = Data.parseThreats({threats: [threat(), threat({id: "two", status: "stale"}),
            threat({id: "three", status: "resolved"})]});
        compare(result.points.length, 1);
        compare(Data.parseThreats({threats: []}).points.length, 0);
    }

    function test_optionalAndNewProviderFields() {
        const entry = Data.parseThreats({threats: [threat({type: "future-type", heading: -90, count: 0})]}).points[0];
        compare(entry.type, "unknown");
        compare(entry.heading, 270);
        compare(entry.count, 0);
        verify(!entry.advisory);
        verify(!entry.approximate);
        const approximate = Data.parseThreats({threats: [threat({positionQuality: "approx"})]}).points[0];
        verify(approximate.approximate);
        compare(approximate.heading, null);
        const presumed = Data.parseThreats({threats: [threat({heading: 45, presumptiveCourse: true})]}).points[0];
        compare(presumed.heading, null);
    }

    function test_malformedSnapshotIsNotAnEmptyMap_data() {
        return [
            {tag: "missing-array", payload: {}},
            {tag: "bad-coordinate", payload: {threats: [threat({lat: "50"})]}},
            {tag: "coordinate-range", payload: {threats: [threat({lon: 200})]}},
            {tag: "duplicate-id", payload: {threats: [threat(), threat()]}},
            {tag: "unknown-status", payload: {threats: [threat({status: "future"})]}},
            {tag: "bad-area-flag", payload: {threats: [threat({areaOnly: "true"})]}},
            {tag: "missing-region", payload: {threats: [threat({areaOnly: true})]}}
        ];
    }

    function test_malformedSnapshotIsNotAnEmptyMap(row) {
        let rejected = false;
        try { Data.parseThreats(row.payload); }
        catch (e) { rejected = true; }
        verify(rejected);
    }
}
