var app = {}

app.chartholder = d3.select("#chartholder");

app.resize = function() {
  app.windowWidth = window.innerWidth;
  app.isMobile = app.windowWidth <= 767 ? true : false;
  app.drawWinProbChart(app.winProbData);
}

app.drawWinProbChart = function(origData) {
  app.updateDimensionsChart();

  app.data = origData.sort((a, b) => d3.ascending(a.minuterown, b.minuterown))

  app.svg = app.chartholder.append('svg')
    .attr("width", app.width + app.margin.left + app.margin.right)
    .attr("height", app.height + app.margin.top + app.margin.bottom)
  .append("g")
    .attr("transform", "translate(" + app.margin.left + "," + app.margin.top + ")");

  app.xmax = d3.max(app.data, d => d.minuteclean) == 210 ? 210 : 180;

  app.xScale = d3.scaleLinear()
    .domain([1, app.xmax])
    .range([app.margin.left, app.width - app.margin.right]);

  app.xAxis = g => g
      .attr("transform", `translate(0,${app.height - app.margin.bottom})`)
      .call(d3.axisBottom(app.xScale).ticks(app.xmax / 10).tickSizeOuter(0))
      .call(g => g.append("text")
          .attr("x", app.width - app.margin.right)
          .attr("y", -4)
          .attr("fill", "currentColor")
          .attr("font-weight", "bold")
          .attr("text-anchor", "end")
          .text('Minutes'))

  app.yScale = d3.scaleLinear()
    .domain([0, 1])
    .range([app.height - app.margin.bottom, app.margin.top]);

  app.yAxis = g => g
    .attr("transform", `translate(${app.margin.left},0)`)
    .call(d3.axisLeft(app.yScale).ticks(app.height / 40))

  app.svg.append('g').call(app.xAxis);
  app.svg.append('g').call(app.yAxis);

  app.lineDraw = d3.line()
    .x(function(d) { return app.xScale(d.minuteclean) })
    .y(function(d) { return app.yScale(d.predictedprobt1) })

  app.svg.append("path")
     .datum(app.data)
     .attr("fill", "none")
     .attr('stroke', '#666')
     .attr('stroke-width', '3px')
     .attr("d", app.lineDraw);
}

// make chart div responsive to window width
app.updateDimensionsChart = function() {
    // margins for d3 chart
    app.margin = {top: 20, right: 20, bottom: 20, left: 20};

    // width of graphic depends on width of chart div
    app.chartElW = document.getElementById("chartholder").clientWidth;
    app.width = app.chartElW - app.margin.left - app.margin.right;

    // height depends only on mobile
    if (app.isMobile){
        app.height = 600 - app.margin.top - app.margin.bottom;
    } else {
        app.height = 600 - app.margin.top - app.margin.bottom;
    }
}
