import QtQuick

// Sparkline canvas — values: list of numbers 0-100, oldest first (left), newest last (right)
Canvas {
    id: graph

    property var values: []
    property color lineColor: "#4a4a8e"

    // implicitHeight (not height) is what ColumnLayout reads to allocate space
    implicitHeight: 42

    onValuesChanged: requestPaint()
    onWidthChanged:  requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        if (!ctx) return;
        ctx.clearRect(0, 0, width, height);

        if (!values || values.length < 2 || width <= 0) return;

        const n    = values.length;
        const w    = width;
        const h    = height;
        const step = w / (n - 1);

        // Extract RGB from lineColor for gradient construction
        const r = Math.round(lineColor.r * 255);
        const g = Math.round(lineColor.g * 255);
        const b = Math.round(lineColor.b * 255);

        // Y coordinate for a value in [0, 100], with 1px padding at top
        function yOf(v) {
            return h - (Math.min(Math.max(v, 0), 100) / 100) * (h - 3) - 1;
        }

        // ── Filled area under the curve ──────────────────────────────────
        const grad = ctx.createLinearGradient(0, 0, 0, h);
        grad.addColorStop(0, "rgba(" + r + "," + g + "," + b + ",0.28)");
        grad.addColorStop(1, "rgba(" + r + "," + g + "," + b + ",0.0)");

        ctx.beginPath();
        ctx.moveTo(0, h);
        for (let i = 0; i < n; i++) {
            ctx.lineTo(i * step, yOf(values[i]));
        }
        ctx.lineTo((n - 1) * step, h);
        ctx.closePath();
        ctx.fillStyle = grad;
        ctx.fill();

        // ── Stroke ───────────────────────────────────────────────────────
        ctx.beginPath();
        ctx.moveTo(0, yOf(values[0]));
        for (let i = 1; i < n; i++) {
            ctx.lineTo(i * step, yOf(values[i]));
        }
        ctx.strokeStyle = lineColor;
        ctx.lineWidth   = 1.5;
        ctx.lineJoin    = "round";
        ctx.lineCap     = "round";
        ctx.stroke();

        // ── Last-value dot ───────────────────────────────────────────────
        const lx = (n - 1) * step;
        const ly = yOf(values[n - 1]);
        ctx.beginPath();
        ctx.arc(lx, ly, 2.5, 0, Math.PI * 2);
        ctx.fillStyle = lineColor;
        ctx.fill();
    }
}
