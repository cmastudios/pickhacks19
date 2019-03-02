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

//temp data from "exercise": "arm"

// var data = {
//   "history" : {
//     "7689798273432" : {
//       "measurement" : 20,
//       "baseline" : true,
//       "completed" : true,
//       "measured_at" : 7689798273
//     },
//     "8689798273432" : {
//       "measurement" : 20,
//       "baseline" : true,
//       "completed" : true,
//       "measured_at" : 86897982
//     },
//     "9689798273432" : {
//       "measurement" : 30,
//       "baseline" : true,
//       "completed" : true,
//       "measured_at" : 9689798273432
//     },
//     "9789798273432" : {
//       "measurement" : 35,
//       "baseline" : true,
//       "completed" : true,
//       "measured_at" : 9789798273432
//     },
//     "9789798273433" : {
//       "measurement" : 37,
//       "baseline" : true,
//       "completed" : true,
//       "measured_at" : 9789798273433
//     },
//     "9789798273434" : {
//       "measurement" : 30,
//       "baseline" : true,
//       "completed" : true,
//       "measured_at" : 9789798273434
//     },
//     "9789798273435" : {
//       "measurement" : 34,
//       "baseline" : true,
//       "completed" : true,
//       "measured_at" : 9789798273435
//     }
//   },
//   "goal" : 90
// };

firebase.database().ref("/users/j2XI6lPPZMXcltQWMGbZUh9fPn33/exercises").on('value', function(snapshot) {
  snapshot.forEach(function (childSnap) {
    if (childSnap.exists()) {
      updateTable(childSnap.key, childSnap.val());
    }
  });
});

function updateTable(bodyPart, data) {
  var keys = Object.keys(data["history"]);

  var startDate;
  if (keys.length != 0) {
    startDate = data["history"][keys[0]]["measured_at"];
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
    else if (data["history"][date]["complete"] == false) {
      break;
    }
  }
  document.getElementById(bodyPart + "InitBaseline").innerText = initBaseline;

  var currBaseline = "no recorded baseline";
  for (var date in data["history"]) {
    if (data["history"][date]["complete"] == true && data["history"][date]["baseline"] == true) {
      currBaseline = data["history"][date]["measurement"];
    }
  }
  document.getElementById(bodyPart + "CurrBaseline").innerText = currBaseline;

  var numReps = keys.length;
  document.getElementById(bodyPart + "NumReps").innerText = numReps;

  var currentImprovement = "no data yet";
  var derivs = [];
  for (var i = 1; i < keys.length; i++) {
    if (data["history"][keys[i]]["complete"] == false) {
      break;
    }
    if (data["history"][keys[i]]["baseline"] == true) {
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
      currentImprovement = 100 * derivsAvg / (data["goal"] - initBaseline) + "%";
    }
  }
  document.getElementById(bodyPart + "CurrentImprovement").innerText = currentImprovement;

  var overallImprovement = "no data yet";
  if (keys.length != 0) {
    if (data["goal"] - initBaseline == 0) {
      overallImprovement = "100%";
    }
    else {
      overallImprovement = (currBaseline - initBaseline) / (data["goal"] - initBaseline) + "%";
    }
  }
  console.log(overallImprovement);
  document.getElementById(bodyPart + "OverallImprovement").innerText = overallImprovement;
}
