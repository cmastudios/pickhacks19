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
  console.log("hey");
  firebase.database().ref("/users/j2XI6lPPZMXcltQWMGbZUh9fPn33").on('value', function(snapshot) {
    if (snapshot.val()["doctor"] != null) {
      for (let element of document.getElementsByClassName("doctor")) {
        console.log(element);
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

var armGraph = document.getElementById("armChart");
var legGraph = document.getElementById("legChart");
var backGraph = document.getElementById("backChart");
if (armGraph) {
  getData("arm", armGraph);
}
else if (legGraph) {
  getData("leg", legGraph);
}
else if (backGraph) {
  getData("back", backGraph);
}


//functions used

function updateTable(bodyPart, data) {
  var keys = Object.keys(data["history"]);

  var startDate;
  if (keys.length != 0 && data["history"][keys[0]]["complete"]) {
    var date = new Date(1000*data["history"][keys[0]]["measured_at"]);
    startDate = date.getMonth() + 1 + "/" + date.getDay() + "/" + (1900 + date.getYear());
  }
  else {
    startDate = "not started";
  }
  document.getElementById(bodyPart + "StartDate").innerText = startDate;

  var goal = data["goal"];
  document.getElementById(bodyPart + "Goal").innerText = goal;

  var initBaseline = "no recorded baseline";
  for (var date in data["history"]) {
    if (data["history"][date]["complete"] == true && data["history"][date]["baseline"] == true) {
      initBaseline = data["history"][date]["measurement"];
      break;
    }
    else if (!data["history"][date]["complete"]) {
      break;
    }
  }
  document.getElementById(bodyPart + "InitBaseline").innerText = initBaseline;

  var currBaseline = "no recorded baseline";
  for (var date in data["history"]) {
    if (data["history"][date]["complete"] && data["history"][date]["baseline"]) {
      currBaseline = Math.round(data["history"][date]["measurement"]);
    }
  }
  document.getElementById(bodyPart + "CurrBaseline").innerText = currBaseline;

  var numReps = 0;
  for (var date in data["history"]) {
    if (data["history"][date]["complete"]) {
      numReps++;
    }
    else {
      break;
    }
  }
  document.getElementById(bodyPart + "NumReps").innerText = numReps;

  var currentImprovement = "no data yet";
  var derivs = [];
  for (var i = 1; i < keys.length; i++) {
    if (!data["history"][keys[i]]["complete"]) {
      break;
    }
    if (data["history"][keys[i]]["baseline"]) {
      derivs.push(data["history"][keys[i]]["measurement"]
                - data["history"][keys[i-1]]["measurement"]);
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
  if (keys.length != 0 && data["history"][keys[0]]["complete"]) {
    if (data["goal"] - initBaseline == 0) {
      overallImprovement = "100%";
    }
    else {
      overallImprovement = Math.round((currBaseline - initBaseline) / (data["goal"] - initBaseline)) + "%";
    }
  }
  document.getElementById(bodyPart + "OverallImprovement").innerText = overallImprovement;
}

function getData(bodyPart, graph) {
  firebase.database().ref("/users/j2XI6lPPZMXcltQWMGbZUh9fPn33/exercises/" + bodyPart + "/history").on('value', function(snapshot) {
    var x = [];
    var y = [];
    snapshot.forEach(function (element) {
      element = element.val();
      if (element["complete"]) {
        x.push(new Date(element["measured_at"]));
        y.push(element["measurement"]);
      }
    });

    buildGraph(bodyPart, graph, x, y);
  });
}

function buildGraph(bodyPart, graph, x, y) {
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
              labelString: "Degrees"
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
        text: bodyPart + " motion range over time",
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
