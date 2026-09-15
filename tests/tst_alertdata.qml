import QtQuick
import QtTest
import "../package/contents/ui/MapData.js" as Data

TestCase {
    name: "AlertData"

    function geometry(key) {
        return Data.prepareGeometry({type: "FeatureCollection", features: [{
            type: "Feature", properties: {key: key, region: "Test region"},
            geometry: {type: "Polygon", coordinates: [[[29, 49], [31, 49], [31, 51], [29, 49]]]}
        }]});
    }

    function test_raionAndOblastKeysAreSeparate() {
        const model = geometry("test");
        const alerts = Data.parseSnapshot({raions: [{key: "test", level: "yellow"}], oblasts: []}, model, model);
        compare(alerts.raions["@test"], "yellow");
        compare(alerts.oblasts["@test"], undefined);
        compare(alerts.count, 1);
    }

    function test_fullSnapshotClearsEndedAlerts() {
        const model = geometry("test");
        let alerts = Data.parseSnapshot({raions: [{key: "test"}], oblasts: []}, model, model);
        compare(alerts.raions["@test"], "red");
        alerts = Data.parseSnapshot({raions: [], oblasts: []}, model, model);
        compare(alerts.raions["@test"], undefined);
        compare(alerts.count, 0);
    }

    function test_invalidResponsesCannotBecomeAllClear_data() {
        return [
            {tag: "missing-array", payload: {raions: []}},
            {tag: "not-an-array", payload: {raions: {}, oblasts: []}},
            {tag: "unknown-region", payload: {raions: [{key: "missing"}], oblasts: []}},
            {tag: "unknown-level", payload: {raions: [{key: "test", level: "green"}], oblasts: []}}
        ];
    }

    function test_invalidResponsesCannotBecomeAllClear(row) {
        const model = geometry("test");
        let rejected = false;
        try { Data.parseSnapshot(row.payload, model, model); }
        catch (e) { rejected = true; }
        verify(rejected);
    }

    function test_staleDataIsNeverPresentedAsCurrent() {
        verify(Data.isStale(0, 100000, false));
        verify(!Data.isStale(1000, 30000, false));
        verify(Data.isStale(1000, 30000, true));
        verify(Data.isStale(1000, 91000, false));
    }

    function test_multipolygonPreservesIslandsAndHoles() {
        const model = Data.prepareGeometry({type: "FeatureCollection", features: [{
            properties: {key: "islands"}, geometry: {type: "MultiPolygon", coordinates: [
                [[[29, 49], [31, 49], [31, 51], [29, 49]], [[30, 49.5], [30.5, 49.5], [30, 50], [30, 49.5]]],
                [[[32, 49], [33, 49], [33, 50], [32, 49]]]
            ]}
        }]});
        compare(model.regions[0].polygons.length, 2);
        compare(model.regions[0].polygons[0].length, 2);
        compare(model.bounds[0], 29);
        compare(model.bounds[2], 33);
        verify(model.bounds[3] > model.bounds[1]);
    }
}
