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
    .domain([-2, app.xmax + 2])
    .range([app.margin.left, app.width - app.margin.right]);

  app.yScale = d3.scaleLinear()
    .domain([0, 1])
    .range([app.height - app.margin.bottom, app.margin.top]);

  app.yTickFormatR = function(i) {
    if (i == 0 | i == 1) {
     return '100%';
    } else if (i == 0.25 | i == 0.75) {
     return '75%'
    } else if (i == 0.5) {
     return '50%'
    }
  }

  app.yAxisR = g => g
    .attr("transform", `translate(${app.width - app.margin.left - app.margin.right},0)`)
    .call(
      d3.axisRight(app.yScale)
        .tickValues([0, 0.5, 1])
        .tickFormat('')
        .tickSizeInner(-(app.width - app.margin.left - app.margin.right))
    )
    .call(g => g.select(".domain").remove());

  app.svg.append('g').call(app.yAxisR);

  // app.yTickFormatL = function(i) {
  //   if (i == 1) {
  //     return app.team1code;
  //   }
  //   if (i == 0) {
  //     return app.team2code;
  //   }
  // }
  //
  // app.yAxisL = g => g
  //   .attr("transform", `translate(${app.margin.left},0)`)
  //   .call(
  //     d3.axisLeft(app.yScale)
  //       .tickValues([0, 1])
  //       .tickFormat(app.yTickFormatL)
  //       // .tickSizeInner(-(app.width - app.margin.left - app.margin.right))
  //       // .tickSizeOuter(20)
  //   )
  //   .call(g => g.select(".domain").remove())
  //   .call(g => g.selectAll('text').attr('x', app.isMobile ? 30 : 35))
  //   .call(g => g.select('.tick:first-of-type text').attr('dy', '1.1em'))
  //   .call(g => g.select('.tick:last-of-type text').attr('dy', '-0.5em'))
  //   // .call(g => g.select('text :last-of-type').attr('dy', '-1.5em'));
  //
  // app.svg.append('g').call(app.yAxisL);

  app.xAxis = g => g
    .attr("transform", `translate(0,0)`)
    .call(
      d3.axisTop(app.xScale)
        .tickValues([0, 90, 180, 210])
        .tickFormat('')
        .tickSizeOuter(0)
        .tickSizeInner(-app.height)
    )
    .call(g => g.select(".domain").remove())
    .call(
      g => g.selectAll("text")
        // .attr("transform", "rotate(45)")
        .style("text-anchor", "start")
    )

  app.svg.append('g').call(app.xAxis);

  app.xTickFormatLabel = function(i) {
    if (i == 89) {
      return 'End Leg 1'
    } else if (i == 91) {
      return app.isMobile ? '' : 'Start Leg 2'
    } else if (i == 179) {
      if (app.aet) {
        return 'End Leg 2'
      } else {
        return 'End Tie'
      }
    } else if (i == 181) {
      if (app.aet) {
        return 'Start ET'
      } else {
        return ''
      }
    } else if (i == 209) {
      if (app.aet) {
        return 'End Tie'
      } else {
        return ''
      }
    }
  }

  app.xAxisLabels = g => g
    .attr("transform", `translate(0,${app.margin.top})`)
    .call(
      d3.axisTop(app.xScale)
        .tickValues([89, 91, 179, 181, 209])
        .tickFormat(app.xTickFormatLabel)
        .tickSizeOuter(0)
        .tickSizeInner(0)
    )
    .call(g => g.select('.tick:nth-of-type(1) text').style('text-anchor', 'end'))
    .call(g => g.select('.tick:nth-of-type(2) text').style('text-anchor', 'start'))
    .call(g => g.select('.tick:nth-of-type(3) text').style('text-anchor', 'end'))
    .call(g => g.select('.tick:nth-of-type(4) text').style('text-anchor', 'start'))
    .call(g => g.select('.tick:nth-of-type(5) text').style('text-anchor', 'end'))
    .call(g => g.select('.domain').remove())

  if (!app.isMobile) { app.svg.append('g').call(app.xAxisLabels); }

  app.svg.append('g')
    .attr('class', 'teamLabel')
  .append('text')
    .attr('dominant-baseline', 'central')
    .attr('text-anchor', 'middle')
    .attr('x', app.xScale(45))
    .attr('y', app.yScale(0.5))
    .text('at ' + (app.isMobile ? app.team1code : app.team1short))
    .style('font-size', (app.isMobile ? '20px' : '40px'))

  app.svg.append('g')
    .attr('class', 'teamLabel')
  .append('text')
    .attr('dominant-baseline', 'central')
    .attr('text-anchor', 'middle')
    .attr('x', app.xScale(app.aet ? 150 : 135))
    .attr('y', app.yScale(0.5))
    .text('at ' + (app.isMobile ? app.team2code : app.team2short))
    .style('font-size', (app.isMobile ? '20px' : '40px'))

  app.svg.append('g')
    .attr('class', 'teamLabel')
  .append('text')
    .attr('dominant-baseline', 'hanging')
    .attr('text-anchor', 'left')
    .attr('x', app.xScale(1))
    .attr('y', app.yScale(0.99))
    .text(app.team1code + ' 100%')
    .style('font-size', (app.isMobile ? '12px' : '15px'))

  app.svg.append('g')
    .attr('class', 'teamLabel')
  .append('text')
    .attr('dominant-baseline', 'auto')
    .attr('text-anchor', 'left')
    .attr('x', app.xScale(1))
    .attr('y', app.yScale(0.01))
    .text(app.team2code + ' 100%')
    .style('font-size', (app.isMobile ? '12px' : '15px'))

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
   .data(app.tieEvents.filter(d => d.is_away_goal))
   .enter()
   .append('g')
     .attr('class', 'awaygoal')
   .append('circle')
     .attr('cx', d => app.xScale(d.minuteclean))
     .attr('cy', d => app.yScale(app.data.filter(e => e.minuterown == d.minuterown)[0].predictedprobt1))
     .attr('r', 8)
     .attr('fill', '#fcc5c0')

  app.svg.selectAll('.goal')
    .data(app.tieEvents.filter(d => d.is_goal))
    .enter()
    .append('g')
      .attr('class', 'goal')
    .append('circle')
      .attr('cx', d => app.xScale(d.minuteclean))
      .attr('cy', d => app.yScale(app.data.filter(e => e.minuterown == d.minuterown)[0].predictedprobt1))
      .attr('r', 5)
      .attr('fill', '#2596be')

  var scaleFactor = 3;
  var cardWidth = 3 * scaleFactor;
  var cardHeight = 4 * scaleFactor;

  app.svg.selectAll('.redcard')
    .data(app.tieEvents.filter(d => d.is_red_card))
    .enter()
    .append('g')
      .attr('class', 'goal')
    .append('rect')
      .attr('x', d => app.xScale(d.minuteclean) - cardWidth / 2)
      .attr('y', d => app.yScale(app.data.filter(e => e.minuterown == d.minuterown)[0].predictedprobt1) - cardHeight / 2)
      .attr('width', cardWidth)
      .attr('height', cardHeight)
      .attr('fill', '#ff3322')
}

// make chart div responsive to window width
app.updateDimensionsChart = function() {
    // margins for d3 chart
    app.margin = {top: 10, right: 5, bottom: 10, left: 0};

    // width of graphic depends on width of chart div
    app.chartElW = document.getElementById("chartholder").clientWidth;
    app.width = app.chartElW - app.margin.left - app.margin.right;

    // height depends only on mobile
    if (app.isMobile){
        app.height = 400 - app.margin.top - app.margin.bottom;
    } else {
        app.height = 600 - app.margin.top - app.margin.bottom;
    }
}
