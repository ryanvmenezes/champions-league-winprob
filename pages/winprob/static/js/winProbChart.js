var app = {}

app.chartholder = d3.select("#chartholder");

app.resize = function() {
  app.windowWidth = window.innerWidth;
  app.isMobile = app.windowWidth <= 767 ? true : false;
  app.drawWinProbChart();
}

app.drawWinProbChart = function() {
  app.updateDimensionsChart();

  app.data = app.winProbData.sort((a, b) => d3.ascending(a.minuterown, b.minuterown));

  d3.select('#chartholder svg').remove();

  app.svg = app.chartholder.append('svg')
    .attr("width", app.width + app.margin.left + app.margin.right)
    .attr("height", app.height + app.margin.top + app.margin.bottom)
  .append("g")
    .attr("transform", "translate(" + app.margin.left + "," + app.margin.top + ")");

  app.aet = d3.max(app.data, d => d.minuteclean) == 210;
  app.xmax = app.aet ? 210 : 180;

  app.xScale = d3.scaleLinear()
    .domain([-5, app.xmax + 5])
    .range([app.margin.left, app.width - app.margin.right]);

  app.yScale = d3.scaleLinear()
    .domain([0, 1])
    .range([app.height - app.margin.bottom, app.margin.top]);

  app.xTickFormat = function(i) {
    if (i == 0) {
      return 'G1 start';
    } else if (i == 45) {
      return 'G1 half'
    } else if (i == 90) {
      return 'G1 end / G2 start'
    } else if (i == 135) {
      return 'G2 half'
    } else if (i == 180) {
      if (app.aet) {
        return 'G2 end / ET start'
      }
      return 'G2 end'
    } else if (app.aet && i == 195) {
      return 'ET half'
    } else if (app.aet && i == 210) {
      return 'ET end'
    }
  }

  app.xAxis = g => g
    .attr("transform", `translate(0,${app.height})`)
    .call(
      d3.axisBottom(app.xScale)
        .tickValues([0, 45, 90, 135, 180, 195, 210])
        .tickFormat(app.xTickFormat)
        .tickSizeOuter(0)
        .tickSizeInner(-app.height)
    )
    .call(g => g.select(".domain").remove())
    .call(
      g => g.selectAll("text")
        .attr("transform", "rotate(45)")
        .style("text-anchor", "start")
    )

  app.yTickFormat = function(i) {
    if (i == 0 | i == 1) {
      return '100%';
    } else if (i == 0.25 | i == 0.75) {
      return '75%'
    } else if (i == 0.5) {
      return '50%'
    }
  }

  app.yAxis = g => g
    .attr("transform", `translate(${app.margin.left},0)`)
    .call(
      d3.axisLeft(app.yScale)
        .tickValues([0, 0.25, 0.5, 0.75, 1])
        .tickFormat(app.yTickFormat)
        .tickSizeInner(-(app.width - app.margin.left - app.margin.right)))
    .call(g => g.select(".domain").remove())

  app.svg.append('g').call(app.xAxis);
  app.svg.append('g').call(app.yAxis);

  app.svg.append('g')
    .attr('class', 'extraGridLine')
  .append('line')
    .attr('x1', app.xScale(90))
    .attr('x2', app.xScale(90))
    .attr('y1', 0)
    .attr('y2', app.height)
    .attr("fill", "none")
    .attr('stroke', '#666666')
    .attr('stroke-dasharray', '20')
    .attr('stroke-width', '2.5px');

  app.svg.append('g')
    .attr('class', 'extraGridLine')
  .append('line')
    .attr('x1', app.xScale(app.aet ? 210 : 180))
    .attr('x2', app.xScale(app.aet ? 210 : 180))
    .attr('y1', 0)
    .attr('y2', app.height)
    .attr("fill", "none")
    .attr('stroke', '#666666')
    .attr('stroke-dasharray', '20')
    .attr('stroke-width', '2.5px');

  app.svg.append('g')
    .attr('class', 'teamLabel')
  .append('text')
    .attr('dominant-baseline', 'central')
    .attr('text-anchor', 'middle')
    .attr('x', app.xScale(45))
    .attr('y', app.yScale(0.5))
    .text('at ' + app.team1short)
    .style('font-size', app.isMobile ? '20px' : '25px')

  app.svg.append('g')
    .attr('class', 'teamLabel')
  .append('text')
    .attr('dominant-baseline', 'central')
    .attr('text-anchor', 'middle')
    .attr('x', app.xScale(app.aet ? 150 : 135))
    .attr('y', app.yScale(0.5))
    .text('at ' + app.team2short)
    .style('font-size', app.isMobile ? '20px' : '25px')


  app.lineDraw = d3.line()
    .x(function(d) { return app.xScale(d.minuteclean) })
    .y(function(d) { return app.yScale(d.predictedprobt1) })

  app.svg.append("path")
     .datum(app.data)
     .attr("fill", "none")
     .attr('stroke', '#000')
     .attr('stroke-width', '1.5px')
     .attr("d", app.lineDraw);

 app.svg.selectAll('.awaygoal')
   .data(app.tieEvents.filter(d => d.ag))
   .enter()
   .append('g')
     .attr('class', 'awaygoal')
   .append('circle')
     .attr('cx', d => app.xScale(d.minuteclean))
     .attr('cy', d => app.yScale(app.data.filter(e => e.minuterown == d.minuterown)[0].predictedprobt1))
     .attr('r', 7)
     .attr('fill', '#fcc5c0')

  app.svg.selectAll('.goal')
    .data(app.tieEvents.filter(d => d.eventtype.includes('goal')))
    .enter()
    .append('g')
      .attr('class', 'goal')
    .append('circle')
      .attr('cx', d => app.xScale(d.minuteclean))
      .attr('cy', d => app.yScale(app.data.filter(e => e.minuterown == d.minuterown)[0].predictedprobt1))
      .attr('r', 4)
      .attr('fill', '#0570b0')
}

// make chart div responsive to window width
app.updateDimensionsChart = function() {
    // margins for d3 chart
    app.margin = {top: 20, right: 20, bottom: 70, left: 20};

    // width of graphic depends on width of chart div
    app.chartElW = document.getElementById("chartholder").clientWidth;
    app.width = app.chartElW - app.margin.left - app.margin.right;

    // height depends only on mobile
    if (app.isMobile){
        app.height = 600 - app.margin.top - app.margin.bottom;
    } else {
        app.height = 700 - app.margin.top - app.margin.bottom;
    }
}
