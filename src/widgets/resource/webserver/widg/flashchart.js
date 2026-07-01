function awInsertFlashGraph(divId, dataId, chartType, width, height)
{
    var objId = divId + "_cht";
    var dataEl = ariba.Dom.getElementById(dataId);
    var xml = dataEl ? dataEl.innerHTML.replace(/<!--/g, "").replace(/-->/g, "").replace(/\n/g, "") : "";
    var option = convertFusionXmlToEChartsOption(xml, chartType);

    var container = ariba.Dom.getElementById(divId);
    if (!container) {
        return;
    }

    var chartDiv = ariba.Dom.getElementById(objId);
    if (!chartDiv) {
        container.innerHTML = '<div id="' + objId + '"></div>';
        chartDiv = ariba.Dom.getElementById(objId);
    }

    chartDiv.style.width = parseInt(width, 10) + "px";
    chartDiv.style.height = parseInt(height, 10) + "px";

    var chart = echarts.getInstanceByDom(chartDiv);
    if (chart) {
        chart.setOption(option, true);
    } else {
        echarts.init(chartDiv).setOption(option);
    }
}

// Kept for backward compatibility with old Scatter chart callbacks
function FC_Loaded() { return null; }

function convertFusionXmlToEChartsOption(xml, chartType)
{
    var parser = new DOMParser();
    var doc = parser.parseFromString(xml, "text/xml");
    var root = doc.documentElement;

    var caption = root.getAttribute("caption") || "";
    var xAxisName = root.getAttribute("xAxisName") || "";
    var yAxisName = root.getAttribute("yAxisName") || "";

    var type = (chartType || "").replace(/^FCF_/i, "").replace(/\.swf$/i, "").toLowerCase();

    var sets = root.querySelectorAll ? root.querySelectorAll("set") : [];
    var categories = root.querySelectorAll ? root.querySelectorAll("categories category") : [];
    var datasets = root.querySelectorAll ? root.querySelectorAll("dataset") : [];

    var isPie = type.indexOf("pie") !== -1 || type.indexOf("doughnut") !== -1;
    var isFunnel = type.indexOf("funnel") !== -1;
    var isArea = type.indexOf("area") !== -1;
    var isStacked = type.indexOf("stacked") !== -1;
    var isHorizontal = type.indexOf("bar") !== -1 && type.indexOf("column") === -1;
    var isColumn = type.indexOf("column") !== -1;
    var isComboLineColumn = type.indexOf("linedy") !== -1;

    var option = {
        title: caption ? { text: caption, left: "left" } : null,
        tooltip: {
            trigger: isPie || isFunnel ? "item" : "axis"
        },
        legend: { top: "bottom" },
        grid: { left: 60, right: 30, top: 50, bottom: 70, containLabel: true }
    };

    if (isPie || isFunnel) {
        var data = [];
        var legendNames = [];
        for (var i = 0; i < sets.length; i++) {
            var s = sets[i];
            var label = s.getAttribute("name") || s.getAttribute("label") || "";
            data.push({
                name: label,
                value: parseFloat(s.getAttribute("value")) || 0,
                itemStyle: s.getAttribute("color") ? { color: s.getAttribute("color") } : null
            });
            legendNames.push(label);
        }
        option.legend.data = legendNames;

        if (isFunnel) {
            data.reverse();
            legendNames.reverse();
            option.legend.data = legendNames;
        } else if (isPie) {
            var last = data.pop();
            if (last) {
                data.unshift(last);
                var lastName = legendNames.pop();
                if (lastName) {
                    legendNames.unshift(lastName);
                    option.legend.data = legendNames;
                }
            }
        }

        var isPie3D = type.indexOf("pie3d") !== -1;
        var seriesConfig = {
            type: isFunnel ? "funnel" : "pie",
            radius: type.indexOf("doughnut") !== -1 ? ["40%", "70%"] : "70%",
            sort: isFunnel ? "none" : undefined,
            clockwise: isPie ? false : undefined,
            label: {
                show: true,
                position: isFunnel ? "inside" : "outside",
                formatter: function(params) {
                    return params.name + ", " + Number(params.value).toFixed(2);
                }
            },
            data: data
        };

        if (isPie3D) {
            seriesConfig.roseType = "radius";
            seriesConfig.itemStyle = {
                shadowBlur: 10,
                shadowOffsetX: 4,
                shadowOffsetY: 4,
                shadowColor: "rgba(0,0,0,0.35)"
            };
            for (var idx = 0; idx < data.length; idx++) {
                if (!data[idx].itemStyle || !data[idx].itemStyle.color) {
                    var baseColor = nextChartColor();
                    data[idx].itemStyle = {
                        color: {
                            type: "radial",
                            x: 0.4, y: 0.3, r: 1,
                            colorStops: [
                                { offset: 0, color: lightenColor(baseColor, 0.4) },
                                { offset: 0.5, color: baseColor },
                                { offset: 1, color: darkenColor(baseColor, 0.25) }
                            ]
                        }
                    };
                }
            }
        }

        option.series = [seriesConfig];
        return option;
    }

    // Cartesian charts (line, bar, area, column)
    var categoryNames = [];
    var seriesList = [];
    var legendNames = [];

    var isColumn3D = type.indexOf("column3d") !== -1;
    var useReal3D = isColumn3D && !isStacked && isEChartsGLAvailable();

    if (useReal3D) {
        return createBar3DOption(root, option, type, xAxisName, yAxisName, caption);
    }

    if (datasets.length > 0) {
        // Multi-series: <categories><category name="..."/></categories> + <dataset seriesname="..."><set value="..."/></dataset>
        for (var c = 0; c < categories.length; c++) {
            categoryNames.push(categories[c].getAttribute("name") || categories[c].getAttribute("label") || "");
        }
        for (var d = 0; d < datasets.length; d++) {
            var ds = datasets[d];
            var seriesName = ds.getAttribute("seriesname") || "";
            var dsSets = ds.querySelectorAll ? ds.querySelectorAll("set") : [];
            var seriesData = [];
            for (var j = 0; j < dsSets.length; j++) {
                seriesData.push(parseFloat(dsSets[j].getAttribute("value")) || 0);
            }
            var renderAs = (ds.getAttribute("renderAs") || "").toLowerCase();
            var parentYAxis = (ds.getAttribute("parentYAxis") || "").toLowerCase();
            var isLineSeries = isComboLineColumn && (renderAs === "line" || parentYAxis === "s");
            seriesList.push(createSeries(
                seriesName, seriesData, type, isArea, isStacked,
                ds.getAttribute("color"), isLineSeries ? "line" : null,
                isLineSeries ? 1 : 0
            ));
            if (seriesName) legendNames.push(seriesName);
        }
    } else {
        // Single series: <set name="..." value="..."/>
        for (var k = 0; k < sets.length; k++) {
            categoryNames.push(sets[k].getAttribute("name") || sets[k].getAttribute("label") || "");
        }
        var values = [];
        for (var m = 0; m < sets.length; m++) {
            values.push(parseFloat(sets[m].getAttribute("value")) || 0);
        }
        var seriesName = root.getAttribute("seriesName") || root.getAttribute("seriesname") || "";
        seriesList.push(createSeries(seriesName, values, type, isArea, isStacked, null));
        if (seriesName) legendNames.push(seriesName);
    }

    if (legendNames.length > 0) {
        option.legend.data = legendNames;
    } else {
        option.legend = null;
    }

    var numberPrefixAttr = root.getAttribute("numberPrefix");
    var numberPrefix = (numberPrefixAttr === null) ? "$" : numberPrefixAttr;
    var numberSuffixAttr = root.getAttribute("numberSuffix");
    var numberSuffix = (numberSuffixAttr === null) ? "M" : numberSuffixAttr;
    var decimalsAttr = root.getAttribute("decimals");
    var forceDecimals = root.getAttribute("forceDecimals") === "1";
    var decimals = (decimalsAttr !== null && decimalsAttr !== "") ? parseInt(decimalsAttr, 10) : 2;
    if (isNaN(decimals)) decimals = 2;
    var formatNumber = root.getAttribute("formatNumber") !== "0";

    var fusionNumberFormatter = function (value) {
        if (!formatNumber) return String(value);
        var negative = value < 0;
        var abs = Math.abs(value);
        var scaled = abs;
        if (abs >= 1000000000) {
            scaled = abs / 1000000000;
        } else if (abs >= 1000000) {
            scaled = abs / 1000000;
        } else if (abs >= 1000) {
            scaled = abs / 1000;
        }
        var parts = scaled.toFixed(decimals).split(".");
        var intPart = parts[0];
        var decPart = parts[1] || "";
        intPart = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        var formatted = intPart + (decPart ? "." + decPart : "");
        return (negative ? "-" : "") + numberPrefix + formatted + numberSuffix;
    };

    option.tooltip.formatter = function (params) {
        var fmt = fusionNumberFormatter;
        if (Array.isArray(params)) {
            if (params.length === 0) return "";
            var html = params[0].name + "<br/>";
            for (var i = 0; i < params.length; i++) {
                var p = params[i];
                html += p.marker + " " + p.seriesName + " : " + fmt(p.value) + "<br/>";
            }
            return html;
        } else {
            return params.name + "<br/>" + params.marker + " " + params.seriesName + " : " + fmt(params.value);
        }
    };

    if (isHorizontal) {
        option.xAxis = { type: "value", name: yAxisName, axisLabel: { formatter: fusionNumberFormatter } };
        option.yAxis = { type: "category", name: xAxisName, data: categoryNames, inverse: true };
    } else {
        option.xAxis = { type: "category", name: xAxisName, data: categoryNames };
        if (isComboLineColumn) {
            option.yAxis = [
                { type: "value", name: yAxisName, axisLabel: { formatter: fusionNumberFormatter } },
                { type: "value", name: "", position: "right", axisLabel: { formatter: fusionNumberFormatter } }
            ];
        } else {
            option.yAxis = { type: "value", name: yAxisName, axisLabel: { formatter: fusionNumberFormatter } };
        }
    }

    option.series = seriesList;
    return option;
}

