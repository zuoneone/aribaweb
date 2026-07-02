function awInsertChart (divId, dataId, chartSource, width, height)
{
    var objId = divId + "_cht";
    var dataElement = ariba.Dom.getElementById(dataId);
    var div = ariba.Dom.getElementById(divId);
    if (!dataElement || !div) {
        return;
    }

    var strXML = awChartDataXml(dataElement);
    div.innerHTML = '<div id="' + objId + '" class="awChart"></div>';

    awRenderSvgChart(objId, strXML, awChartType(chartSource), width, height);
}

function awInsertFlashGraph (divId, dataId, chartSource, width, height)
{
    awInsertChart(divId, dataId, chartSource, width, height);
}

function awChartDataXml (dataElement)
{
    var xml = dataElement.innerHTML || dataElement.textContent || dataElement.innerText || "";
    return xml.replace(/<!--/g, "").replace(/-->/g, "").replace(/\n/g, "");
}

function awChartType (chartSource)
{
    var source = chartSource || "";
    var match = /FCF_([^\/\\?]+)\.swf/i.exec(source);
    if (match) {
        return match[1];
    }
    match = /([^\/\\?]+?)(?:\.[^\/\\?.]+)?(?:\?.*)?$/.exec(source);
    return match && match[1] ? match[1] : "Column2D";
}

function awRenderSvgChart (objId, strXML, chartType, width, height)
{
    var container = ariba.Dom.getElementById(objId);
    if (!container) {
        return;
    }

    width = parseInt(width, 10) || 480;
    height = parseInt(height, 10) || 320;

    var graph = awParseChartXml(strXML);
    if (!graph) {
        container.innerHTML = '<div class="awChartMessage">Unable to load chart data.</div>';
        return;
    }

    container.style.width = width + "px";
    container.style.height = height + "px";
    container.innerHTML = "";

    var svg = awSvg("svg", {
        width: width,
        height: height,
        viewBox: "0 0 " + width + " " + height,
        role: "img",
        "aria-label": "Chart"
    });
    svg.style.display = "block";
    svg.style.background = "#ffffff";
    svg.style.fontFamily = "Arial, Helvetica, sans-serif";
    container.appendChild(svg);

    chartType = chartType || "Column2D";
    if (/pie|doughnut/i.test(chartType)) {
        awDrawPieChart(svg, graph, width, height, /doughnut/i.test(chartType));
    }
    else if (/line/i.test(chartType)) {
        awDrawCartesianChart(svg, graph, chartType, width, height, true);
    }
    else if (/bar/i.test(chartType)) {
        awDrawCartesianChart(svg, graph, chartType, width, height, false, true);
    }
    else {
        awDrawCartesianChart(svg, graph, chartType, width, height, false);
    }
}

function awParseChartXml (strXML)
{
    var parser = new DOMParser();
    var doc = parser.parseFromString(strXML, "text/xml");
    if (doc.getElementsByTagName("parsererror").length) {
        return null;
    }

    var graphNode = doc.getElementsByTagName("graph")[0] || doc.documentElement;
    var graph = {
        attrs: awAttrs(graphNode),
        labels: [],
        single: [],
        series: []
    };

    var categoryNodes = graphNode.getElementsByTagName("category");
    for (var i = 0; i < categoryNodes.length; i++) {
        graph.labels.push(awAttr(categoryNodes[i], "name") || awAttr(categoryNodes[i], "label") || "");
    }

    var datasetNodes = graphNode.getElementsByTagName("dataset");
    for (var d = 0; d < datasetNodes.length; d++) {
        var datasetNode = datasetNodes[d];
        var setNodes = datasetNode.getElementsByTagName("set");
        var series = {
            name: awAttr(datasetNode, "seriesname") || awAttr(datasetNode, "name") || "",
            color: awColor(awAttr(datasetNode, "color"), d),
            values: []
        };
        for (var s = 0; s < setNodes.length; s++) {
            series.values.push(awNumber(awAttr(setNodes[s], "value")));
        }
        graph.series.push(series);
    }

    if (!graph.series.length) {
        var directSets = [];
        for (var child = graphNode.firstChild; child; child = child.nextSibling) {
            if (child.nodeType == 1 && child.nodeName.toLowerCase() == "set") {
                directSets.push(child);
            }
        }
        for (var j = 0; j < directSets.length; j++) {
            graph.single.push({
                label: awAttr(directSets[j], "name") || awAttr(directSets[j], "label") || "",
                value: awNumber(awAttr(directSets[j], "value")),
                color: awColor(awAttr(directSets[j], "color"), j)
            });
        }
        if (!graph.labels.length) {
            for (var k = 0; k < graph.single.length; k++) {
                graph.labels.push(graph.single[k].label);
            }
        }
        graph.series.push({
            name: "",
            color: null,
            values: graph.single.map(function (item) { return item.value; })
        });
    }

    return graph;
}

