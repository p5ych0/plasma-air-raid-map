import QtQuick
import QtTest
import "../package/contents/ui"

TestCase {
    name: "ThreatSource"
    Component { id: sourceComponent; AlertSource { autoRefresh: false } }

    function test_invalidSnapshotPreservesLastValidThreats() {
        const source = createTemporaryObject(sourceComponent, this);
        source.acceptThreats({threats: [{id: "one", type: "kab", lat: 50, lon: 30, status: "active"}]});
        verify(!source.threatsStale);
        let rejected = false;
        try { source.acceptThreats({threats: null}); }
        catch (e) { rejected = true; }
        verify(rejected);
        compare(source.threats.points[0].type, "kab");
        compare(source.threatsUpdateCount, 1);
        source.acceptThreats({threats: []});
        compare(source.threats.points.length, 0);
        compare(source.threatsUpdateCount, 2);
    }

    function test_endpointsHaveIndependentFreshnessAndRecovery() {
        const source = createTemporaryObject(sourceComponent, this);
        source.oblasts = {keys: {}};
        source.raions = {keys: {}};
        source.acceptSnapshot({oblasts: [], raions: []});
        source.acceptThreats({threats: []});
        verify(!source.stale && !source.threatsStale);
        source.threatsError = "HTTP 503";
        verify(source.threatsStale);
        verify(!source.stale);
        source.acceptThreats({threats: []});
        verify(!source.threatsStale);
        source.error = "Network timeout";
        verify(source.stale);
        verify(!source.threatsStale);
        source.now = source.threatsLastSuccess + 90000;
        verify(source.threatsStale);
    }
}
