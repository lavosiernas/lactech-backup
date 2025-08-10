// Chart utilities for reports and dashboards

// Chart.js theme helper to adapt to dark mode
function getChartTheme(isDark) {
    return {
        gridColor: isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)',
        tickColor: isDark ? '#e5e7eb' : '#475569',
        lineBorder: isDark ? '#34d399' : '#369e36',
        lineFill: isDark ? 'rgba(52, 211, 153, 0.15)' : 'rgba(54, 158, 54, 0.1)',
        barColor: isDark ? '#60a5fa' : '#2563eb'
    };
}

function applyChartTheme() {
    try {
        const isDark = document.documentElement.classList.contains('dark');
        const t = getChartTheme(isDark);
        const charts = [
            window.volumeChart,
            window.dashboardWeeklyChart,
            window.temperatureChart,
            window.qualityChart,
            window.weeklyVolumeChart,
            window.dailyVolumeChart,
            window.qualityTrendChart,
            window.qualityDistributionChart,
            window.paymentsChart,
            window.weeklySummaryChart,
            window.monthlyVolumeChart
        ].filter(Boolean);

        charts.forEach((ch) => {
            try {
                if (ch.config.type === 'line') {
                    ch.data.datasets.forEach(ds => {
                        ds.borderColor = t.lineBorder;
                        ds.backgroundColor = t.lineFill;
                    });
                }
                if (ch.config.type === 'bar') {
                    ch.data.datasets.forEach(ds => {
                        ds.backgroundColor = t.barColor;
                    });
                }
                if (ch.options && ch.options.scales) {
                    Object.values(ch.options.scales).forEach(scale => {
                        if (!scale.grid) scale.grid = {};
                        if (!scale.ticks) scale.ticks = {};
                        scale.grid.color = t.gridColor;
                        scale.ticks.color = t.tickColor;
                    });
                }
                if (ch.options && ch.options.plugins && ch.options.plugins.legend && ch.options.plugins.legend.labels) {
                    ch.options.plugins.legend.labels.color = t.tickColor;
                }
                ch.update('none');
            } catch (_) {}
        });
    } catch (_) {}
}

// Create a volume chart
function createVolumeChart(canvasId, data) {
    try {
        const ctx = document.getElementById(canvasId);
        if (!ctx) return null;

        const isDark = document.documentElement.classList.contains('dark');
        const theme = getChartTheme(isDark);

        return new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.map(item => new Date(item.date).toLocaleDateString('pt-BR')),
                datasets: [{
                    label: 'Volume (L)',
                    data: data.map(item => item.volume),
                    borderColor: theme.lineBorder,
                    backgroundColor: theme.lineFill,
                    tension: 0.1,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: { color: theme.gridColor },
                        ticks: { color: theme.tickColor }
                    },
                    x: {
                        grid: { color: theme.gridColor },
                        ticks: { color: theme.tickColor }
                    }
                },
                plugins: {
                    legend: {
                        labels: { color: theme.tickColor }
                    }
                }
            }
        });
    } catch (error) {
        console.error('Error creating volume chart:', error);
        return null;
    }
}

// Create a quality chart
function createQualityChart(canvasId, data) {
    try {
        const ctx = document.getElementById(canvasId);
        if (!ctx) return null;

        const isDark = document.documentElement.classList.contains('dark');
        const theme = getChartTheme(isDark);

        return new Chart(ctx, {
            type: 'bar',
            data: {
                labels: data.map(item => new Date(item.date).toLocaleDateString('pt-BR')),
                datasets: [
                    {
                        label: 'Gordura (%)',
                        data: data.map(item => item.fat),
                        backgroundColor: theme.barColor + '80',
                        borderColor: theme.barColor,
                        borderWidth: 1
                    },
                    {
                        label: 'Proteína (%)',
                        data: data.map(item => item.protein),
                        backgroundColor: '#10b981' + '80',
                        borderColor: '#10b981',
                        borderWidth: 1
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: { color: theme.gridColor },
                        ticks: { color: theme.tickColor }
                    },
                    x: {
                        grid: { color: theme.gridColor },
                        ticks: { color: theme.tickColor }
                    }
                },
                plugins: {
                    legend: {
                        labels: { color: theme.tickColor }
                    }
                }
            }
        });
    } catch (error) {
        console.error('Error creating quality chart:', error);
        return null;
    }
}

// Create a payments chart
function createPaymentsChart(canvasId, data) {
    try {
        const ctx = document.getElementById(canvasId);
        if (!ctx) return null;

        const isDark = document.documentElement.classList.contains('dark');
        const theme = getChartTheme(isDark);

        return new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.map(item => new Date(item.date).toLocaleDateString('pt-BR')),
                datasets: [{
                    label: 'Valor (R$)',
                    data: data.map(item => item.amount),
                    borderColor: '#f59e0b',
                    backgroundColor: '#f59e0b' + '20',
                    tension: 0.1,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: { color: theme.gridColor },
                        ticks: { 
                            color: theme.tickColor,
                            callback: function(value) {
                                return 'R$ ' + value.toFixed(2);
                            }
                        }
                    },
                    x: {
                        grid: { color: theme.gridColor },
                        ticks: { color: theme.tickColor }
                    }
                },
                plugins: {
                    legend: {
                        labels: { color: theme.tickColor }
                    }
                }
            }
        });
    } catch (error) {
        console.error('Error creating payments chart:', error);
        return null;
    }
}

// Destroy chart safely
function destroyChart(chart) {
    try {
        if (chart && typeof chart.destroy === 'function') {
            chart.destroy();
        }
    } catch (error) {
        console.error('Error destroying chart:', error);
    }
}

// Export functions for global access
window.getChartTheme = getChartTheme;
window.applyChartTheme = applyChartTheme;
window.createVolumeChart = createVolumeChart;
window.createQualityChart = createQualityChart;
window.createPaymentsChart = createPaymentsChart;
window.destroyChart = destroyChart;