function awDrawCartesianChart (svg, graph, chartType, width, height, lineChart, horizontal)
{
    var margin = { top: 24, right: 24, bottom: 54, left: 58 };
    var plotW = Math.max(10, width - margin.left - margin.right);
    var plotH = Math.max(10, height - margin.top - margin.bottom);
    var labels = graph.labels;
    var series = graph.series;
    var stacked = /stacked/i.test(chartType);
    var max = awMaxValue(series, stacked);
    var min = 0;

    awDrawGrid(svg, margin, plotW, plotH, min, max, horizontal);

    if (horizontal) {
        awDrawBars(svg, graph, margin, plotW, plotH, max, true, stacked);
    }
    else if (lineChart) {
        awDrawLines(svg, graph, margin, plotW, plotH, max);
    }
    else {
        awDrawBars(svg, graph, margin, plotW, plotH, max, false, stacked);
    }

    awDrawLegend(svg, series, width, margin);
    awDrawAxes(svg, margin, plotW, plotH);
}

function awDrawGrid (svg, margin, plotW, plotH, min, max, horizontal)
{
    var ticks = 4;
    for (var i = 0; i <= ticks; i++) {
        var ratio = i / ticks;
        var y = margin.top + plotH - (plotH * ratio);
        var x = margin.left + (plotW * ratio);
        if (horizontal) {
            awAppend(svg, "line", {
                x1: x,
                y1: margin.top,
                x2: x,
                y2: margin.top + plotH,
                stroke: "#e4e7eb",
                "stroke-width": 1
            });
        }
        else {
            awAppend(svg, "line", {
                x1: margin.left,
                y1: y,
                x2: margin.left + plotW,
                y2: y,
                stroke: "#e4e7eb",
                "stroke-width": 1
            });
        }
        awAppend(svg, "text", {
            x: horizontal ? x : margin.left - 8,
            y: horizontal ? margin.top + plotH + 18 : y + 4,
            "text-anchor": horizontal ? "middle" : "end",
            fill: "#5f6b7a",
            "font-size": 11
        }, awFormatNumber(max * ratio));
    }
}

function awDrawAxes (svg, margin, plotW, plotH)
{
    awAppend(svg, "path", {
        d: "M" + margin.left + " " + margin.top + "V" + (margin.top + plotH) + "H" + (margin.left + plotW),
        fill: "none",
        stroke: "#9aa4b2",
        "stroke-width": 1
    });
}

function awDrawBars (svg, graph, margin, plotW, plotH, max, horizontal, stacked)
{
    var labels = graph.labels;
    var series = graph.series;
    var groups = Math.max(labels.length, series[0] ? series[0].values.length : 0);
    var groupSize = (horizontal ? plotH : plotW) / Math.max(groups, 1);
    var gap = Math.min(16, groupSize * 0.22);
    var seriesCount = stacked ? 1 : Math.max(series.length, 1);
    var barSize = Math.max(2, (groupSize - gap) / seriesCount);

    for (var g = 0; g < groups; g++) {
        var label = labels[g] || "";
        var offset = groupSize * g + gap / 2;
        var stackedBase = 0;
        awDrawCategoryLabel(svg, label, margin, plotW, plotH, offset + groupSize / 2, horizontal);

        for (var s = 0; s < series.length; s++) {
            var value = series[s].values[g] || 0;
            var color = awSeriesColor(graph, series[s], s, g);
            if (horizontal) {
                var x = margin.left + (stackedBase / max) * plotW;
                var w = Math.max(0, (value / max) * plotW);
                var y = margin.top + offset + (stacked ? 0 : s * barSize);
                awAppend(svg, "rect", awBarAttrs(x, y, w, Math.max(2, barSize - 2), color));
            }
            else {
                var h = Math.max(0, (value / max) * plotH);
                var bx = margin.left + offset + (stacked ? 0 : s * barSize);
                var by = margin.top + plotH - h - ((stackedBase / max) * plotH);
                awAppend(svg, "rect", awBarAttrs(bx, by, Math.max(2, barSize - 2), h, color));
            }
            if (stacked) {
                stackedBase += value;
            }
        }
    }
}

