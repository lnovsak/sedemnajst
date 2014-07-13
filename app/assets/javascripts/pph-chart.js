$(function() {
  var user_id = $("#pph-chart").data("user-id"),
      url;
  if (!$("#pph-chart").length) { return; }
  if (user_id) {
    url = "/users/" + user_id + "/pph";
  } else {
    url = "/stats/pph";
  }
  function pointClick(ev) {
    var points = ev.point.series.points,
        from = Highcharts.dateFormat("%d.%m.%Y", ev.point.x),
        to = Highcharts.
          dateFormat("%d.%m.%Y", points[points.indexOf(ev.point) + 1].x),
        url;
    if (user_id) {
      url = "/users/" + user_id + "/posts?posts_q[remote_created_at_gt]=" +
        from + "&posts_q[remote_created_at_lt]=" + to;
    } else {
      url = "/posts?posts_q[remote_created_at_gt]=" + from +
        "&posts_q[remote_created_at_lt]=" + to;
    }
    window.open(url, "_blank");
  }
  $.getJSON(url, function(data) {
    $("#pph-chart-container").highcharts("StockChart", {
      colors: ["#ffcf3e"],
      navigator: {
	series: {
	  data: data,
          color: "#ffcf3e",
          lineColor: "#f0b400"
        }
      },
      scrollbar: {
        enabled: false
      },
      plotOptions: {
        series: {
          marker: {
            radius: 3,
            fillColor: "#f0b400"
          },
          lineWidth: 3,
          dataGrouping: {
            groupPixelWidth: "20",
            approximation: "sum"
          },
          point: {
            events: {
              click: pointClick
            }
          }
        }
      },
      chart: {
        backgroundColor: "#ffe495",
	zoomType: "x",
        type: "spline",
        style: {
          fontFamily: "Verdana, sans-serif"
        }
      },
      rangeSelector: {
        allButtonsEnabled: true,
        selected: 1,
        inputBoxBorderColor: "#ffe495",
	inputStyle: {
          color: "#f6931f",
	  fontWeight: "bold"
	},
        inputDateFormat: "%d.%m.%Y",
        inputEditDateFormat: "%d.%m.%Y",
        inputDateParser: function(date) {
          var parts = date.split(".");
          return Date.UTC(parts[2], parseInt(parts[1]) - 1, parts[0]);
        },
	buttonTheme: {
	  fill: "#fece2f",
          width: 88,
          height: 18,
	  "stroke-width": 0,
	  r: 8,
	  style: {
	    color: '#4c3000',
	    fontWeight: 'bold'
	  },
	  states: {
	    hover: {
              fill: "#fedb66"
	    },
	    select: {
	      fill: '#fff',
	      style: {
              color: "#0074c7"
	      }
	    }
	  }
	},
        buttonSpacing: 5,
        buttons: [{
	  type: "month",
	  count: 1,
	  text: "1 mesec"
        }, {
	  type: "month",
	  count: 3,
	  text: "3 meseci"
        }, {
	  type: "month",
	  count: 6,
	  text: "6 mesecev"
        }, {
	  type: "year",
	  count: 1,
	  text: "1 leto"
        }, {
	  type: "all",
	  text: "vseskozi"
        }]
      },
      series: [{
	data: data,
        name: "postov",
        dataGrouping: {
          dateTimeLabelFormats: {
            week: ["teden od %A, %b %e, %Y"]
          }
        }
      }],
      yAxis: {
        min: 0
      }
    }, function(chart) {
      setTimeout(function(){
        $("input.highcharts-range-selector", $(chart.options.chart.renderTo)).
          datepicker({
            beforeShow: function(i, obj) {
              $widget = obj.dpDiv;
              window.$uiDatepickerDiv = $widget;
              if ($widget.data("top")) {
                setTimeout(function() {
                  $uiDatepickerDiv.css("top", $uiDatepickerDiv.data("top"));
                }, 50);
              }
            },
            onClose: function(i, obj) {
              $widget = obj.dpDiv;
              $widget.data("top", $widget.position().top);
            }
          });
      }, 0);
    });
  });
});
