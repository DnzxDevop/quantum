var hex = [
  "0",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
];
var solutions = ["", ""];
var solutionPos = [
  [0, 0],
  [0, 0],
];
var userSolPos = [
  [0, 1],
  [0, 15],
];
var gameStarted = false;
var solved = [false, false];
var endTime = 0;
var now = 0;
var thread;
var penalty = 5000;
var mistakes = 0;
var lastBeep = 0;
var gameTable = [[], [], [], [], [], [], [], [], []];
var lastReseed = [[], [], [], [], [], [], [], [], []];

function resetGameState() {
  solutions = ["", ""];
  solutionPos = [
    [0, 0],
    [0, 0],
  ];
  userSolPos = [
    [0, 1],
    [0, 15],
  ];
  solved = [false, false];
  gameStarted = false;
  mistakes = 0;
  $(".sol2").removeClass("sol2");
}

function getRandomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function writeSolution() {
  for (var i = 0; i < solutions[0].length; i++) {
    $(
      "#" + solutionPos[0][0].toString() + (solutionPos[0][1] + i).toString()
    ).text(solutions[0].charAt(i));
    $(
      "#" + solutionPos[1][0].toString() + (solutionPos[1][1] + i).toString()
    ).text(solutions[1].charAt(i));
  }
}

function fadeBigMsg(b) {
  if (b) {
    $("#screen").fadeIn();
  } else {
    $("#screen").fadeOut();
  }
}

function setBigMsg(txt) {
  $("#screentext").html(txt);
}

function wrongSolution() {
  mistakes++;
  endTime = endTime - mistakes * penalty;
}

function tryFinish() {
  if (solved[0] && solved[1]) {
    clearInterval(thread);
    $("#infobox").fadeOut().text("Hackeado").fadeIn();
    setBigMsg("Hackeado");
    setTimeout(function () {
      fadeBigMsg(true);
      playSound("audiofinish", 1);
      setTimeout(function () {
        $.post(
          "http://quantum_system/callback",
          JSON.stringify({ success: true, remainingtime: endTime - now })
        );
      }, 2000);
    }, 2000);
    resetGameState();
  }
}

function writeUserSolution() {
  $(".sol").removeClass("sol");
  for (var i = 0; i < solutions[0].length; i++) {
    $(
      "#" + userSolPos[0][0].toString() + (userSolPos[0][1] + i).toString()
    ).text(solutions[0].charAt(i));
    $(
      "#" + userSolPos[0][0].toString() + (userSolPos[0][1] + i).toString()
    ).addClass("sol");
    $(
      "#" + userSolPos[1][0].toString() + (userSolPos[1][1] + i).toString()
    ).text(solutions[1].charAt(i));
    $(
      "#" + userSolPos[1][0].toString() + (userSolPos[1][1] + i).toString()
    ).addClass("sol");
  }
}

function writeTime() {
  if (!solved[0] || !solved[1]) {
    $("#infobox").text(
      ((endTime - new Date().getTime()) / 1000.0).toFixed(2).toString() + "s"
    );
  }
}

function seedTable() {
  for (var j = 0; j < 18; j++) {
    $("#0" + (j + 1).toString()).html("&nbsp;");
  }
  now = new Date().getTime();
  if (now >= endTime) {
    clearInterval(thread);
    $("#infobox").fadeOut().text("Você Falhou!").fadeIn();
    setBigMsg("Você Falhou!");
    setTimeout(function () {
      fadeBigMsg(true);
      playSound("audiofail", 1);
      $.post(
        "http://quantum_system/callback",
        JSON.stringify({ success: false, remainingtime: 0 })
      );
    }, 2000);
    resetGameState();
  } else {
    writeTime();
  }
  for (var i = 0; i < 9; i++) {
    for (var j = 0; j < 18; j++) {
      if (lastBeep < now - 600) {
        playSound("audiobeep", 0.08);
        lastBeep = now;
      }
      if (lastReseed[i][j] < now - 200) {
        gameTable[i][j] = hex[getRandomInt(0, 15)];
        lastReseed[i][j] = now;
      }
      $("#" + (i + 1).toString() + (j + 1).toString()).text(gameTable[i][j]);
    }
  }
  writeSolution();
  writeUserSolution();
}

function playSound(snd, vol) {
  document.getElementById(snd).load();
  document.getElementById(snd).volume = vol;
  document.getElementById(snd).play();
}

function generateSolutions(s) {
  solutionPos[0] = [getRandomInt(1, 9), getRandomInt(1, 18 - s)];
  var goodsolution = false;
  while (!goodsolution) {
    solutionPos[1] = [getRandomInt(1, 9), getRandomInt(1, 18 - s)];
    if (solutionPos[0][0] == solutionPos[1][0]) {
      if (solutionPos[0][1] + s < solutionPos[1][1]) {
        goodsolution = true;
      } else if (solutionPos[0][1] > solutionPos[1][1] + s) {
        goodsolution = true;
      }
    } else {
      goodsolution = true;
    }
  }
  for (var i = 0; i < s; i++) {
    solutions[0] = solutions[0] + hex[getRandomInt(0, 15)];
    solutions[1] = solutions[1] + hex[getRandomInt(0, 15)];
  }
  userSolPos = [
    [0, 1],
    [0, 19 - s],
  ];
}