function createSeries(name, data, type, isArea, isStacked, color, forcedType, yAxisIndex)
{
    var seriesType = forcedType || "line";
    if (!forcedType && (type.indexOf("bar") !== -1 || type.indexOf("column") !== -1)) {
        seriesType = "bar";
    }

    var isLine = seriesType === "line";
    var series = {
        name: name || "",
        type: seriesType,
        data: data,
        label: {
            show: seriesType !== "pie" && seriesType !== "funnel" && !isLine,
            position: isLine ? "top" : "inside",
            color: "#000"
        },
        symbol: isLine ? "circle" : "none"
    };

    if (yAxisIndex) {
        series.yAxisIndex = yAxisIndex;
    }

    if (isArea) {
        series.areaStyle = {};
    }
    if (isStacked) {
        series.stack = "total";
    }

    var seriesColor = color || nextChartColor();
    var is3DColumn = seriesType === "bar" && type.indexOf("column3d") !== -1;

    if (is3DColumn) {
        series.itemStyle = {
            color: {
                type: "linear",
                x: 0, y: 0, x2: 1, y2: 0,
                colorStops: [
                    { offset: 0, color: lightenColor(seriesColor, 0.3) },
                    { offset: 0.5, color: seriesColor },
                    { offset: 1, color: darkenColor(seriesColor, 0.2) }
                ]
            },
            borderRadius: [4, 4, 0, 0],
            shadowColor: "rgba(0,0,0,0.3)",
            shadowBlur: 6,
            shadowOffsetX: 3,
            shadowOffsetY: 3
        };
    } else {
        series.itemStyle = { color: seriesColor };
    }

    return series;
}

