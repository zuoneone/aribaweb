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

    var option = {
        title: caption ? { text: caption, left: "center" } : null,
        tooltip: { trigger: isPie || isFunnel ? "item" : "axis" },
        legend: { top: "bottom" }
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
        option.series = [{
            type: isFunnel ? "funnel" : "pie",
            radius: type.indexOf("doughnut") !== -1 ? ["40%", "70%"] : "70%",
            label: { show: true, formatter: "{b}: {c}" },
            data: data
        }];
        return option;
    }

    // Cartesian charts (line, bar, area, column)
    var categoryNames = [];
    var seriesList = [];
    var legendNames = [];

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
            seriesList.push(createSeries(seriesName, seriesData, type, isArea, isStacked, ds.getAttribute("color")));
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

    if (isHorizontal) {
        option.xAxis = { type: "value", name: yAxisName };
        option.yAxis = { type: "category", name: xAxisName, data: categoryNames };
    } else {
        option.xAxis = { type: "category", name: xAxisName, data: categoryNames };
        option.yAxis = { type: "value", name: yAxisName };
    }

    option.series = seriesList;
    return option;
}

function createSeries(name, data, type, isArea, isStacked, color)
{
    var seriesType = "line";
    if (type.indexOf("bar") !== -1 || type.indexOf("column") !== -1) {
        seriesType = "bar";
    }

    var labelPosition = (type.indexOf("bar") !== -1 && type.indexOf("column") === -1)
        ? "right" : "top";

    var series = {
        name: name || "",
        type: seriesType,
        data: data,
        label: { show: true, position: labelPosition }
    };

    if (isArea) {
        series.areaStyle = {};
    }
    if (isStacked) {
        series.stack = "total";
    }
    if (color) {
        series.itemStyle = { color: color };
    }

    return series;
}
