/**
 * Chart Components
 * Reusable chart components with dark/light theme support
 */

import { useMemo } from 'react';
import { formatCompactNumber, formatCurrency } from '@/shared/utils';
import './Charts.css';

export interface LineChartDataPoint {
  label: string;
  value: number;
}

export interface LineChartProps {
  data: LineChartDataPoint[];
  height?: number;
  showGrid?: boolean;
  showLabels?: boolean;
  color?: string;
  fillArea?: boolean;
}

export function LineChart({
  data,
  height = 200,
  showGrid = true,
  showLabels = true,
  color = 'var(--color-primary)',
  fillArea = true,
}: LineChartProps) {
  const { points, min, max, path, areaPath } = useMemo(() => {
    if (data.length === 0) {
      return { points: [], min: 0, max: 0, path: '', areaPath: '' };
    }

    const values = data.map((d) => d.value);
    const min = Math.min(...values);
    const max = Math.max(...values);
    const range = max - min || 1;

    const width = 100;
    const chartHeight = 100;
    const padding = 5;
    const usableHeight = chartHeight - padding * 2;

    const points = data.map((d, i) => {
      const x = (i / (data.length - 1 || 1)) * width;
      const y =
        chartHeight - padding - ((d.value - min) / range) * usableHeight;
      return { x, y, value: d.value, label: d.label };
    });

    // Create SVG path
    const pathData = points
      .map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`)
      .join(' ');

    // Create area path for fill
    const areaPathData =
      pathData +
      ` L ${points[points.length - 1]?.x ?? 0} ${chartHeight - padding}` +
      ` L ${points[0]?.x ?? 0} ${chartHeight - padding} Z`;

    return { points, min, max, path: pathData, areaPath: areaPathData };
  }, [data]);

  if (data.length === 0) {
    return (
      <div className="chart chart--empty" style={{ height }}>
        <p className="chart__empty-message">No data available</p>
      </div>
    );
  }

  return (
    <div className="chart chart--line" style={{ height }}>
      <svg
        viewBox="0 0 100 100"
        preserveAspectRatio="none"
        className="chart__svg"
      >
        {/* Grid lines */}
        {showGrid && (
          <g className="chart__grid">
            {[0, 25, 50, 75, 100].map((y) => (
              <line
                key={y}
                x1="0"
                y1={y}
                x2="100"
                y2={y}
                className="chart__grid-line"
              />
            ))}
          </g>
        )}

        {/* Area fill */}
        {fillArea && (
          <path
            d={areaPath}
            className="chart__area"
            style={{ fill: `${color}20` }}
          />
        )}

        {/* Line */}
        <path
          d={path}
          className="chart__line"
          style={{ stroke: color }}
          fill="none"
          strokeWidth="2"
          vectorEffect="non-scaling-stroke"
        />

        {/* Data points */}
        {points.map((point, i) => (
          <circle
            key={i}
            cx={point.x}
            cy={point.y}
            r="3"
            className="chart__point"
            style={{ fill: color }}
            vectorEffect="non-scaling-stroke"
          />
        ))}
      </svg>

      {/* Labels */}
      {showLabels && (
        <div className="chart__labels">
          {data.map((d, i) => (
            <div key={i} className="chart__label">
              {d.label}
            </div>
          ))}
        </div>
      )}

      {/* Y-axis labels */}
      <div className="chart__y-axis">
        <span className="chart__y-label">{formatCompactNumber(max)}</span>
        <span className="chart__y-label">
          {formatCompactNumber((max + min) / 2)}
        </span>
        <span className="chart__y-label">{formatCompactNumber(min)}</span>
      </div>
    </div>
  );
}

export interface BarChartDataPoint {
  label: string;
  value: number;
  color?: string;
}

export interface BarChartProps {
  data: BarChartDataPoint[];
  height?: number;
  showValues?: boolean;
  showGrid?: boolean;
  defaultColor?: string;
}

export function BarChart({
  data,
  height = 250,
  showValues = true,
  showGrid = true,
  defaultColor = 'var(--color-primary)',
}: BarChartProps) {
  const max = useMemo(() => {
    return data.length > 0 ? Math.max(...data.map((d) => d.value)) : 0;
  }, [data]);

  if (data.length === 0) {
    return (
      <div className="chart chart--empty" style={{ height }}>
        <p className="chart__empty-message">No data available</p>
      </div>
    );
  }

  return (
    <div className="chart chart--bar" style={{ height }}>
      {/* Grid */}
      {showGrid && (
        <div className="chart__grid-horizontal">
          {[0, 25, 50, 75, 100].map((percent) => (
            <div
              key={percent}
              className="chart__grid-line-horizontal"
              style={{ bottom: `${percent}%` }}
            />
          ))}
        </div>
      )}

      {/* Bars */}
      <div className="chart__bars">
        {data.map((item, i) => {
          const heightPercent = max > 0 ? (item.value / max) * 100 : 0;
          const barColor = item.color || defaultColor;

          return (
            <div key={i} className="chart__bar-container">
              <div
                className="chart__bar"
                style={{
                  height: `${heightPercent}%`,
                  backgroundColor: barColor,
                }}
                title={`${item.label}: ${formatCurrency(item.value)}`}
              >
                {showValues && item.value > 0 && (
                  <span className="chart__bar-value">
                    {formatCompactNumber(item.value)}
                  </span>
                )}
              </div>
              <div className="chart__bar-label">{item.label}</div>
            </div>
          );
        })}
      </div>

      {/* Y-axis */}
      <div className="chart__y-axis chart__y-axis--bar">
        <span className="chart__y-label">{formatCompactNumber(max)}</span>
        <span className="chart__y-label">{formatCompactNumber(max / 2)}</span>
        <span className="chart__y-label">0</span>
      </div>
    </div>
  );
}

export interface GroupedBarDataPoint {
  label: string;
  values: { key: string; value: number; color?: string }[];
}

export interface GroupedBarChartProps {
  data: GroupedBarDataPoint[];
  height?: number;
  showLegend?: boolean;
  showValues?: boolean;
  showGrid?: boolean;
}

export function GroupedBarChart({
  data,
  height = 250,
  showLegend = true,
  showValues = false,
  showGrid = true,
}: GroupedBarChartProps) {
  const { max, legend } = useMemo(() => {
    let max = 0;
    const legendSet = new Set<string>();

    data.forEach((group) => {
      group.values.forEach((v) => {
        if (v.value > max) max = v.value;
        legendSet.add(v.key);
      });
    });

    return { max, legend: Array.from(legendSet) };
  }, [data]);

  if (data.length === 0) {
    return (
      <div className="chart chart--empty" style={{ height }}>
        <p className="chart__empty-message">No data available</p>
      </div>
    );
  }

  return (
    <div className="chart chart--grouped-bar" style={{ height }}>
      {/* Legend */}
      {showLegend && legend.length > 0 && (
        <div className="chart__legend">
          {legend.map((key) => {
            const sample = data[0]?.values.find((v) => v.key === key);
            return (
              <div key={key} className="chart__legend-item">
                <span
                  className="chart__legend-color"
                  style={{
                    backgroundColor: sample?.color || 'var(--color-primary)',
                  }}
                />
                <span className="chart__legend-label">{key}</span>
              </div>
            );
          })}
        </div>
      )}

      {/* Grid */}
      {showGrid && (
        <div className="chart__grid-horizontal">
          {[0, 25, 50, 75, 100].map((percent) => (
            <div
              key={percent}
              className="chart__grid-line-horizontal"
              style={{ bottom: `${percent}%` }}
            />
          ))}
        </div>
      )}

      {/* Grouped bars */}
      <div className="chart__groups">
        {data.map((group, i) => (
          <div key={i} className="chart__group">
            <div className="chart__group-bars">
              {group.values.map((v, j) => {
                const heightPercent = max > 0 ? (v.value / max) * 100 : 0;
                return (
                  <div
                    key={j}
                    className="chart__bar"
                    style={{
                      height: `${heightPercent}%`,
                      backgroundColor: v.color || 'var(--color-primary)',
                    }}
                    title={`${group.label} - ${v.key}: ${formatCurrency(v.value)}`}
                  >
                    {showValues && v.value > 0 && (
                      <span className="chart__bar-value">
                        {formatCompactNumber(v.value)}
                      </span>
                    )}
                  </div>
                );
              })}
            </div>
            <div className="chart__group-label">{group.label}</div>
          </div>
        ))}
      </div>

      {/* Y-axis */}
      <div className="chart__y-axis chart__y-axis--bar">
        <span className="chart__y-label">{formatCompactNumber(max)}</span>
        <span className="chart__y-label">{formatCompactNumber(max / 2)}</span>
        <span className="chart__y-label">0</span>
      </div>
    </div>
  );
}