function awDrawCategoryLabel (svg, label, margin, plotW, plotH, offset, horizontal)
{
    if (horizontal) {
        awAppend(svg, "text", {
            x: margin.left - 8,
            y: margin.top + offset + 4,
            "text-anchor": "end",
            fill: "#344054",
            "font-size": 11
        }, awShortLabel(label));
    }
    else {
        awAppend(svg, "text", {
            x: margin.left + offset,
            y: margin.top + plotH + 18,
            "text-anchor": "middle",
            fill: "#344054",
            "font-size": 11
        }, awShortLabel(label));
    }
}

function awDrawLines (svg, graph, margin, plotW, plotH, max)
{
    var labels = graph.labels;
    var series = graph.series;
    var groups = Math.max(labels.length, series[0] ? series[0].values.length : 0);
    var step = groups > 1 ? plotW / (groups - 1) : plotW;

    for (var g = 0; g < groups; g++) {
        awDrawCategoryLabel(svg, labels[g] || "", margin, plotW, plotH, g * step, false);
    }

    for (var s = 0; s < series.length; s++) {
        var points = [];
        for (var i = 0; i < groups; i++) {
            var x = margin.left + (groups > 1 ? i * step : plotW / 2);
            var y = margin.top + plotH - ((series[s].values[i] || 0) / max) * plotH;
            points.push(x + "," + y);
            awAppend(svg, "circle", {
                cx: x,
                cy: y,
                r: 3,
                fill: awSeriesColor(graph, series[s], s, i),
                stroke: "#fff",
                "stroke-width": 1
            });
        }
        awAppend(svg, "polyline", {
            points: points.join(" "),
            fill: "none",
            stroke: awSeriesColor(graph, series[s], s, 0),
            "stroke-width": 2
        });
    }
}

function awDrawPieChart (svg, graph, width, height, doughnut)
{
    var items = graph.single.length ? graph.single : [];
    if (!items.length && graph.series[0]) {
        for (var i = 0; i < graph.series[0].values.length; i++) {
            items.push({
                label: graph.labels[i] || "",
                value: graph.series[0].values[i],
                color: awColor(null, i)
            });
        }
    }

    var total = 0;
    for (var t = 0; t < items.length; t++) {
        total += Math.max(0, items[t].value);
    }
    if (!total) {
        total = 1;
    }

    var cx = Math.floor(width * 0.42);
    var cy = Math.floor(height * 0.48);
    var r = Math.max(30, Math.min(width * 0.26, height * 0.34));
    var angle = -Math.PI / 2;
    for (var s = 0; s < items.length; s++) {
        var slice = Math.max(0, items[s].value) / total * Math.PI * 2;
        if (slice >= Math.PI * 2) {
            awAppend(svg, "circle", {
                cx: cx,
                cy: cy,
                r: r,
                fill: items[s].color,
                stroke: "#fff",
                "stroke-width": 1
            });
        }
        else {
            var path = awArcPath(cx, cy, r, angle, angle + slice);
            awAppend(svg, "path", {
                d: path,
                fill: items[s].color,
                stroke: "#fff",
                "stroke-width": 1
            });
        }
        angle += slice;
    }

    if (doughnut) {
        awAppend(svg, "circle", {
            cx: cx,
            cy: cy,
            r: Math.max(12, r * 0.48),
            fill: "#fff"
        });
    }

    awDrawLegend(svg, items.map(function (item) {
        return { name: item.label, color: item.color };
    }), width, { top: 24, right: 24 });
}

