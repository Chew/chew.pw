import Chart from 'chart.js/auto';

const ctx = document.getElementById('myChart').getContext('2d');

const values = document.getElementById("win_sum").innerText.split(" ");

const gameTable = document.getElementById("regular-season-table");
const gameTableRows = gameTable.getElementsByTagName("tr");

const games = [];

for (let i = 1; i < gameTableRows.length; i++) {
    // Columns are: Date, Away Team, Home Team, Score, State (Win/Loss/Tie), Result (Final, Postponed, etc.)
    const game = gameTableRows[i].getElementsByTagName("td");
    const gameDate = game[0].innerText;
    const gameAwayTeam = game[1].innerText;
    const gameHomeTeam = game[2].innerText;
    const gameScore = game[3].innerText;
    const gameState = game[4].innerText;
    const gameResult = game[5].innerText;

    // If result contains "Postponed" or "Cancelled", skip it.
    if (gameResult.includes("Postponed") || gameResult.includes("Cancelled")) {
        continue;
    }

    // Format is:
    // [Away Team] @ [Home Team] on [Date]
    // [State]: [Score]
    games.push(`${gameAwayTeam} @ ${gameHomeTeam}\nDate: ${gameDate}\n${gameState}: ${gameScore}`);
}

const DATA_COUNT = values.length;
let labels = [];
for (let i = 0; i < DATA_COUNT; i++) {
    labels.push(i);
}

const above500values = [];
const at500values = [];
const below500values = [];

for (let i = 0; i < DATA_COUNT; i++) {
    if (values[i] > 0) {
        above500values.push(values[i]);
        below500values.push(0);
    } else if (values[i] < 0) {
        above500values.push(0);
        below500values.push(values[i]);
    } else {
        above500values.push(0);
        below500values.push(0);
        at500values.push({ x: i, y: 0 });
    }
}

const data = {
    labels: labels,
    datasets: [
        {
            type: 'bar',
            label: 'Above 500',
            data: above500values,
            // green color
            backgroundColor: "#3fd03f",
        },
        {
            type: 'scatter',
            label: 'At 500',
            data: at500values,
            // yellow color
            backgroundColor: "#c7a32c",
        },
        {
            type: 'bar',
            label: 'Below 500',
            data: below500values,
            // red color
            backgroundColor: "#c72c2c",
        }
    ]
};

const config = {
    type: 'bar',
    data: data,
    options: {
        responsive: true,
        plugins: {
            legend: {
                display: 'none',
            },
            title: {
                display: true,
                text: 'Win Chart'
            },
            tooltip: {
                callbacks: {
                    // Update title for hover
                    title: function(context) {
                        return games[context[0].dataIndex];
                    },
                    // Update label
                    label: function(context) {
                        console.log(context);
                        if (context.dataset.label === "At 500") {
                            return "At 500";
                        } else {
                            return Math.abs(context.parsed.y) + " Games " + context.dataset.label;
                        }
                    }
                }
            }
        },
        scales: {
            x: {
                stacked: true,
            },
            y: {
                stacked: true
            }
        }
    },
};

const myChart = new Chart(ctx, config);