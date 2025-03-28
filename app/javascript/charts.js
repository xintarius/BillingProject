document.addEventListener("turbo:load", () => {
    createInvoiceChart();
    function createInvoiceChart() {
        const invoiceChart = document.getElementById('invoice-chart').dataset.chartData;
        const chartData = JSON.parse(invoiceChart)
        const labels = Object.keys(chartData)
        const data = Object.values(chartData)
        const ctx = document.getElementById('invoice-chart').getContext('2d');
        console.log("Canvas context:", ctx)
        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [{
                    data: data,
                    backgroundColor: 'rgba(54, 162, 235)',
                    borderRadius: 30,
                    barPercentage: 0.2,
                    barThickness: 15,
                    categoryPercentage: 1,
                }]
            },
            options: {
                interaction: {
                    mode: 'nearest',
                    intersect: false
                },
                hover: {
                    mode: 'index',
                    intersect: true
                },
                elements: {
                    bar: {
                        hitRadius: 30
                    }
                },
                maintainAspectRatio: false,
                responsive: true,
                response: true,
                plugins: {
                    legend: {
                        display: false
                    },
                },
                scales: {
                    x: {
                        grid: {
                            display: false,
                        },
                        ticks: {
                            autoSkip: false,
                            font: {
                                size: 12,
                            },
                        }
                    },
                    y: {
                        grid: {
                            borderColor: '#F3F3F5',
                            lineWidth: 1,
                        },
                        beginAtZero: true,
                        ticks: {
                            font: {
                                size: 12,
                            },
                            display: true,
                            stepSize: 50,
                            maxTicksLimit: 10
                        },
                        border: {
                            color: '#FFFFFF'
                        },
                    }
                }
            }
        });
    }
})