function startGame(solutionsize, timeout) {
  for (var i = 0; i < 9; i++) {
    for (var j = 0; j < 18; j++) {
      lastReseed[i][j] = 0;
    }
  }
  generateSolutions(solutionsize);
  gameStarted = true;
  endTime = new Date().getTime() + timeout * 1000;
  thread = setInterval(function () {
    seedTable();
  }, 5);
}

$(function () {
  $("#game").append('<table id="gametable"></table>');
  $("#gametable").append('<tr id="row0"></tr>');
  for (var j = 0; j < 18; j++) {
    $("#row0").append('<th id="0' + (j + 1).toString() + '">&nbsp;</th>');
  }
  for (var i = 0; i < 9; i++) {
    $("#gametable").append('<tr id="row' + (i + 1).toString() + '"></tr>');
    for (var j = 0; j < 18; j++) {
      $("#row" + (i + 1).toString()).append(
        '<td id="' + (i + 1).toString() + (j + 1).toString() + '">&nbsp;</td>'
      );
    }
  }

  document.onkeydown = function (event) {
    if (gameStarted) {
      event = event || window.event;
      var charCode = event.keyCode || event.which;
      if (charCode == 87 && !solved[0]) {
        // w
        if (userSolPos[0][0] > 0) {
          userSolPos[0][0]--;
        }
      } else if (charCode == 65 && !solved[0]) {
        //a
        if (userSolPos[0][1] > 1) {
          userSolPos[0][1]--;
        }
      } else if (charCode == 83 && !solved[0]) {
        //s
        if (userSolPos[0][0] < 9) {
          userSolPos[0][0]++;
        }
      } else if (charCode == 68 && !solved[0]) {
        //d
        if (userSolPos[0][1] < 19 - solutions[0].length) {
          userSolPos[0][1]++;
        }
      }
      if (charCode == 38 && !solved[1]) {
        // up
        if (userSolPos[1][0] > 0) {
          userSolPos[1][0]--;
        }
      } else if (charCode == 37 && !solved[1]) {
        //left
        if (userSolPos[1][1] > 1) {
          userSolPos[1][1]--;
        }
      } else if (charCode == 40 && !solved[1]) {
        //down
        if (userSolPos[1][0] < 9) {
          userSolPos[1][0]++;
        }
      } else if (charCode == 39 && !solved[1]) {
        //right
        if (userSolPos[1][1] < 19 - solutions[0].length) {
          userSolPos[1][1]++;
        }
      }
      if (charCode == 32 && !solved[0]) {
        // space
        if (
          userSolPos[0][0] == solutionPos[0][0] &&
          userSolPos[0][1] == solutionPos[0][1]
        ) {
          solved[0] = true;
          for (var i = 0; i < solutions[0].length; i++) {
            $(
              "#" +
                userSolPos[0][0].toString() +
                (userSolPos[0][1] + i).toString()
            ).addClass("sol2");
          }
          $(".sol2").fadeOut().fadeIn();
          playSound("audiocorrect", 1);
          tryFinish();
        } else {
          playSound("audiowrong", 1);
          wrongSolution();
        }
      }
      if (charCode == 13 && !solved[1]) {
        // enter
        if (
          userSolPos[1][0] == solutionPos[1][0] &&
          userSolPos[1][1] == solutionPos[1][1]
        ) {
          solved[1] = true;
          for (var i = 0; i < solutions[1].length; i++) {
            $(
              "#" +
                userSolPos[1][0].toString() +
                (userSolPos[1][1] + i).toString()
            ).addClass("sol2");
          }
          $(".sol2").fadeOut().fadeIn();
          playSound("audiocorrect", 1);
          tryFinish();
        } else {
          playSound("audiowrong", 1);
          wrongSolution();
        }
      }
    }
  };

  window.addEventListener("message", function (event) {
    var item = event.data;

    if (item.start == true) {
      if (item.s && item.d) {
        setBigMsg(
          '<span class="flash">Iniciando Algoritmos...</span><br /><span class="small">Ache falhas constantes</span>'
        );
        playSound("audiostart", 1);
        $(".flash").fadeOut().fadeIn().fadeOut().fadeIn().fadeOut().fadeIn();
        setTimeout(function () {
          fadeBigMsg(false);
          startGame(item.s, item.d);
        }, 3000);
      }
    }

    if (item.displayMsg) {
      setBigMsg('<span class="flash">' + item.displayMsg + "</span>");
    }

    if (item.fail == true) {
      endTime = now;
    }

    if (item.show == true) {
      $("#phone").fadeIn();
      $("#bgfill").fadeIn();
      $("#phonewrapper").fadeIn();
    } else if (item.show == false) {
      $("#phone").fadeOut();
      $("#bgfill").fadeOut();
      $("#phonewrapper").fadeOut();
    }
  });
});