function awDrawLegend (svg, series, width, margin)
{
    var x = width - (margin.right || 24) - 120;
    var y = margin.top || 20;
    for (var i = 0; i < series.length && i < 8; i++) {
        var name = series[i].name;
        if (!name && series.length == 1) {
            continue;
        }
        awAppend(svg, "rect", {
            x: x,
            y: y + i * 18,
            width: 10,
            height: 10,
            fill: series[i].color || awColor(null, i)
        });
        awAppend(svg, "text", {
            x: x + 16,
            y: y + 9 + i * 18,
            fill: "#344054",
            "font-size": 11
        }, awShortLabel(name));
    }
}

function awBarAttrs (x, y, width, height, color)
{
    return {
        x: x,
        y: y,
        width: width,
        height: height,
        fill: color,
        stroke: "#ffffff",
        "stroke-width": 1
    };
}

function awArcPath (cx, cy, r, start, end)
{
    var x1 = cx + r * Math.cos(start);
    var y1 = cy + r * Math.sin(start);
    var x2 = cx + r * Math.cos(end);
    var y2 = cy + r * Math.sin(end);
    var large = (end - start) > Math.PI ? 1 : 0;
    return "M" + cx + " " + cy + "L" + x1 + " " + y1 + "A" + r + " " + r +
        " 0 " + large + " 1 " + x2 + " " + y2 + "Z";
}

function awMaxValue (series, stacked)
{
    var max = 0;
    if (stacked) {
        var groups = series[0] ? series[0].values.length : 0;
        for (var g = 0; g < groups; g++) {
            var total = 0;
            for (var s = 0; s < series.length; s++) {
                total += Math.max(0, series[s].values[g] || 0);
            }
            max = Math.max(max, total);
        }
    }
    else {
        for (var i = 0; i < series.length; i++) {
            for (var j = 0; j < series[i].values.length; j++) {
                max = Math.max(max, series[i].values[j] || 0);
            }
        }
    }
    return max || 1;
}

function awSeriesColor (graph, series, seriesIndex, itemIndex)
{
    if (graph.single.length && graph.single[itemIndex]) {
        return graph.single[itemIndex].color;
    }
    return series.color || awColor(null, seriesIndex);
}

function awColor (color, index)
{
    var colors = [
        "#4f7dd5", "#7fbe45", "#6b6f93", "#f2a541",
        "#6ba368", "#dbc84f", "#8c80d9", "#5a67d8",
        "#d65db1", "#229ad6", "#8f9aa8"
    ];
    if (color) {
        return color.charAt(0) == "#" ? color : "#" + color;
    }
    return colors[index % colors.length];
}

function awAttrs (node)
{
    var attrs = {};
    if (!node || !node.attributes) {
        return attrs;
    }
    for (var i = 0; i < node.attributes.length; i++) {
        attrs[node.attributes[i].name] = node.attributes[i].value;
    }
    return attrs;
}

function awAttr (node, name)
{
    return node && node.getAttribute ? node.getAttribute(name) : null;
}

function awNumber (value)
{
    var number = parseFloat((value || "0").toString().replace(/[^0-9.\-]/g, ""));
    return isNaN(number) ? 0 : number;
}

function awFormatNumber (value)
{
    if (Math.abs(value) >= 1000000) {
        return Math.round(value / 100000) / 10 + "M";
    }
    if (Math.abs(value) >= 1000) {
        return Math.round(value / 100) / 10 + "K";
    }
    return Math.round(value * 100) / 100;
}

function awShortLabel (label)
{
    label = (label == null) ? "" : String(label);
    return label.length > 16 ? label.substring(0, 15) + "..." : label;
}

function awSvg (name, attrs)
{
    var element = document.createElementNS("http://www.w3.org/2000/svg", name);
    for (var key in attrs) {
        element.setAttribute(key, attrs[key]);
    }
    return element;
}

function awAppend (parent, name, attrs, text)
{
    var element = awSvg(name, attrs || {});
    if (text != null) {
        element.appendChild(document.createTextNode(text));
    }
    parent.appendChild(element);
    return element;
}

// For compatibility with old Scatter chart.
function FC_Loaded() { return null; }
