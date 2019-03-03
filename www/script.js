// Initialize Firebase
var config = {
  apiKey: "AIzaSyA36BfvzD5FwJP1y7JmjkHHWtWhuwOGFr0",
  authDomain: "pickhacks19.firebaseapp.com",
  databaseURL: "https://pickhacks19.firebaseio.com",
  projectId: "pickhacks19",
  storageBucket: "pickhacks19.appspot.com",
  messagingSenderId: "624383403076"
};

firebase.initializeApp(config);


//script for sendData.html

var sendData = document.getElementsByClassName("doctor");
if (sendData) {
  firebase.database().ref("/users/j2XI6lPPZMXcltQWMGbZUh9fPn33").on('value', function(snapshot) {
    if (snapshot.val()["doctor"] != null) {
      for (let element of document.getElementsByClassName("doctor")) {
        element.innerText = snapshot.val()["doctor"];
      }
    }
  });
}


//script for progress.html

var progress = document.getElementById("armStartDate");
if (progress) {
  firebase.database().ref("/users/j2XI6lPPZMXcltQWMGbZUh9fPn33/exercises").on('value', function(snapshot) {
    snapshot.forEach(function (childSnap) {
      if (childSnap.exists()) {
        updateTable(childSnap.key, childSnap.val());
      }
    });
  });
}


//script for graphs

var armGraph = document.getElementById("armChart1");
var legGraph = document.getElementById("legChart1");
var backGraph = document.getElementById("backChart1");
if (armGraph) {
  getData("arm", document.getElementById("armChart1"), "Angle (Degrees)", "Arm Motion Range Over Time");
  getData("arm", document.getElementById("armChart2"), "Number of Reps", "Number of Reps Over Time");
}
else if (legGraph) {
  getData("leg", document.getElementById("legChart1"), "Angle (Degrees)", "Leg Motion Range Over Time");
  getData("leg", document.getElementById("legChart2"), "Number of Reps", "Number of Reps Over Time");
}
else if (backGraph) {
  getData("back", document.getElementById("backChart1"), "Angle (Degrees)", "Back Motion Range Over Time");
  getData("back", document.getElementById("backChart2"), "Number of Reps", "Number of Reps Over Time");
}


//functions used

function updateTable(bodyPart, data) {
  var keys = Object.keys(data["history"]);

    var startDate = "not started";
    if (keys.length != 0) {
      for (var date in data["history"]) {
        if (data["history"][date]["complete"]) {
          var date = new Date(1000*data["history"][date]["measured_at"]);
          startDate = date.getMonth() + 1 + "/" + date.getDay() + "/" + (1900 + date.getYear());
          break;
        }
      }
    }
  document.getElementById(bodyPart + "StartDate").innerText = startDate;

  var goal = data["goal"];
  document.getElementById(bodyPart + "Goal").innerText = goal;

  var initBaseline = "no recorded baseline";
  var currBaseline = "no recorded baseline";
  var initBaselineFound = false;
  for (var date in data["history"]) {
    if (data["history"][date]["complete"] && data["history"][date]["baseline"]) {
      if (!initBaselineFound) {
        initBaseline = Math.round(data["history"][date]["measurement"]);
      }
      currBaseline = Math.round(data["history"][date]["measurement"]);
    }
  }
  document.getElementById(bodyPart + "InitBaseline").innerText = initBaseline;
  document.getElementById(bodyPart + "CurrBaseline").innerText = currBaseline;

  var numReps = 0;
  for (var date in data["history"]) {
    if (data["history"][date]["complete"] && !data["history"][date]["baseline"]) {
      numReps++;
    }
  }
  document.getElementById(bodyPart + "NumReps").innerText = numReps;

  var currentImprovement = "no data yet";
  var derivs = [];
  var prev = null;
  for (var i = 0; i < keys.length; i++) {
    if (data["history"][keys[i]]["complete"] && data["history"][keys[i]]["baseline"]) {
      if (prev != null) {
        derivs.push(data["history"][keys[i]]["measurement"]
                  - data["history"][keys[prev]]["measurement"]);
      }
      prev = i;
    }
  }
  if (derivs.length > 1) {
    derivsSum = 0;
    count = 0;
    for (var i = derivs.length - 1; i > derivs.length - 4 && i >= 0; i--, count++) {
      derivsSum += derivs[i];
    }
    derivsAvg = derivsSum / count;
    if (data["goal"] - initBaseline == 0) {
      currentImprovement = "100%";
    }
    else {
      currentImprovement = Math.round(100 * derivsAvg / (data["goal"] - initBaseline)) + "%";
    }
  }
  document.getElementById(bodyPart + "CurrentImprovement").innerText = currentImprovement;

  var overallImprovement = "no data yet";
  if (currBaseline != "no recorded baseline") {
    if (data["goal"] - initBaseline == 0) {
      overallImprovement = "100%";
    }
    else {
      overallImprovement = Math.round((currBaseline - initBaseline) / (data["goal"] - initBaseline)) + "%";
    }
  }
  document.getElementById(bodyPart + "OverallImprovement").innerText = overallImprovement;
}

function getData(bodyPart, graph, yLabel, title) {
  firebase.database().ref("/users/j2XI6lPPZMXcltQWMGbZUh9fPn33/exercises/" + bodyPart + "/history").on('value', function(snapshot) {
    var x = [];
    var y = [];
    snapshot.forEach(function (element) {
      element = element.val();
      if (element["complete"] && (element["baseline"] ^ yLabel == "Number of Reps")) {
        x.push(new Date(element["measured_at"]));
        y.push(element["measurement"]);
      }
    });

    buildGraph(bodyPart, graph, yLabel, title, x, y);
  });
}

function buildGraph(bodyPart, graph, yLabel, title, x, y) {
  console.log(bodyPart);
  console.log(graph);
  console.log(yLabel);
  console.log(title);
  console.log(x);
  console.log(y);
  var ctx = graph.getContext("2d");
  var chart = new Chart(ctx, {
    type: "line",
    data: {
      labels: x,
      datasets: [
        {
          backgroundColor: "rgb(255, 99, 132)",
          borderColor: "rgb(255, 99, 132)",
          fill: false,
          data: y,
          lineTension: 0
        }
      ]
    },
    options: {
      scales: {
        yAxes: [
          {
            scaleLabel: {
              display: true,
              labelString: yLabel
            }
          }
        ],
        xAxes: [
          {
            scaleLabel: {
              display: true,
              labelString: "Date"
            },
            type: "time",
            ticks: {
              autoSkip: true,
              maxTicksLimit: 20
            }
          }
        ]
      },
      title: {
        text: title,
        display: true,
        fontSize: 20
      },
      legend: {
        display: false
      },
      tooltips: {
        enabled: false
      }
    }
  });
}