var _chartColorIndex = 0;
var _chartColors = ["#5470c6", "#91cc75", "#fac858", "#ee6666", "#73c0de", "#3ba272", "#fc8452", "#9a60b4"];

function nextChartColor()
{
    var color = _chartColors[_chartColorIndex % _chartColors.length];
    _chartColorIndex++;
    return color;
}

function lightenColor(hex, percent)
{
    var rgb = hexToRgb(hex);
    if (!rgb) return hex;
    return "rgb(" + Math.min(255, Math.round(rgb.r + (255 - rgb.r) * percent)) + "," +
        Math.min(255, Math.round(rgb.g + (255 - rgb.g) * percent)) + "," +
        Math.min(255, Math.round(rgb.b + (255 - rgb.b) * percent)) + ")";
}

function darkenColor(hex, percent)
{
    var rgb = hexToRgb(hex);
    if (!rgb) return hex;
    return "rgb(" + Math.max(0, Math.round(rgb.r * (1 - percent))) + "," +
        Math.max(0, Math.round(rgb.g * (1 - percent))) + "," +
        Math.max(0, Math.round(rgb.b * (1 - percent))) + ")";
}

function hexToRgb(hex)
{
    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
    } : null;
}

var _echartsGLAvailable = null;
function isEChartsGLAvailable()
{
    if (_echartsGLAvailable !== null) {
        return _echartsGLAvailable;
    }
    if (typeof echarts === "undefined") {
        _echartsGLAvailable = false;
        return false;
    }
    var testDiv = document.createElement("div");
    testDiv.style.cssText = "position:absolute;left:-9999px;top:-9999px;width:1px;height:1px;";
    document.body.appendChild(testDiv);
    var chart = echarts.init(testDiv);
    var available = false;
    try {
        chart.setOption({ series: [{ type: "bar3D", data: [] }] });
        available = true;
    } catch (e) {}
    chart.dispose();
    document.body.removeChild(testDiv);
    _echartsGLAvailable = available;
    return available;
}

