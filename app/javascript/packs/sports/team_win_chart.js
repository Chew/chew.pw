import Chart from 'chart.js/auto';

const ctx = document.getElementById('myChart').getContext('2d');

const values = document.getElementById("win_sum").innerText.split(" ");

const DATA_COUNT = values.length;
const NUMBER_CFG = {count: DATA_COUNT, min: -100, max: 100};

let labels = [];
for (let i = 0; i < DATA_COUNT; i++) {
    labels.push(i);
}

const above500values = [];
const below500values = [];

for (let i = 0; i < DATA_COUNT; i++) {
    if (values[i] > 0) {
        above500values.push(values[i]);
        below500values.push(0);
    } else {
        above500values.push(0);
        below500values.push(values[i]);
    }
}

const data = {
    labels: labels,
    datasets: [
        {
            label: 'Above 500',
            data: above500values,
            // green color
            backgroundColor: "#3fd03f",
        },
        {
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