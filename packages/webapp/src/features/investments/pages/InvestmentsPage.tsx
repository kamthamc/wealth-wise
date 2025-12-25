import { usePortfolioSummary } from '@/core/api/analyticsApi';
import {
    AssetAllocationChart,
    HoldingsPerformanceChart,
} from '@/features/investments/components/InvestmentCharts';
import { formatCurrency } from '@/shared/utils';
import { useQuery } from '@tanstack/react-query';
import { Loader2 } from 'lucide-react';

export const InvestmentsPage = () => {
    const { data: portfolioResponse, isLoading, error } = useQuery({
        queryKey: ['portfolio-summary'],
        queryFn: async () => {
            const result = await usePortfolioSummary()();
            return result;
        },
    });

    if (isLoading) {
        return (
            <div className="flex h-full items-center justify-center p-8">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
        );
    }

    if (error || !portfolioResponse) {
        return (
            <div className="p-8 text-center text-red-500">
                Error loading portfolio data. Please try again later.
            </div>
        );
    }

    const { performance, currency = 'INR' } = portfolioResponse;

    // Use default values if performance data is missing
    const totalValue = performance?.currentValue ?? 0;
    const totalInvested = performance?.totalInvested ?? 0;
    const totalReturns = performance?.totalReturns ?? 0;
    const returnsPercentage = performance?.returnsPercentage ?? 0;
    const holdings = performance?.holdings ?? [];

    // Aggregate asset allocation from holdings
    const assetAllocationMap = new Map<string, number>();
    holdings.forEach(holding => {
        // Assuming holding.accountType can be mapped roughly to asset type
        // or we need a better mapping. For now using accountType.
        const type = holding.accountType;
        const current = assetAllocationMap.get(type) || 0;
        assetAllocationMap.set(type, current + holding.currentValue);
    });

    const assetAllocation = Array.from(assetAllocationMap.entries()).map(([type, value]) => ({
        asset_type: type as any,
        name: type.replace('_', ' ').toUpperCase(),
        value,
        percentage: totalValue > 0 ? (value / totalValue) * 100 : 0
    })).sort((a, b) => b.value - a.value);




    // Transform holdings for chart
    const holdingsData = holdings.map(holding => ({
        symbol: holding.accountName,
        name: holding.accountName,
        return: holding.returns,
        returnPercentage: holding.returnsPercentage
    })).slice(0, 5); // Top 5

    return (
        <div className="container mx-auto space-y-8 p-6">
            <header className="mb-8">
                <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100">
                    Investment Portfolio
                </h1>
                <p className="text-gray-500 dark:text-gray-400">
                    Track your wealth and performance
                </p>
            </header>

            {/* Summary Cards */}
            <div className="grid gap-6 md:grid-cols-3">
                <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Total Value
                    </h3>
                    <p className="mt-2 text-3xl font-bold text-gray-900 dark:text-gray-100">
                        {formatCurrency(totalValue, currency)}
                    </p>
                </div>
                <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Total Invested
                    </h3>
                    <p className="mt-2 text-3xl font-bold text-gray-900 dark:text-gray-100">
                        {formatCurrency(totalInvested, currency)}
                    </p>
                </div>
                <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Total Returns
                    </h3>
                    <div className="mt-2 flex items-baseline gap-2">
                        <p className={`text-3xl font-bold ${totalReturns >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                            {formatCurrency(totalReturns, currency)}
                        </p>
                        <span className={`text-sm font-medium ${totalReturns >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                            ({returnsPercentage.toFixed(2)}%)
                        </span>
                    </div>
                </div>
            </div>

            {/* Charts Grid */}
            <div className="grid gap-6 lg:grid-cols-2">
                {/* Portfolio Performance */}
                {/* Asset Allocation - Spanning full width if performance chart is removed, or adjust grid */}
                <div className="col-span-2 rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                    <h3 className="mb-6 text-lg font-semibold text-gray-900 dark:text-gray-100">
                        Asset Allocation
                    </h3>
                    <AssetAllocationChart
                        data={assetAllocation}
                        height={300}
                        currency={currency}
                    />
                </div>
            </div>

            {/* Holdings Performance */}
            <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                <h3 className="mb-6 text-lg font-semibold text-gray-900 dark:text-gray-100">
                    Top Holdings Performance
                </h3>
                <HoldingsPerformanceChart data={holdingsData} height={300} currency={currency} />
            </div>
        </div>
    );
};