function createBar3DOption(root, baseOption, type, xAxisName, yAxisName, caption)
{
    var categories = root.querySelectorAll ? root.querySelectorAll("categories category") : [];
    var datasets = root.querySelectorAll ? root.querySelectorAll("dataset") : [];
    var sets = root.querySelectorAll ? root.querySelectorAll("set") : [];

    var categoryNames = [];
    var seriesNames = [];
    var data = [];
    var legendNames = [];

    if (datasets.length > 0) {
        for (var c = 0; c < categories.length; c++) {
            categoryNames.push(categories[c].getAttribute("name") || categories[c].getAttribute("label") || "");
        }
        for (var d = 0; d < datasets.length; d++) {
            var ds = datasets[d];
            var seriesName = ds.getAttribute("seriesname") || "";
            seriesNames.push(seriesName);
            if (seriesName) legendNames.push(seriesName);
            var dsSets = ds.querySelectorAll ? ds.querySelectorAll("set") : [];
            var seriesColor = ds.getAttribute("color") || nextChartColor();
            for (var j = 0; j < dsSets.length; j++) {
                var value = parseFloat(dsSets[j].getAttribute("value")) || 0;
                data.push({
                    value: [j, d, value],
                    itemStyle: { color: seriesColor }
                });
            }
        }
    } else {
        for (var k = 0; k < sets.length; k++) {
            categoryNames.push(sets[k].getAttribute("name") || sets[k].getAttribute("label") || "");
        }
        var seriesName = root.getAttribute("seriesName") || root.getAttribute("seriesname") || "";
        seriesNames.push(seriesName || "");
        if (seriesName) legendNames.push(seriesName);
        var seriesColor = nextChartColor();
        for (var m = 0; m < sets.length; m++) {
            var value = parseFloat(sets[m].getAttribute("value")) || 0;
            data.push({
                value: [m, 0, value],
                itemStyle: { color: seriesColor }
            });
        }
    }

    var option = {
        title: caption ? { text: caption, left: "center" } : null,
        tooltip: {},
        legend: legendNames.length > 0 ? { data: legendNames, top: "bottom" } : null,
        xAxis3D: { type: "category", name: xAxisName, data: categoryNames },
        yAxis3D: { type: "category", name: yAxisName || "", data: seriesNames },
        zAxis3D: { type: "value" },
        grid3D: {
            boxWidth: 200,
            boxDepth: 80,
            viewControl: {
                alpha: 20,
                beta: 30,
                distance: 300,
                autoRotate: false
            },
            light: {
                main: { intensity: 1.2, shadow: true },
                ambient: { intensity: 0.3 }
            }
        },
        series: [{
            type: "bar3D",
            data: data,
            shading: "lambert",
            label: { show: true, formatter: function(params) { return params.data.value[2]; } }
        }]
    };
    return option;
}
