// SPDX-License-Identifier: MIT
.pragma library

// Original silhouettes in a 24 x 24 coordinate space, pointing north.
// Drawn locally with Canvas.Image; no icon font, image downloads or WebGL.
function draw(ctx, type, size, color) {
    ctx.save();
    ctx.scale(size / 24, size / 24);
    ctx.fillStyle = color;
    ctx.strokeStyle = color;
    ctx.lineWidth = 0.7;
    ctx.lineJoin = "round";

    function polygon(points) {
        ctx.beginPath();
        ctx.moveTo(points[0][0], points[0][1]);
        for (let i = 1; i < points.length; ++i) ctx.lineTo(points[i][0], points[i][1]);
        ctx.closePath(); ctx.fill(); ctx.stroke();
    }

    if (type === "uav") {
        polygon([[0,-11],[4,-1],[12,7],[3,5],[0,9],[-3,5],[-12,7],[-4,-1]]);
    } else if (type === "fpv") {
        ctx.strokeStyle = color; ctx.lineWidth = 3;
        ctx.beginPath(); ctx.moveTo(-7,-7); ctx.lineTo(7,7);
        ctx.moveTo(7,-7); ctx.lineTo(-7,7); ctx.stroke();
        ctx.lineWidth = 2;
        for (const x of [-7,7]) for (const y of [-7,7]) {
            ctx.beginPath(); ctx.arc(x,y,4,0,Math.PI*2); ctx.stroke();
        }
        ctx.fillRect(-3,-4,6,8);
    } else if (type === "recon") {
        polygon([[0,-11],[2,-3],[12,0],[12,3],[2,2],[2,8],[6,10],[-6,10],[-2,8],[-2,2],[-12,3],[-12,0],[-2,-3]]);
    } else if (type === "missile") {
        polygon([[0,-12],[3,-7],[3,-1],[10,6],[10,8],[3,5],[3,9],[5,12],[-5,12],[-3,9],[-3,5],[-10,8],[-10,6],[-3,-1],[-3,-7]]);
    } else if (type === "ballistic") {
        polygon([[0,-12],[4,-6],[4,5],[8,10],[3,9],[0,6],[-3,9],[-8,10],[-4,5],[-4,-6]]);
        ctx.strokeStyle = color; ctx.lineWidth = 2;
        ctx.beginPath(); ctx.moveTo(-2,11); ctx.lineTo(-2,14);
        ctx.moveTo(2,11); ctx.lineTo(2,14); ctx.stroke();
    } else if (type === "kab") {
        polygon([[-4,-11],[0,-8],[4,-11],[3,-4],[6,2],[5,7],[0,11],[-5,7],[-6,2],[-3,-4]]);
        ctx.strokeStyle = color; ctx.lineWidth = 2;
        ctx.beginPath(); ctx.moveTo(-10,-1); ctx.lineTo(10,-1); ctx.stroke();
    } else if (type === "mig31k") {
        polygon([[0,-12],[3,-3],[12,6],[12,8],[3,5],[3,8],[7,11],[2,10],[0,7],[-2,10],[-7,11],[-3,8],[-3,5],[-12,8],[-12,6],[-3,-3]]);
    } else {
        polygon([[0,-11],[10,0],[0,11],[-10,0]]);
    }
    ctx.restore();
}

function marker(ctx, threat, x, y, size) {
    const color = threat.advisory ? "#9ad6f7" : "#ffffff";
    ctx.save();
    ctx.translate(x,y);
    // Only reported directions rotate silhouettes; presumed courses are omitted.
    ctx.save();
    if (threat.heading !== null && ["uav","recon","missile","ballistic","mig31k"].includes(threat.type))
        ctx.rotate(threat.heading * Math.PI / 180);
    draw(ctx, threat.type, size, color);
    ctx.restore();
    if (threat.count > 1) {
        ctx.fillStyle = color;
        ctx.font = "600 " + Math.max(8, size * 0.6) + "px sans-serif";
        ctx.textAlign = "center";
        ctx.textBaseline = "top";
        ctx.fillText("×" + threat.count, 0, size / 2 + 2);
    }
    ctx.restore();
}
