import Chart from 'chart.js/auto';

const home_values = document.getElementById("home-info").innerText.split("/");
const away_values = document.getElementById("away-info").innerText.split("/");

/*
const ctx = document.getElementById('progress-graph').getContext('2d');

// [0] => away runs
// [1] => away hits
// [2] => away errors
// [3] => away left on base
// [4] => home runs
// [5] => home hits
// [6] => home errors
// [7] => home left on base
const graph_data = [[], [], [], [], [], [], [], []];

for (let i = 0; i < away_values.length; i++) {
    let a_d = away_values[i].split(",");
    let h_d = home_values[i].split(",");

    for (let a = 0; a < a_d.length; a++)
        graph_data[a].push(parseInt(a_d[a]))

    for (let h = 4; h < h_d.length; h++)
        graph_data[h].push(parseInt(h_d[h]))
}

const DATA_COUNT = away_values.length;
const NUMBER_CFG = {count: DATA_COUNT, min: -100, max: 100};

let labels = [];
for (let i = 1; i <= 9; i++) {
    labels.push(i);
}

const data = {
    labels: labels,
    datasets: [
        {
            label: 'Runs (Away)',
            data: graph_data[0],
            stack: 'Runs',
            // red color
            borderColor: 'rgb(255,99,132)',
        },
        {
            label: 'Runs (Home)',
            data: graph_data[4],
            stack: 'Runs',
            // blue color
            borderColor: 'rgb(54,162,235)',
        },
        {
            label: 'Hits (Away)',
            data: graph_data[1],
            stack: 'Hits',
            // red color
            borderColor: 'rgb(255,206,86)',
        },
        {
            label: 'Hits (Home)',
            data: graph_data[5],
            stack: 'Hits',
            // blue color
            borderColor: 'rgb(75,192,192)',
        },
        {
            label: 'Errors (Away)',
            data: graph_data[2],
            stack: 'Errors',
            // red color
            borderColor: 'rgb(255,159,64)',
        },
        {
            label: 'Errors (Home)',
            data: graph_data[6],
            stack: 'Errors',
            // blue color
            borderColor: 'rgb(153,102,255)',
        },
        {
            label: 'Left on Base (Away)',
            data: graph_data[3],
            stack: 'Left on Base',
            // red color
            borderColor: 'rgb(255,99,132)',
        },
        {
            label: 'Left on Base (Home)',
            data: graph_data[7],
            stack: 'Left on Base',
            // blue color
            borderColor: 'rgb(54,162,235)',
        }
    ]
};

const config = {
    type: 'line',
    data: data,
    options: {
        plugins: {
            title: {
                display: true,
                text: 'Chart.js Bar Chart - Stacked'
            },
        },
        responsive: true,
        scales: {
            x: {
                stacked: true,
            },
            y: {
                stacked: true
            }
        }
    }
};

const myChart = new Chart(ctx, config);
 */

// Listen to changes on the "#scorecard-type" select element
$("#scorecard-type").on('change', function() {
    // turn val into a number
    let val = parseInt($(this).val());

    // Get the scorecard table
    let values = $(".valued-inning");

    // Iterate through each value and find ".extra-data", split it by "," and grab the [val] index
    for (let i = 0; i < values.length; i++) {
        let extra_data = $(values[i]).find(".extra-data").text().split(",");
        $(values[i]).find(".shown-value").text(extra_data[val]);
    }
});